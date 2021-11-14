#!/bin/bash

################################################################################
# Windows pthread-win32 cross-compile build script
################################################################################
#
# This script file can be included in build scripts for Windows or run directly
#
################################################################################

# Halt on errors
set -eE

_build_product() {
    mkdir -p "${PRODUCT_FOLDER}"
    cd "${PRODUCT_FOLDER}"

    step "Build (${ARCH})..."
    make DESTROOT="${BUILD_DIR}" CROSS=$WIN_CROSS_TOOL_PREFIX-w64-mingw32- realclean GC-small-static
}

_install_product() {
    cd "${PRODUCT_FOLDER}"

    step "Install (${ARCH})..."
    cp libpthreadGC2.a "${BUILD_DIR}"/lib
}

build-pthread-win32-main() {
    PRODUCT_NAME="${PRODUCT_NAME:-pthread-win32}"

    if [ -z "${_RUN_OBS_BUILD_SCRIPT}" ]; then
        CHECKOUT_DIR="$(/usr/bin/git rev-parse --show-toplevel)"
        source "${CHECKOUT_DIR}/CI/include/build_support.sh"
        source "${CHECKOUT_DIR}/CI/include/build_support_windows_cross.sh"

        _check_parameters $*
        _build_checks
    fi

    PRODUCT_PROJECT="GerHobbelt"
    PRODUCT_REPO="pthread-win32"
    PRODUCT_FOLDER="${PRODUCT_REPO}"

    if [ -z "${INSTALL}" ]; then
        _add_ccache_to_path

        _build_setup_git
        _build
    else
        _install_product
    fi
}

build-pthread-win32-main $*
