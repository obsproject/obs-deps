#!/bin/bash

################################################################################
# Windows libvorbis cross-compile build script
################################################################################
#
# This script file can be included in build scripts for Windows or run directly
#
################################################################################

# Halt on errors
set -eE

_build_product() {
    cd "${PRODUCT_FOLDER}"

    step "Configure (${ARCH})..."
    git clean -dxf
    ./autogen.sh
    PKG_CONFIG_PATH="${BUILD_DIR}/lib/pkgconfig" \
        LDFLAGS="-L${BUILD_DIR}/lib -static-libgcc" \
        CPPFLAGS="-I${BUILD_DIR}/include" \
        ./configure \
        --host=$WIN_CROSS_TOOL_PREFIX-w64-mingw32 \
        --prefix="${BUILD_DIR}" \
        --enable-shared \
        --with-ogg="${BUILD_DIR}"

    step "Compile (${ARCH})..."
    make -j$PARALLELISM
}

_install_product() {
    cd "${PRODUCT_FOLDER}"

    step "Install (${ARCH})..."
    make install
}

build-libvorbis-main() {
    PRODUCT_NAME="${PRODUCT_NAME:-libvorbis}"

    if [ -z "${_RUN_OBS_BUILD_SCRIPT}" ]; then
        CHECKOUT_DIR="$(/usr/bin/git rev-parse --show-toplevel)"
        source "${CHECKOUT_DIR}/CI/include/build_support.sh"
        source "${CHECKOUT_DIR}/CI/include/build_support_windows_cross.sh"

        _check_parameters $*
        _build_checks
    fi

    PRODUCT_PROJECT="xiph"
    PRODUCT_REPO="vorbis"
    PRODUCT_FOLDER="${PRODUCT_REPO}"

    if [ -z "${INSTALL}" ]; then
        _add_ccache_to_path

        _build_setup_git
        _build
    else
        _install_product
    fi
}

build-libvorbis-main $*
