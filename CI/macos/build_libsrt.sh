#!/bin/bash

##############################################################################
# macOS libsrt build script
##############################################################################
#
# This script file can be included in build scripts for macOS or run directly
#
##############################################################################

# Halt on errors
set -eE

_build_product() {
    cd "${PRODUCT_FOLDER}"

    step "Configure (${ARCH})..."
    cmake -S . -B build_${ARCH} -G Ninja ${CMAKE_CCACHE_OPTIONS} \
        -DCMAKE_INSTALL_PREFIX="${BUILD_DIR}" \
        -DCMAKE_OSX_ARCHITECTURES="${CMAKE_ARCHS}" \
        -DENABLE_APPS=OFF \
        -DUSE_ENCLIB="mbedtls" \
        -DENABLE_STATIC=ON \
        -DENABLE_SHARED=OFF \
        -DSSL_INCLUDE_DIRS="${BUILD_DIR}/include" \
        -DSSL_LIBRARY_DIRS="${BUILD_DIR}/lib" \
        -DCMAKE_FIND_FRAMEWORK="LAST" \
        ${QUIET:+-Wno-deprecated -Wno-dev --log-level=ERROR}

    step "Build (${ARCH})..."
    cmake --build build_${ARCH} --config "Release"
}

_install_product() {
    cd "${PRODUCT_FOLDER}"

    step "Install (${ARCH})..."
    cmake --install build_${ARCH} --config "Release"
}

build-libsrt-main() {
    PRODUCT_NAME="${PRODUCT_NAME:-libsrt}"

    if [ -z "${_RUN_OBS_BUILD_SCRIPT}" ]; then
        CHECKOUT_DIR="$(/usr/bin/git rev-parse --show-toplevel)"
        source "${CHECKOUT_DIR}/CI/include/build_support.sh"
        source "${CHECKOUT_DIR}/CI/include/build_support_macos.sh"

        _check_parameters $*
        _build_checks
    fi

    NOCONTINUE=TRUE
    PRODUCT_URL="https://github.com/Haivision/srt/archive/v${PRODUCT_VERSION:-${CI_PRODUCT_VERSION}}.tar.gz"
    PRODUCT_FILENAME="$(basename "${PRODUCT_URL}")"
    PRODUCT_FOLDER="srt-${PRODUCT_VERSION:-${CI_PRODUCT_VERSION}}"

    if [ -z "${INSTALL}" ]; then
        _build_setup
        _build
    else
        _install_product
    fi
}

build-libsrt-main $*
