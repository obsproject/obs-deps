#!/bin/bash

################################################################################
# Windows AMF cross-compile build script
################################################################################
#
# This script file can be included in build scripts for Windows or run directly
#
################################################################################

# Halt on errors
set -eE

_install_product() {
    cd "${PRODUCT_FOLDER}"
    mkdir -p "${BUILD_DIR}"/include/AMF

    step "Install (${ARCH})..."
    cp -a amf/public/include/* "${BUILD_DIR}"/include/AMF
}

build-amf-main() {
    PRODUCT_NAME="${PRODUCT_NAME:-AMF}"

    if [ -z "${_RUN_OBS_BUILD_SCRIPT}" ]; then
        CHECKOUT_DIR="$(/usr/bin/git rev-parse --show-toplevel)"
        source "${CHECKOUT_DIR}/CI/include/build_support.sh"
        source "${CHECKOUT_DIR}/CI/include/build_support_windows_cross.sh"

        _check_parameters $*
        _build_checks
    fi

    PRODUCT_PROJECT="GPUOpen-LibrariesAndSDKs"
    PRODUCT_REPO="AMF"
    PRODUCT_FOLDER="${PRODUCT_REPO}"

    if [ -z "${INSTALL}" ]; then
        set +eE
        check_git
        set -eE
        _build_setup_git "set amf/public/include"
        _build
    else
        _install_product
    fi
}

build-amf-main $*
