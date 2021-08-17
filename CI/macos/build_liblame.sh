#!/bin/bash

##############################################################################
# macOS liblame build script
##############################################################################
#
# This script file can be included in build scripts for macOS or run directly
#
##############################################################################

# Halt on errors
set -eE

_build_product() {
    cd "${PRODUCT_FOLDER}"
    BASE_DIR="$(pwd)"

    if [ "${ARCH}" = "x86_64" -o "${ARCH}" = "universal" ]; then
        mkdir -p "${BASE_DIR}/build_x86_64"
        cd "${BASE_DIR}/build_x86_64"

        step "Configure (x86_64)..."
        ../configure \
            --enable-nasm \
            --disable-shared --disable-dependency-tracking --disable-debug \
            --prefix="${BUILD_DIR}" --host="x86_64-apple-darwin${DARWIN_TARGET}" CFLAGS="-arch x86_64"

        step "Build (x86_64)..."
        make -j${PARALLELISM}
    fi

    if [ "${ARCH}" = "arm64" -o "${ARCH}" = "universal" ]; then
        mkdir -p "${BASE_DIR}/build_arm64"
        cd "${BASE_DIR}/build_arm64"

        step "Configure (arm64)..."
        ../configure \
            --enable-nasm \
            --disable-shared --disable-dependency-tracking --disable-debug \
            --prefix="${BUILD_DIR}" --host="arm-apple-darwin" CFLAGS="-arch arm64"

        step "Build (arm64)..."
        make -j${PARALLELISM}
    fi

    if [ "${ARCH}" = "universal" ]; then
        step "Create universal binaries..."
        cp -cpR "${BASE_DIR}/build_x86_64" "${BASE_DIR}/build_universal"
        cd "${BASE_DIR}/build_universal"
        lipo -create ../build_x86_64/mpglib/.libs/libmpgdecoder.a ../build_arm64/mpglib/.libs/libmpgdecoder.a -output ./mpglib/.libs/libmpgdecoder.a
        lipo -create ../build_x86_64/libmp3lame/.libs/libmp3lame.a ../build_arm64/libmp3lame/.libs/libmp3lame.a -output ./libmp3lame/.libs/libmp3lame.a
        lipo -create ../build_x86_64/./frontend/lame ../build_arm64/./frontend/lame -output ./frontend/lame
    fi
}

_install_product() {
    cd "${PRODUCT_FOLDER}/build_${ARCH}"

    step "Install (${ARCH})..."
    make install
}

build-liblame-main() {
    PRODUCT_NAME="${PRODUCT_NAME:-liblame}"

    if [ -z "${_RUN_OBS_BUILD_SCRIPT}" ]; then
        CHECKOUT_DIR="$(/usr/bin/git rev-parse --show-toplevel)"
        source "${CHECKOUT_DIR}/CI/include/build_support.sh"
        source "${CHECKOUT_DIR}/CI/include/build_support_macos.sh"

        _check_parameters $*
        _build_checks
    fi

    PRODUCT_URL="https://downloads.sourceforge.net/project/lame/lame/${PRODUCT_VERSION:-${CI_PRODUCT_VERSION}}/lame-${PRODUCT_VERSION:-${CI_PRODUCT_VERSION}}.tar.gz"
    PRODUCT_FILENAME="$(basename "${PRODUCT_URL}")"
    PRODUCT_FOLDER="${PRODUCT_FILENAME%.*.*}"

    if [ -z "${INSTALL}" ]; then
        _add_ccache_to_path
        _build_setup
        _build
    else
        _install_product
    fi
}

build-liblame-main $*
