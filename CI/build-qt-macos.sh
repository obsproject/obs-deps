#!/bin/bash

##############################################################################
# macOS dependencies build script
##############################################################################
#
# This script pre-compiles all dependencies required to build OBS
#
# Parameters:
#   -h, --help                     : Print usage help
#   -q, --quiet                    : Suppress most build process output
#   -v, --verbose                  : Enable more verbose build process output
#   -a, --architecture             : Specify build architecture
#                                    (default: universal, alternative: x86_64
#                                     or arm64)\n"
#
##############################################################################

# Halt on errors
set -eE

## SET UP ENVIRONMENT ##
_RUN_OBS_BUILD_SCRIPT=TRUE
PRODUCT_NAME="obs-qt"
REQUIRED_DEPS=(
    "qt 5.15.2 3a530d1b243b5dec00bc54937455471aaa3e56849d2593edb8ded07228202240"
)

## MAIN SCRIPT FUNCTIONS ##
print_usage() {
    echo -e "Usage: ${0}\n" \
            "-h, --help                     : Print this help\n" \
            "-q, --quiet                    : Suppress most build process output\n" \
            "-v, --verbose                  : Enable more verbose build process output\n" \
            "-a, --architecture             : Specify build architecture (default: universal, alternative: x86_64 or arm64)\n" \
            "-s, --skip-dependency-checks   : Skip Homebrew dependency checks (default: off)\n" \
            "--skip-unpack                  : Skip unpacking of Qt archive (default: off)\n"
}

obs-qt-build-main() {
    QMAKE_QUIET=TRUE
    CHECKOUT_DIR="$(/usr/bin/git rev-parse --show-toplevel)"
    source "${CHECKOUT_DIR}/CI/include/build_support.sh"
    source "${CHECKOUT_DIR}/CI/include/build_support_macos.sh"

    while true; do
        case "${1}" in
            -h | --help ) print_usage; exit 0 ;;
            -q | --quiet ) export QUIET=TRUE; shift ;;
            -v | --verbose ) export VERBOSE=TRUE; unset QMAKE_QUIET; shift ;;
            -a | --architecture ) ARCH="${2}"; shift 2 ;;
            -s | --skip-dependency-checks ) SKIP_DEP_CHECKS=TRUE; shift ;;
            --skip-unpack ) SKIP_UNPACK=TRUE; shift ;;
            -- ) shift; break ;;
            * ) break ;;
        esac
    done

    _build_checks

    ensure_dir "${CHECKOUT_DIR}"

    FILE_NAME="macos-deps-qt-${CURRENT_DATE}-${ARCH:-${CURRENT_ARCH}}.tar.xz"
    ORIG_PATH="${PATH}"

    for DEPENDENCY in "${REQUIRED_DEPS[@]}"; do
        unset -f _build_product
        unset -f _patch_product
        unset -f _install_product
        unset NOCONTINUE
        PATH="${ORIG_PATH}"

        set -- ${DEPENDENCY}
        trap "caught_error ${DEPENDENCY}" ERR

        if [ "${1}" = "swig" ]; then
            PCRE_VERSION="8.44"
            PCRE_HASH="19108658b23b3ec5058edc9f66ac545ea19f9537234be1ec62b714c84399366d"
        fi

        PRODUCT_NAME="${1}"
        PRODUCT_VERSION="${2}"
        PRODUCT_HASH="${3}"

        source "${CHECKOUT_DIR}/CI/macos/build_${1}.sh"
    done


    if [ "${ARCH}" = "universal" ]; then
        source "${CHECKOUT_DIR}/CI/package-universal-qt-macos.sh"
    else
        cd "${CHECKOUT_DIR}/macos/obs-dependencies-qt-${ARCH}"
        cp -R "${CHECKOUT_DIR}/licenses" .

        step "Create archive ${FILE_NAME}"
        XZ_OPT=-T0 tar -cJf "${FILE_NAME}" *

        mv ${FILE_NAME} ..
    fi

    cleanup
}

obs-qt-build-main $*
