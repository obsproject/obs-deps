#!/bin/bash

##############################################################################
# macOS libaom build script
##############################################################################
#
# This script file can be included in build scripts for macOS or run directly
#
##############################################################################

# Halt on errors
set -eE

_build_product() {
    cd "${PRODUCT_FOLDER}"

    step "Configure ("${ARCH}")..."
    if [ "${CURRENT_ARCH}" = "arm64" ]; then
        _DISABLE_CPU_DETECT="-DCONFIG_RUNTIME_CPU_DETECT=0"
    fi

    cmake -S . -B build_${ARCH} -G Ninja ${CMAKE_CCACHE_OPTIONS} \
        -DCMAKE_INSTALL_PREFIX="${BUILD_DIR}" \
        -DCMAKE_PREFIX_PATH="${BUILD_DIR}" \
        -DCMAKE_OSX_ARCHITECTURES="${CMAKE_ARCHS}" \
        -DAOM_TARGET_CPU="${ARCH}" \
        -DENABLE_DOCS=OFF \
        -DENABLE_EXAMPLES=OFF \
        -DENABLE_TESTDATA=OFF \
        -DENABLE_TESTS=OFF \
        -DENABLE_TOOLS=OFF \
        -DBUILD_SHARED_LIBS=OFF \
        ${_DISABLE_CPU_DETECT} \
        ${QUIET:+-Wno-deprecated -Wno-dev --log-level=ERROR}

    step "Compile ("${ARCH}")..."
    cmake --build build_${ARCH} --config "Release"
}

_install_product() {
    cd "${PRODUCT_FOLDER}"

    step "Install ("${ARCH}").."
    cmake --install build_${ARCH} --config "Release"
}

_build_setup_aom() {
    trap "caught_error 'build-libaom'" ERR

    ensure_dir "${CHECKOUT_DIR}/macos_build_temp"

    step "Git checkout..."
    mkdir -p "${PRODUCT_REPO}-${PRODUCT_VERSION:-${CI_PRODUCT_VERSION}}"
    cd "${PRODUCT_REPO}-${PRODUCT_VERSION:-${CI_PRODUCT_VERSION}}"

    if [ -d "./.git" ]; then
        info "Repository ${PRODUCT_REPO} already exists, updating..."
        git config advice.detachedHead false
        git config remote.origin.url "https://aomedia.googlesource.com/${PRODUCT_REPO}.git"
        git config remote.origin.fetch "+refs/heads/master:refs/remotes/origin/master"
        git config remote.origin.tapOpt --no-tags

        if ! git rev-parse -q --verify "${PRODUCT_HASH:-${CI_PRODUCT_HASH}}^{commit}"; then
            git fetch origin
        fi

        git checkout -f "${PRODUCT_HASH:-${CI_PRODUCT_HASH}}" --
        git reset --hard "${PRODUCT_HASH:-${CI_PRODUCT_HASH}}" --
        if [ -d "./.gitmodules" ]; then
            git submodule foreach --recursive git submodule sync
            git submodule update --init --recursive
        fi
    else
        git clone "https://aomedia.googlesource.com/${PRODUCT_REPO}.git" "$(pwd)"
        git config advice.detachedHead false
        info "Checking out commit ${PRODUCT_HASH:-${CI_PRODUCT_HASH}}..."
        git checkout -f "${PRODUCT_HASH:-${CI_PRODUCT_HASH}}" --

        if [ -d "./.gitmodules" ]; then
            git submodule foreach --recursive git submodule sync
            git submodule update --init --recursive
        fi
    fi
}

build-libaom-main() {
    PRODUCT_NAME="${PRODUCT_NAME:-libaom}"

    if [ -z "${_RUN_OBS_BUILD_SCRIPT}" ]; then
        CHECKOUT_DIR="$(/usr/bin/git rev-parse --show-toplevel)"
        source "${CHECKOUT_DIR}/CI/include/build_support.sh"
        source "${CHECKOUT_DIR}/CI/include/build_support_macos.sh"

        _check_parameters $*
        _build_checks
    fi

    PRODUCT_REPO="aom"
    PRODUCT_PROJECT="libaom"
    PRODUCT_FOLDER="${PRODUCT_REPO}-${PRODUCT_VERSION:-${CI_PRODUCT_VERSION}}"

    if [ -z "${INSTALL}" ]; then
        _add_ccache_to_path
        _build_setup_aom
        _build
    else
        _install_product
    fi
}

build-libaom-main $*
