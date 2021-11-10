#!/bin/bash

##############################################################################
# macOS librist build script
##############################################################################
#
# This script file can be included in build scripts for macOS or run directly
#
##############################################################################

# Halt on errors
set -eE

_patch_product() {
    cd "${PRODUCT_FOLDER}"

    step "Apply patches..."
    if [ ! -f "cross_compile.txt" ]; then
        apply_patch "${CHECKOUT_DIR}/CI/macos/patches/librist.patch" "c7b167df4debc5bc0926b56ea1206b2a893ff7541d025218c48d14dfc07bbbe9"
    fi
}

_build_product() {
    cd "${PRODUCT_FOLDER}"
    BASE_DIR="$(pwd)"

    if [ "${ARCH}" = "x86_64" -o "${ARCH}" = "universal" ]; then
        step "Configure (x86_64)..."
        meson setup build_x86_64 \
            --buildtype release \
            --prefix "${BUILD_DIR}" \
            -Duse_mbedtls=true \
            -Dtest=false \
            -Dbuilt_tools=false \
            -Dbuiltin_cjson=true \
            --default-library static \
            -Dc_args="-mmacosx-version-min=${MACOSX_DEPLOYMENT_TARGET}" \
            -Dc_link_args="-mmacosx-version-min=${MACOSX_DEPLOYMENT_TARGET}" \
            -Dpkg_config_path="${BUILD_DIR}/lib/pkgconfig"

        step "Build (x86_64)..."
        meson compile -C build_x86_64
    fi

    if [ "${ARCH}" = "arm64" -o "${ARCH}" = "universal" ]; then
        step "Configure (arm64)..."
        meson setup build_arm64 \
            --buildtype release \
            --prefix "${BUILD_DIR}" \
            -Duse_mbedtls=true \
            -Dtest=false \
            -Dbuilt_tools=false \
            -Dbuiltin_cjson=true \
            --default-library static \
            -Dpkg_config_path="${BUILD_DIR}/lib/pkgconfig" \
            --cross-file ./cross_compile.txt

        step "Build (arm64)..."
        meson compile -C build_arm64
    fi

    if [ "${ARCH}" = "universal" ]; then
        step "Create universal binaries..."
        cp -cpR "${BASE_DIR}/build_x86_64" "${BASE_DIR}/build_universal"
        cd "${BASE_DIR}/build_universal"

        lipo -create ./librist.a ../build_arm64/librist.a -output ./librist.a
    fi
}

_install_product() {
    cd "${PRODUCT_FOLDER}"

    step "Install (${ARCH})..."
    meson install -C build_${ARCH}
}

build-librist-main() {
    PRODUCT_NAME="${PRODUCT_NAME:-librist}"

    if [ -z "${_RUN_OBS_BUILD_SCRIPT}" ]; then
        CHECKOUT_DIR="$(/usr/bin/git rev-parse --show-toplevel)"
        source "${CHECKOUT_DIR}/CI/include/build_support.sh"
        source "${CHECKOUT_DIR}/CI/include/build_support_macos.sh"

        _check_parameters $*
        _build_checks
    fi

    NOCONTINUE=TRUE
    PRODUCT_URL="https://code.videolan.org/rist/librist/-/archive/v${PRODUCT_VERSION:-${CI_PRODUCT_VERSION}}/librist-v${PRODUCT_VERSION:-${CI_PRODUCT_VERSION}}.tar.gz"
    PRODUCT_FILENAME="$(basename "${PRODUCT_URL}")"
    PRODUCT_FOLDER="librist-v${PRODUCT_VERSION:-${CI_PRODUCT_VERSION}}"

    if [ -z "${INSTALL}" ]; then
        _build_setup
        _build
    else
        _install_product
    fi
}

build-librist-main $*
