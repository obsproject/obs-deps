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

_build_setup_rist() {
    trap "caught_error 'build-librist'" ERR

    ensure_dir "${CHECKOUT_DIR}/macos_build_temp"

    step "Git checkout..."
    mkdir -p "${PRODUCT_REPO}-v${PRODUCT_VERSION:-${CI_PRODUCT_VERSION}}"
    cd "${PRODUCT_REPO}-v${PRODUCT_VERSION:-${CI_PRODUCT_VERSION}}"

    if [ -d "./.git" ]; then
        info "Repository ${PRODUCT_REPO} already exists, updating..."
        git config advice.detachedHead false
        git config remote.origin.url "https://code.videolan.org/rist/librist.git"
        git config remote.origin.fetch "+refs/heads/master:refs/remotes/origin/master"
        git config remote.origin.tapOpt --no-tags

        if ! git rev-parse -q --verify "${PRODUCT_HASH:-${CI_PRODUCT_HASH}}^{commit}"; then
            git fetch origin
        fi

        git checkout -f "${PRODUCT_HASH:-${CI_PRODUCT_HASH}}" --
        git reset --hard "${PRODUCT_HASH:-${CI_PRODUCT_HASH}}" --
    else
        git clone "https://code.videolan.org/rist/librist.git" "$(pwd)"
        git config advice.detachedHead false
        info "Checking out commit ${PRODUCT_HASH:-${CI_PRODUCT_HASH}}..."
        git checkout -f "${PRODUCT_HASH:-${CI_PRODUCT_HASH}}" --

    fi
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
    PRODUCT_REPO="librist"
    PRODUCT_PROJECT="librist"
    PRODUCT_FOLDER="librist-v${PRODUCT_VERSION:-${CI_PRODUCT_VERSION}}"

    if [ -z "${INSTALL}" ]; then
# instead of downloading librist release 0.26, build master; revert back when librist will have a new release for v0.27
#      _build_setup
        _build_setup_rist
        _build
    else
        _install_product
    fi
}

build-librist-main $*
