#!/bin/bash

################################################################################
# Windows libx264 cross-compile build script
################################################################################
#
# This script file can be included in build scripts for Windows or run directly
#
################################################################################

# Halt on errors
set -eE

_fixup_libs() {
    x264name=$(find . -type f -iname "libx264*.dll")
    x264name="$(basename "${x264name}")"
    $WIN_CROSS_TOOL_PREFIX-w64-mingw32-dlltool -z "${BUILD_DIR}"/bin/x264.orig.def --export-all-symbols "${BUILD_DIR}"/bin/$x264name
    grep "EXPORTS\|x264" "${BUILD_DIR}"/bin/x264.orig.def > "${BUILD_DIR}"/bin/x264.def
    rm -f "${BUILD_DIR}"/bin/x264.orig.def
    sed -i -e "/\\t.*DATA/d" -e "/\\t\".*/d" -e "s/\s@.*//" "${BUILD_DIR}"/bin/x264.def
    $WIN_CROSS_TOOL_PREFIX-w64-mingw32-dlltool -m $WIN_CROSS_MVAL -d "${BUILD_DIR}"/bin/x264.def -l "${BUILD_DIR}"/bin/x264.lib -D "${BUILD_DIR}"/bin/$x264name
}

_build_product() {
    cd "${PRODUCT_FOLDER}"

    step "Configure (${ARCH})..."
    git clean -dxf
    LDFLAGS="-static-libgcc" ./configure --enable-shared \
        --disable-avs \
        --disable-ffms \
        --disable-gpac \
        --disable-interlaced \
        --disable-lavf \
        --cross-prefix=$WIN_CROSS_TOOL_PREFIX-w64-mingw32- \
        --host=$WIN_CROSS_TOOL_PREFIX-pc-mingw32 \
        --prefix="${BUILD_DIR}"

    step "Build (${ARCH})..."
    make -j$PARALLELISM
}

_install_product() {
    cd "${PRODUCT_FOLDER}"

    step "Install (${ARCH})..."
    make install

    _fixup_libs
}

build-libx264-main() {
    PRODUCT_NAME="${PRODUCT_NAME:-libx264}"

    if [ -z "${_RUN_OBS_BUILD_SCRIPT}" ]; then
        CHECKOUT_DIR="$(/usr/bin/git rev-parse --show-toplevel)"
        source "${CHECKOUT_DIR}/CI/include/build_support.sh"
        source "${CHECKOUT_DIR}/CI/include/build_support_windows_cross.sh"

        _check_parameters $*
        _build_checks
    fi

    PRODUCT_PROJECT="mirror"
    PRODUCT_REPO="x264"
    PRODUCT_FOLDER="${PRODUCT_REPO}"

    if [ -z "${INSTALL}" ]; then
        _add_ccache_to_path

        _build_setup_git
        _build
    else
        _install_product
    fi
}

build-libx264-main $*
