#!/bin/bash

##############################################################################
# macOS ntv2 build script
##############################################################################
#
# This script file can be included in build scripts for macOS or run directly
#
##############################################################################

# Halt on errors
set -eE

_build_product() {
    cd ${PRODUCT_FOLDER}

    step "Configure ("${ARCH}")..."
    cmake -S . -B build_${ARCH} -G Ninja ${CMAKE_CCACHE_OPTIONS} \
        -DCMAKE_INSTALL_PREFIX="${BUILD_DIR}" \
        -DCMAKE_PREFIX_PATH="${BUILD_DIR}" \
        -DCMAKE_OSX_ARCHITECTURES="${CMAKE_ARCHS}" \
        -DAJA_BUILD_OPENSOURCE=ON \
        ${QUIET:+-Wno-deprecated -Wno-dev --log-level=ERROR}

    mkdir -p build_${ARCH}/arm64

    step "Compile ("${ARCH}")..."
    cmake --build build_${ARCH} --config "Release"
}

_install_product() {
    cd "${PRODUCT_FOLDER}"

    step "Install ("${ARCH}").."
    cmake --install build_${ARCH} --config "Release"
}

build-ntv2-main() {
    PRODUCT_NAME="${PRODUCT_NAME:-ntv2}"

    if [ -z "${_RUN_OBS_BUILD_SCRIPT}" ]; then
        CHECKOUT_DIR="$(/usr/bin/git rev-parse --show-toplevel)"
        source "${CHECKOUT_DIR}/CI/include/build_support.sh"
        source "${CHECKOUT_DIR}/CI/include/build_support_macos.sh"

        _check_parameters $*
        _build_checks
    fi

    PRODUCT_REPO="ntv2"
    PRODUCT_PROJECT="aja-video"
    PRODUCT_FOLDER="${PRODUCT_REPO}-${PRODUCT_VERSION:-${CI_PRODUCT_VERSION}}"

    if [ -z "${INSTALL}" ]; then
        _add_ccache_to_path
        _build_setup_git
        _build
    else
        _install_product
    fi
}

build-ntv2-main $*
