#!/bin/bash

################################################################################
# Windows libvpx cross-compile build script
################################################################################
#
# This script file can be included in build scripts for Windows or run directly
#
################################################################################

# Halt on errors
set -eE

_fixup_libs() {
    vpxname=`find . -type f -iname libvpx*.dll`
    vpxname="$(basename "${vpxname}")"
    $WIN_CROSS_TOOL_PREFIX-w64-mingw32-dlltool \
        -m $WIN_CROSS_MVAL \
        -d libvpx.def \
        -l "${BUILD_DIR}"/bin/vpx.lib \
        -D "${BUILD_DIR}"/bin/$vpxname
}

_patch_product() {
    cd "${PRODUCT_FOLDER}"

    step "Apply patches..."
    apply_patch "${CHECKOUT_DIR}/CI/windows/patches/libvpx/libvpx-crosscompile-win-dll.patch" "9553b8186feac616d4421188d7c6ca75fbce900265e688cafdf1ed3333ad376a"
}

_build_product() {
    ensure_dir "${PRODUCT_FOLDER}/build_${ARCH}"

    step "Configure (${ARCH})..."
    if [ -f "Makefile" ]; then
        make clean
    fi
    PKG_CONFIG_PATH="${BUILD_DIR}/lib/pkgconfig" \
        CROSS=$WIN_CROSS_TOOL_PREFIX-w64-mingw32- \
        LDFLAGS="-static-libgcc" \
        ../configure \
        --prefix="${BUILD_DIR}" \
        --enable-vp8 \
        --enable-vp9 \
        --disable-docs \
        --disable-examples \
        --enable-shared \
        --disable-static \
        --enable-multithread \
        --enable-runtime-cpu-detect \
        --enable-realtime-only \
        --disable-install-bins \
        --disable-install-docs \
        --disable-unit-tests \
        --target=$WIN_CROSS_GCC_TARGET

    step "Build (${ARCH})..."
    make -j$PARALLELISM
}

_install_product() {
    cd "${PRODUCT_FOLDER}/build_${ARCH}"

    step "Install (${ARCH})..."
    make install

    _fixup_libs
}

build-libvpx-main() {
    PRODUCT_NAME="${PRODUCT_NAME:-libvpx}"

    if [ -z "${_RUN_OBS_BUILD_SCRIPT}" ]; then
        CHECKOUT_DIR="$(/usr/bin/git rev-parse --show-toplevel)"
        source "${CHECKOUT_DIR}/CI/include/build_support.sh"
        source "${CHECKOUT_DIR}/CI/include/build_support_windows_cross.sh"

        _check_parameters $*
        _build_checks
    fi


    PRODUCT_PROJECT="webmproject"
    PRODUCT_REPO="libvpx"
    PRODUCT_FOLDER="${PRODUCT_REPO}"

    if [ -z "${INSTALL}" ]; then
        _add_ccache_to_path

       _build_setup_git
       _build
    else
        _install_product
    fi
}

build-libvpx-main $*
