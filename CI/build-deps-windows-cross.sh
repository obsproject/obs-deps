#!/bin/bash

##############################################################################
# Windows cross-compiled dependencies build script
##############################################################################
#
# This script compiles all the FFmpeg dependencies required to build OBS
#
# Parameters:
#   -h, --help                     : Print usage help
#   -q, --quiet                    : Suppress most build process output
#   -v, --verbose                  : Enable more verbose build process output
#   -a, --architecture             : Specify build architecture
#                                    (default: x86_64, alternative: x86)"
#
##############################################################################

# Halt on errors
set -eE

## SET UP ENVIRONMENT ##
_RUN_OBS_BUILD_SCRIPT=TRUE
PRODUCT_NAME="obs-deps"
REQUIRED_DEPS=(
    "mbedtls 2.24.0 523f0554b6cdc7ace5d360885c3f5bbcc73ec0e8"
    "pthread-win32 2.10.0.0 19fd5054b29af1b4e3b3278bfffbb6274c6c89f5"
    "libaom 3.2.0 287164de79516c25c8c84fd544f67752c170082a"
    "svt-av1 0.8.6 a5ec26c0f0bd6e872a0b2bb340b4a777f4847020"
    "libsrt 1.4.2 50b7af06f3a0a456c172b4cb3aceafa8a5cc0036"
    "librist 0.27 419f09ea9aa9bf15f9c43b7752ca878521543679"
    "libx264 r3020 d198931a63049db1f2c92d96c34904c69fde8117"
    "libopus 1.3.1 e85ed7726db5d677c9c0677298ea0cb9c65bdd23"
    "zlib 1.2.11 cacf7f1d4e3d44d871b605da3b647f07d718623f"
    "libpng 1.6.37 505e70834d35383537b6491e7ae8641f1a4bed1876dbfe361201fc80868d88ca"
    "libogg 1.3.4 31bd3f2707fb7dbae539a7093ba1fc4b2b37d84e"
    "libvorbis 1.3.7 83a82dd9296400d811b78c06e9ca429e24dd1e5c"
    "libvpx 1.8.1 8ae686757b708cd8df1d10c71586aff5355cfe1e"
    "nv-codec-headers 11.1.5.0 e81e2ba5e8f365d47d91c8c8688769f62614b644"
    "amf 1.4.16.1 802f92ee52b9efa77bf0d3ea8bfaed6040cdd35e"
    "ffmpeg 4.4.1 cc33e73618a981de7fd96385ecb34719de031f16"
)

## MAIN SCRIPT FUNCTIONS ##
obs-deps-build-main() {
    CHECKOUT_DIR="$(/usr/bin/git rev-parse --show-toplevel)"
    BUILD_DIR="${CHECKOUT_DIR}/../obs-prebuilt-dependencies"
    source "${CHECKOUT_DIR}/CI/include/build_support.sh"
    source "${CHECKOUT_DIR}/CI/include/build_support_windows_cross.sh"
    _check_parameters $*

    _build_checks

    ensure_dir "${CHECKOUT_DIR}"

    FILE_NAME="windows-cross-deps-${CURRENT_DATE}-${ARCH:-${CURRENT_ARCH}}.tar.xz"
    ORIG_PATH="${PATH}"

    # for x86 arch disable aom and svt-av1
    if [ "${ARCH}" = "x86" ]; then
        unset REQUIRED_DEPS[2]
        unset REQUIRED_DEPS[3]
    fi

    for DEPENDENCY in "${REQUIRED_DEPS[@]}"; do
        unset -f _build_product
        unset -f _patch_product
        unset -f _install_product
        unset NOCONTINUE
        PATH="${ORIG_PATH}"

        set -- ${DEPENDENCY}
        trap "caught_error ${DEPENDENCY}" ERR

        PRODUCT_NAME="${1}"
        PRODUCT_VERSION="${2}"
        PRODUCT_HASH="${3}"

        source "${CHECKOUT_DIR}/CI/windows/build_${1}.sh"
    done

    cd "${CHECKOUT_DIR}/windows/obs-dependencies-${ARCH}"

    step "Copy license files..."
    cp -R "${CHECKOUT_DIR}/licenses" .

    step "Create archive ${FILE_NAME}"
    XZ_OPT=-T0 tar -cJf "${FILE_NAME}" *

    mv ${FILE_NAME} ..

    cleanup
}

obs-deps-build-main $*
