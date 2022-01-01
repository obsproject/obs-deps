#!/bin/bash

################################################################################
# Windows librist cross-compile build script
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
    if [ ! -f "cross_mingw_x86.txt" ] || [ ! -f "cross_mingw_x86_64.txt" ]; then
        apply_patch "${CHECKOUT_DIR}/CI/windows/patches/librist/librist.patch" "9182C700947D52AE9A650213DB43E703B8E0E34080388EFC9EF9F700F05D5B9A"
    fi
}

_build_product() {
    cd "${PRODUCT_FOLDER}"
    BASE_DIR="$(pwd)"

    step "Configure (${ARCH})..."
    meson setup build_${ARCH} \
        --cross-file cross_mingw_${ARCH}.txt \
        --buildtype release \
        --prefix "${BUILD_DIR}" \
        -Duse_mbedtls=true \
        -Dbuiltin_cjson=true \
        -Dtest=false \
        -Dbuilt_tools=false \
        -Dc_link_args="-static-libgcc" \
        -Dhave_mingw_pthreads=false \
        -Dpkg_config_path="${BUILD_DIR}/lib/pkgconfig"
    step "Build (${ARCH})..."
    ninja -C build_${ARCH}
}

_install_product() {
    cd "${PRODUCT_FOLDER}"

    step "Install (${ARCH})..."
    meson install -C build_${ARCH}
}

_build_setup_rist() {
    trap "caught_error 'build-librist'" ERR

    ensure_dir "${CHECKOUT_DIR}/windows_cross_build_temp"

    step "Git checkout..."
    mkdir -p "${PRODUCT_REPO}"
    cd "${PRODUCT_REPO}"

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
        source "${CHECKOUT_DIR}/CI/include/build_support_windows_cross.sh"

        _check_parameters $*
        _build_checks
    fi

    NOCONTINUE=TRUE
    PRODUCT_REPO="librist"
    PRODUCT_PROJECT="librist"
    PRODUCT_FOLDER="librist"

    if [ -z "${INSTALL}" ]; then
        _build_setup_rist
        _build
    else
        _install_product
    fi
}

build-librist-main $*
