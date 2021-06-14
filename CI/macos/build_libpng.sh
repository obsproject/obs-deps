#!/bin/bash

##############################################################################
# macOS libpng build script
##############################################################################
#
# This script file can be included in build scripts for macOS or run directly
#
##############################################################################

# Halt on errors
set -eE

_patch_product() {
    cd "${PRODUCT_FOLDER}"

    step "Apply patches..."
    apply_patch "${CHECKOUT_DIR}/CI/macos/patches/libpng.patch" "c6d7c7ca5ca016c839fd2579ac8ab46e2e3940d4027166e9315797b146918f54"
}

_build_product() {
    cd ${PRODUCT_FOLDER}

    step "Configure ("${ARCH}")..."
    cmake -S . -B build_${ARCH} -G Ninja ${CMAKE_CCACHE_OPTIONS} \
        -DCMAKE_INSTALL_PREFIX="${BUILD_DIR}" \
        -DCMAKE_PREFIX_PATH="${BUILD_DIR}" \
        -DCMAKE_OSX_ARCHITECTURES="${CMAKE_ARCHS}" \
        -DPNG_SHARED=OFF \
        -DPNG_TESTS=OFF \
        -DPNG_STATIC=ON \
        -DPNG_ARM_NEON=on \
        -DCMAKE_ASM_FLAGS="-DPNG_ARM_NEON_IMPLEMENTATION=1" \
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

build-libpng-main() {
    PRODUCT_NAME="${PRODUCT_NAME:-libpng}"

    if [ -z "${_RUN_OBS_BUILD_SCRIPT}" ]; then
        CHECKOUT_DIR="$(/usr/bin/git rev-parse --show-toplevel)"
        source "${CHECKOUT_DIR}/CI/include/build_support.sh"
        source "${CHECKOUT_DIR}/CI/include/build_support_macos.sh"
        _check_parameters $*
        _build_checks
    fi

    PRODUCT_URL="https://downloads.sourceforge.net/project/libpng/libpng16/${PRODUCT_VERSION:-${CI_PRODUCT_VERSION}}/libpng-${PRODUCT_VERSION:-${CI_PRODUCT_VERSION}}.tar.xz"
    PRODUCT_FILENAME="$(basename "${PRODUCT_URL}")"
    PRODUCT_FOLDER="${PRODUCT_FILENAME%.*.*}"

    if [ -z "${INSTALL}" ]; then
        _build_setup
        _build
    else
        _install_product
    fi
}

build-libpng-main $*
