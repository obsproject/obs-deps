#!/bin/bash

##############################################################################
# macOS libvpx build script
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
        ../configure --target="x86_64-darwin${DARWIN_TARGET}-gcc" --disable-shared --disable-examples --disable-unit-tests --enable-pic --enable-vp9-highbitdepth --prefix="${BUILD_DIR}"

        step "Compile (x86_64)..."
        make -j${PARALLELISM}
    fi

    if [ "${ARCH}" = "arm64" -o "${ARCH}" = "universal" ]; then
        mkdir -p "${BASE_DIR}/build_arm64"
        cd "${BASE_DIR}/build_arm64"

        step "Configure (arm64)..."
        ../configure --target="arm64-darwin20-gcc" --disable-shared --disable-examples --disable-unit-tests --enable-pic --enable-vp9-highbitdepth --prefix="${BUILD_DIR}"

        step "Compile (arm64)..."
        make -j${PARALLELISM}
    fi

    if [ ${ARCH} = "universal" ]; then
        step "Create universal binaries..."
        cp -cpR "${BASE_DIR}/build_x86_64" "${BASE_DIR}/build_universal"
        cd "${BASE_DIR}/build_universal"
        lipo -create ../build_x86_64/libvpx.a ../build_arm64/libvpx.a -output ./libvpx.a
        lipo -create ../build_x86_64/libvpx_g.a ../build_arm64/libvpx_g.a -output ./libvpx_g.a
        lipo -create ../build_x86_64/libvp9rc.a ../build_arm64/libvp9rc.a -output ./libvp9rc.a
        lipo -create ../build_x86_64/libvp9rc_g.a ../build_arm64/libvp9rc_g.a -output ./libvp9rc_g.a
    fi
}

_install_product() {
    cd "${PRODUCT_FOLDER}/build_${ARCH}"

    step "Install (${ARCH})..."
    make install
}

build-libvpx-main() {
    PRODUCT_NAME="${PRODUCT_NAME:-libvpx}"

    if [ -z "${_RUN_OBS_BUILD_SCRIPT}" ]; then
        CHECKOUT_DIR="$(/usr/bin/git rev-parse --show-toplevel)"
        source "${CHECKOUT_DIR}/CI/include/build_support.sh"
        source "${CHECKOUT_DIR}/CI/include/build_support_macos.sh"

        _check_parameters $*
        _build_checks
    fi


    PRODUCT_URL="https://github.com/webmproject/libvpx/archive/v${PRODUCT_VERSION:-${CI_PRODUCT_VERSION}}.tar.gz"
    PRODUCT_FILENAME="$(basename "${PRODUCT_URL}")"
    PRODUCT_FOLDER="${PRODUCT_NAME}-${PRODUCT_VERSION:-${CI_PRODUCT_VERSION}}"

    if [ -z "${INSTALL}" ]; then
        _add_ccache_to_path
       _build_setup
       _build
    else
        _install_product
    fi
}

build-libvpx-main $*
