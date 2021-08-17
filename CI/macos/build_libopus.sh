#!/bin/bash

##############################################################################
# macOS libopus build script
##############################################################################
#
# This script file can be included in build scripts for macOS or run directly
#
##############################################################################

# Halt on errors
set -eE

_build_product() {
    cd "${PRODUCT_FOLDER}"

    step "Configure ("${ARCH}")..."
    cmake -S . -B build_${ARCH} -G Ninja ${CMAKE_CCACHE_OPTIONS} \
        -DCMAKE_INSTALL_PREFIX="${BUILD_DIR}" \
        -DCMAKE_OSX_ARCHITECTURES="${CMAKE_ARCHS}" \
        -DBUILD_SHARED_LIBS=OFF \
        -DBUILD_TESTING=OFF \
        -DOPUS_BUILD_PROGRAMS=OFF \
        ${QUIET:+-Wno-deprecated -Wno-dev --log-level=ERROR}

    step "Build ("${ARCH}")..."
    cmake --build build_${ARCH} --config "Release"
}

_install_product() {
    cd "${PRODUCT_FOLDER}"

    step "Install ("${ARCH}")..."
    cmake --install build_${ARCH} --config "Release"
}

build-libopus-main() {
    PRODUCT_NAME="${PRODUCT_NAME:-libopus}"

    if [ -z "${_RUN_OBS_BUILD_SCRIPT}" ]; then
        CHECKOUT_DIR="$(/usr/bin/git rev-parse --show-toplevel)"
        source "${CHECKOUT_DIR}/CI/include/build_support.sh"
        source "${CHECKOUT_DIR}/CI/include/build_support_macos.sh"

        _check_parameters $*
        _build_checks
    fi

    PRODUCT_REPO="opus"
    PRODUCT_PROJECT="xiph"
    PRODUCT_FOLDER="${PRODUCT_REPO}-${PRODUCT_VERSION:-${CI_PRODUCT_VERSION}}"

    if [ -z "${INSTALL}" ]; then
        _build_setup_git
        _build
    else
        _install_product
    fi
}

build-libopus-main $*
