#!/bin/bash

################################################################################
# Windows SVT-AV1 cross-compile build script
################################################################################
#
# This script file can be included in build scripts for Windows or run directly
#
################################################################################

# Halt on errors
set -eE

_fixup_libs() {
    mv "${BUILD_DIR}"/lib/libSvtAv1*.dll "${BUILD_DIR}"/bin
}

_build_product() {
    ensure_dir "${PRODUCT_FOLDER}/build_${ARCH}"

    step "Configure (${ARCH})..."
    if [ -f "Makefile" ]; then
        make clean
    fi
    cmake .. ${CMAKE_CCACHE_OPTIONS} \
        -DCMAKE_SYSTEM_NAME=Windows \
        -DCMAKE_SYSTEM_PROCESSOR=${ARCH} \
        -DCMAKE_C_COMPILER=$WIN_CROSS_TOOL_PREFIX-w64-mingw32-gcc \
        -DCMAKE_CXX_COMPILER=$WIN_CROSS_TOOL_PREFIX-w64-mingw32-c++ \
        -DCMAKE_INSTALL_PREFIX="${BUILD_DIR}" \
        -DCMAKE_RC_COMPILER=$WIN_CROSS_TOOL_PREFIX-w64-mingw32-windres \
        -DBUILD_APPS=OFF \
        -DBUILD_DEC=ON \
        -DBUILD_ENC=ON \
        -DBUILD_SHARED_LIBS=ON \
        -DBUILD_TESTING=OFF \
        -DCMAKE_C_FLAGS="-I${CHECKOUT_DIR}/windows_cross_build_temp/pthread-win32" \
        -DCMAKE_CXX_FLAGS="-I${CHECKOUT_DIR}/windows_cross_build_temp/pthread-win32" \
        -DCMAKE_SHARED_LINKER_FLAGS="-static-libgcc -static-libstdc++ -Wl,--strip-debug" \
        -DCMAKE_BUILD_TYPE=Release \
        ${QUIET:+-Wno-deprecated -Wno-dev --log-level=ERROR}
    step "Build (${ARCH})..."
    make -j$PARALLELISM
    $WIN_CROSS_TOOL_PREFIX-w64-mingw32-strip -w --keep-symbol=svt_* ../Bin/Release/libSvtAv1Enc.dll
}

_install_product() {
    cd "${PRODUCT_FOLDER}/build_${ARCH}"

    step "Install (${ARCH})..."
    make install

    _fixup_libs
}

build-svt-av1-main() {
    PRODUCT_NAME="${PRODUCT_NAME:-svt-av1}"

    if [ -z "${_RUN_OBS_BUILD_SCRIPT}" ]; then
        CHECKOUT_DIR="$(/usr/bin/git rev-parse --show-toplevel)"
        source "${CHECKOUT_DIR}/CI/include/build_support.sh"
        source "${CHECKOUT_DIR}/CI/include/build_support_windows_cross.sh"

        _check_parameters $*
        _build_checks
    fi

    NOCONTINUE=TRUE
    PRODUCT_PROJECT="AOMediaCodec"
    PRODUCT_REPO="SVT-AV1"
    PRODUCT_FOLDER="${PRODUCT_REPO}"

    if [ -z "${INSTALL}" ]; then
        _build_setup_git
        _build
    else
        _install_product
    fi
}

build-svt-av1-main $*
