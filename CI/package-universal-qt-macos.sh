#!/bin/bash

##############################################################################
# macOS universal package script
##############################################################################
#
# This script combines compiled x86_64 and arm64 binaries into universal
# variants.
#
# Parameters:
#   -h, --help                     : Print usage help
#   -q, --quiet                    : Suppress most build process output
#
##############################################################################

# Halt on errors
set -eE

print_usage() {
    echo -e "Usage: ${0}\n" \
            "-h, --help                     : Print this help\n" \
            "-q, --quiet                    : Suppress most build process output\n"
}

package-universal-main() {
    while true; do
        case "${1}" in
            -h | --help ) print_usage; exit 0 ;;
            -q | --quiet ) export QUIET=TRUE; shift ;;
            -- ) shift; break ;;
            * ) break ;;
        esac
    done

    CHECKOUT_DIR="$(/usr/bin/git rev-parse --show-toplevel)"
    PRODUCT_NAME="obs-qt"
    source "${CHECKOUT_DIR}/CI/include/build_support.sh"
    source "${CHECKOUT_DIR}/CI/include/build_support_macos.sh"

    check_macos_version

    status "Create universal obs-deps package"

    if [ "${CURRENT_ARCH}" = "x86_64" ]; then
        OTHER_ARCH="arm64"
    else
        OTHER_ARCH="x86_64"
    fi

    if [ ! -d "${CHECKOUT_DIR}/macos/obs-dependencies-qt-${OTHER_ARCH}" ]; then
        caught_error "Missing ${OTHER_ARCH} build of Qt"
    elif [ ! -d "${CHECKOUT_DIR}/macos/obs-dependencies-qt-${CURRENT_ARCH}" ]; then
        caught_error "Missing ${CURRENT_ARCH} build of Qt"
    fi

    rm -rf "${CHECKOUT_DIR}/macos/obs-dependencies-qt-universal"
    rsync -ah "${CHECKOUT_DIR}"/macos/obs-dependencies-qt-${OTHER_ARCH}/* "${CHECKOUT_DIR}/macos/obs-dependencies-qt-universal"
    cd "${CHECKOUT_DIR}/macos/obs-dependencies-qt-universal"

    step "Create universal binaries..."
    # We find all the binary files that we need to lipo by reading the first four bytes of each non-zero file and match the magic header for arm64 thin (cffaedfe)
    for FILE in $(find . -type f ! \( -size 0 -o -name "qmake" \)); do
        MAGIC=$(xxd -ps -l 4 "${FILE}")

        if [ "${MAGIC}" = "cffaedfe" ]; then
            info "Create universal binary ${FILE}"
            lipo -create "../obs-dependencies-qt-${OTHER_ARCH}/${FILE}" "../obs-dependencies-qt-${CURRENT_ARCH}/${FILE}" -output "${FILE}"
        fi
    done

    step "Create pre-built dependency archive..."
    FILE_NAME="macos-deps-qt-${CURRENT_DATE}-universal.tar.xz"
    cd "${CHECKOUT_DIR}/macos/obs-dependencies-qt-universal"
    cp -R "${CHECKOUT_DIR}/licenses" .

    XZ_OPT=-T0 tar -cJf "${FILE_NAME}" *
    mv ${FILE_NAME} ..
}

package-universal-main $*
