#!/bin/bash

################################################################################
# Windows FFmpeg nv-codec-headers cross-compile build script
################################################################################
#
# This script file can be included in build scripts for Windows or run directly
#
################################################################################

# Halt on errors
set -eE

_build_product() {
    cd "${PRODUCT_FOLDER}"

    step "Build (${ARCH})..."
    make PREFIX="${BUILD_DIR}"
}

_install_product() {
    cd "${PRODUCT_FOLDER}"

    step "Install (${ARCH})..."
    make PREFIX="${BUILD_DIR}" install
}

build-nv-codec-headers-main() {
    PRODUCT_NAME="${PRODUCT_NAME:-nv-codec-headers}"

    if [ -z "${_RUN_OBS_BUILD_SCRIPT}" ]; then
        CHECKOUT_DIR="$(/usr/bin/git rev-parse --show-toplevel)"
        source "${CHECKOUT_DIR}/CI/include/build_support.sh"
        source "${CHECKOUT_DIR}/CI/include/build_support_windows_cross.sh"

        _check_parameters $*
        _build_checks
    fi

    PRODUCT_PROJECT="FFmpeg"
    PRODUCT_REPO="nv-codec-headers"
    PRODUCT_FOLDER="${PRODUCT_REPO}"

    if [ -z "${INSTALL}" ]; then
        _add_ccache_to_path

        _build_setup_git
        _build
    else
        _install_product
    fi
}

build-nv-codec-headers-main $*
