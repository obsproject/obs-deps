#!/bin/bash

################################################################################
# Windows libpng cross-compile build script
################################################################################
#
# This script file can be included in build scripts for Windows or run directly
#
################################################################################

# Halt on errors
set -eE

_fixup_installed_files() {
    rm -f "${BUILD_DIR}"/bin/libpng-config
    rm -f "${BUILD_DIR}"/include/png.h
    rm -f "${BUILD_DIR}"/include/pngconf.h
    rm -f "${BUILD_DIR}"/include/pnglibconf.h
    rm -f "${BUILD_DIR}"/lib/libpng.a
    rm -f "${BUILD_DIR}"/lib/libpng.dll.a
    rm -f "${BUILD_DIR}"/lib/libpng.la
    rm -f "${BUILD_DIR}"/lib/pkgconfig/libpng.pc
}

_build_product() {
    cd ${PRODUCT_FOLDER}

    step "Configure ("${ARCH}")..."
    if [ -f "Makefile" ]; then
        make clean
    fi
    PKG_CONFIG_PATH="${BUILD_DIR}/lib/pkgconfig" \
        LDFLAGS="-L${BUILD_DIR}/lib -static-libgcc" \
        CPPFLAGS="-I${BUILD_DIR}/include" \
        ./configure \
        --host=$WIN_CROSS_TOOL_PREFIX-w64-mingw32 \
        --prefix="${BUILD_DIR}" \
        --enable-shared

    step "Compile ("${ARCH}")..."
    make -j$PARALLELISM
}

_install_product() {
    cd "${PRODUCT_FOLDER}"

    step "Install ("${ARCH}").."
    make install

    _fixup_installed_files
}

build-libpng-main() {
    PRODUCT_NAME="${PRODUCT_NAME:-libpng}"

    if [ -z "${_RUN_OBS_BUILD_SCRIPT}" ]; then
        CHECKOUT_DIR="$(/usr/bin/git rev-parse --show-toplevel)"
        source "${CHECKOUT_DIR}/CI/include/build_support.sh"
        source "${CHECKOUT_DIR}/CI/include/build_support_windows_cross.sh"
        _check_parameters $*
        _build_checks
    fi

    PRODUCT_URL="https://downloads.sourceforge.net/project/libpng/libpng16/${PRODUCT_VERSION:-${CI_PRODUCT_VERSION}}/libpng-${PRODUCT_VERSION:-${CI_PRODUCT_VERSION}}.tar.xz"
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

build-libpng-main $*
