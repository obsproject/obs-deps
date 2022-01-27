#!/bin/bash

##############################################################################
# macOS dependencies build script
##############################################################################
#
# This script compiles all dependencies required to build OBS
#
# Parameters:
#   -h, --help                     : Print usage help
#   -q, --quiet                    : Suppress most build process output
#   -v, --verbose                  : Enable more verbose build process output
#   -a, --architecture             : Specify build architecture
#                                    (default: universal, alternative: x86_64
#                                     or arm64)"
#
##############################################################################

# Halt on errors
set -eE

## SET UP ENVIRONMENT ##
_RUN_OBS_BUILD_SCRIPT=TRUE
PRODUCT_NAME="obs-deps"
REQUIRED_DEPS=(
    "ntv2 16.1 abf17cc1e7aadd9f3e4972774a3aba2812c51b75"
    "libpng 1.6.37 505e70834d35383537b6491e7ae8641f1a4bed1876dbfe361201fc80868d88ca"
    "libopus 1.3.1-93-gdfd6c88a dfd6c88aaa54a03a61434c413e30c217eb98f1d5"
    "libogg 1.3.5 c4d91be36fc8e54deae7575241e03f4211eb102afb3fc0775fbbc1b740016705"
    "libvorbis 1.3.7 b33cc4934322bcbf6efcbacf49e3ca01aadbea4114ec9589d1b1e9d20f72954b"
    "libvpx 1.10.0 85803ccbdbdd7a3b03d930187cb055f1353596969c1f92ebec2db839fa4f834a"
    "libaom 3.2.0 402e264b94fd74bdf66837da216b6251805b4ae4"
    "libx264 r3059 b684ebe04a6f80f8207a57940a1fa00e25274f81"
    "libtheora 1.1.1 f36da409947aa2b3dcc6af0a8c2e3144bc19db2ed547d64e9171c59c66561c61"
    "liblame 3.100 ddfe36cab873794038ae2c1210557ad34857a4b6bdc515785d1da9e175b1da1e"
    "mbedtls 2.26.0 35d8d87509cd0d002bddbd5508b9d2b931c5e83747d087234cc7ad551d53fe05"
    "libsrt 1.4.1 e80ca1cd0711b9c70882c12ec365cda1ba852e1ce8acd43161a21a04de0cbf14"
    "librist 0.2.7 419f09ea9aa9bf15f9c43b7752ca878521543679"
    "ffmpeg 4.4.1 cc33e73618a981de7fd96385ecb34719de031f16"
    "speexdsp 1.2.0 d7032f607e8913c019b190c2bccc36ea73fc36718ee38b5cdfc4e4c0a04ce9a4"
    "libjansson 2.13.1 f4f377da17b10201a60c1108613e78ee15df6b12016b116b6de42209f47a474f"
    "libluajit 2.1 ec6edc5c39c25e4eb3fca51b753f9995e97215da"
    "libfreetype 2.10.4 86a854d8905b19698bbc8f23b860bc104246ce4854dcea8e3b0fb21284f75784"
    "librnnoise 2020-07-28 90ec41ef659fd82cfec2103e9bb7fc235e9ea66c"
)

## MAIN SCRIPT FUNCTIONS ##
obs-deps-build-main() {
    CHECKOUT_DIR="$(/usr/bin/git rev-parse --show-toplevel)"
    BUILD_DIR="${CHECKOUT_DIR}/../obs-prebuilt-dependencies"
    source "${CHECKOUT_DIR}/CI/include/build_support.sh"
    source "${CHECKOUT_DIR}/CI/include/build_support_macos.sh"
    _check_parameters $*

    _build_checks

    ensure_dir "${CHECKOUT_DIR}"

    FILE_NAME="macos-deps-${CURRENT_DATE}-${ARCH:-${CURRENT_ARCH}}.tar.xz"
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

    cd "${CHECKOUT_DIR}/macos/obs-dependencies-${ARCH}"

    step "Cleanup unnecessary files..."
    find . \( -type f -or -type l \) \( -name "*.la" -or -name "*.a" -and ! -name "libajantv2*.a" \) | xargs rm
    rm -rf ./bin
    rm -rf ./share
    find ./lib -mindepth 1 -maxdepth 1 -type d | xargs rm -rf
    cp -R "${CHECKOUT_DIR}/licenses" .

    step "Create archive ${FILE_NAME}"
    XZ_OPT=-T0 tar -cJf "${FILE_NAME}" *

    mv ${FILE_NAME} ..

    cleanup
}

obs-deps-build-main $*
