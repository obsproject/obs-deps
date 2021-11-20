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
    PRODUCT_NAME="obs-deps"
    source "${CHECKOUT_DIR}/CI/include/build_support.sh"
    source "${CHECKOUT_DIR}/CI/include/build_support_macos.sh"

    check_macos_version

    status "Create universal obs-deps package"

    if [ ! -d "${CHECKOUT_DIR}/macos/obs-dependencies-arm64" ]; then
        caught_error "Missing arm64 build of obs-dependencies"
    elif [ ! -d "${CHECKOUT_DIR}/macos/obs-dependencies-x86_64" ]; then
        caught_error "Missing x86_64 build of obs-depndencies"
    fi

    rm -rf "${CHECKOUT_DIR}/macos/obs-dependencies-universal"
    cp -cpR "${CHECKOUT_DIR}/macos/obs-dependencies-arm64" "${CHECKOUT_DIR}/macos/obs-dependencies-universal"
    cd "${CHECKOUT_DIR}/macos/obs-dependencies-universal"

    step "Cleanup unnecessary files..."
    find . \( -type f -or -type l \) \( -name "*.la" -or -name "*.a" -and ! -name "libajantv2*.a" \) | xargs rm
    find ./lib -mindepth 1 -maxdepth 1 -type d | xargs rm -rf
    rm -rf ./bin
    rm -rf ./share

    step "Create universal binaries..."
    # We find all the binary files that we need to lipo by reading the first
    # four bytes of each non-zero file and match the magic header for
    # arm64 thin (cffaedfe)
    for FILE in $(find . -type f ! -size 0); do
        MAGIC=$(xxd -ps -l 4 "${FILE}")

        if [ "${MAGIC}" = "cffaedfe" ]; then
            info "Create universal binary ${FILE}"
            lipo -create "../obs-dependencies-x86_64/${FILE}" "../obs-dependencies-arm64/${FILE}" -output "${FILE}"
        fi
    done

    step "Create pre-built dependency archive..."
    FILE_NAME="macos-deps-${CURRENT_DATE}-universal.tar.xz"
    cd "${CHECKOUT_DIR}/macos/obs-dependencies-universal"
    cp -R "${CHECKOUT_DIR}/licenses" .

    XZ_OPT=-T0 tar -cJf "${FILE_NAME}" *
    mv ${FILE_NAME} ..
}

package-universal-main $*
