#!/bin/bash

################################################################################
# Windows libsrt cross-compile build script
################################################################################
#
# This script file can be included in build scripts for Windows or run directly
#
################################################################################

# Halt on errors
set -eE

_patch_product() {
    cd "${PRODUCT_FOLDER}"

    step "Apply patches..."
    apply_patch "${CHECKOUT_DIR}/CI/windows/patches/libsrt/srt-minsizerel.patch" "e586ba574c0f3a8468135be7703f287272e2000670c6e926247e8178af237366"
}

_build_product() {
    ensure_dir "${PRODUCT_FOLDER}/build_${ARCH}"

    step "Configure (${ARCH})..."
    if [ -f "Makefile" ]; then
        make clean
    fi
    cmake .. ${CMAKE_CCACHE_OPTIONS} \
        -DCMAKE_SYSTEM_NAME=Windows \
        -DCMAKE_C_COMPILER=$WIN_CROSS_TOOL_PREFIX-w64-mingw32-gcc \
        -DCMAKE_CXX_COMPILER=$WIN_CROSS_TOOL_PREFIX-w64-mingw32-c++ \
        -DCMAKE_INSTALL_PREFIX="${BUILD_DIR}" \
        -DCMAKE_RC_COMPILER=$WIN_CROSS_TOOL_PREFIX-w64-mingw32-windres \
        -DUSE_ENCLIB="mbedtls" \
        -DENABLE_APPS=OFF \
        -DENABLE_STATIC=OFF \
        -DENABLE_SHARED=ON \
        -DCMAKE_C_FLAGS="-I${CHECKOUT_DIR}/windows_cross_build_temp/pthread-win32" \
        -DCMAKE_CXX_FLAGS="-I${CHECKOUT_DIR}/windows_cross_build_temp/pthread-win32" \
        -DCMAKE_SHARED_LINKER_FLAGS="-static-libgcc -static-libstdc++ -Wl,--strip-debug" \
        -DPTHREAD_LIBRARY="${BUILD_DIR}/lib/libpthreadGC2.a" \
        -DPTHREAD_INCLUDE_DIR="${CHECKOUT_DIR}/windows_cross_build_temp/pthread-win32" \
        -DUSE_OPENSSL_PC=OFF \
        -DCMAKE_BUILD_TYPE=MinSizeRel \
        ${QUIET:+-Wno-deprecated -Wno-dev --log-level=ERROR}

    step "Build (${ARCH})..."
    make -j$PARALLELISM
    $WIN_CROSS_TOOL_PREFIX-w64-mingw32-strip -w --keep-symbol=srt* libsrt.dll
}

_install_product() {
    cd "${PRODUCT_FOLDER}/build_${ARCH}"

    step "Install (${ARCH})..."
    make install
}

build-libsrt-main() {
    PRODUCT_NAME="${PRODUCT_NAME:-libsrt}"

    if [ -z "${_RUN_OBS_BUILD_SCRIPT}" ]; then
        CHECKOUT_DIR="$(/usr/bin/git rev-parse --show-toplevel)"
        source "${CHECKOUT_DIR}/CI/include/build_support.sh"
        source "${CHECKOUT_DIR}/CI/include/build_support_windows_cross.sh"

        _check_parameters $*
        _build_checks
    fi

    NOCONTINUE=TRUE
    PRODUCT_PROJECT="Haivision"
    PRODUCT_REPO="srt"
    PRODUCT_FOLDER="${PRODUCT_REPO}"

    if [ -z "${INSTALL}" ]; then
        _build_setup_git
        _build
    else
        _install_product
    fi
}

build-libsrt-main $*
