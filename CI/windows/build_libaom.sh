#!/bin/bash

################################################################################
# windows libaom build script
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
    apply_patch "${CHECKOUT_DIR}/CI/windows/patches/libaom/libaom-crosscompile-win-dll.patch" "6fa9ca74001c5fa3a6521a2b4944be2a8b4350d31c0234aede9a7052a8f1890b"
}

_build_product() {
    ensure_dir "${PRODUCT_FOLDER}/build_${ARCH}"

    step "Configure (${ARCH})..."
    if [ -f "build.ninja" ]; then
        cmake --build . --target clean
    fi
    cmake -S .. -B . -G Ninja ${CMAKE_CCACHE_OPTIONS} \
        -DCMAKE_SYSTEM_NAME=Windows \
        -DCMAKE_SYSTEM_PROCESSOR=${ARCH} \
        -DAOM_EXTRA_C_FLAGS="-static" \
        -DCMAKE_INSTALL_PREFIX="${BUILD_DIR}" \
        -DCMAKE_TOOLCHAIN_FILE=build/cmake/toolchains/${ARCH}-mingw-gcc.cmake \
        -DCMAKE_SHARED_LINKER_FLAGS="-static-libgcc -static-libstdc++ -Wl,--strip-debug" \
        -DCMAKE_RC_COMPILER=$WIN_CROSS_TOOL_PREFIX-w64-mingw32-windres \
        -DENABLE_DOCS=OFF \
        -DENABLE_EXAMPLES=OFF \
        -DENABLE_TESTDATA=OFF \
        -DENABLE_TESTS=OFF \
        -DENABLE_TOOLS=OFF \
        -DBUILD_SHARED_LIBS=ON \
        -DCMAKE_BUILD_TYPE=Release \
        ${QUIET:+-Wno-deprecated -Wno-dev --log-level=ERROR}

    step "Compile ("${ARCH}")..."
    cmake --build . --config "Release"
    $WIN_CROSS_TOOL_PREFIX-w64-mingw32-strip -w --keep-symbol=aom* libaom.dll
}

_install_product() {
    cd "${PRODUCT_FOLDER}"

    step "Install ("${ARCH}").."
    cmake --install build_${ARCH} --config "Release"
}

_build_setup_aom() {
    trap "caught_error 'build-libaom'" ERR

    ensure_dir "${CHECKOUT_DIR}/windows_cross_build_temp"

    step "Git checkout..."
    mkdir -p "${PRODUCT_REPO}"
    cd "${PRODUCT_REPO}"

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
        source "${CHECKOUT_DIR}/CI/include/build_support_windows_cross.sh"

        _check_parameters $*
        _build_checks
    fi

    PRODUCT_REPO="aom"
    PRODUCT_PROJECT="libaom"
    PRODUCT_FOLDER="${PRODUCT_REPO}"

    if [ -z "${INSTALL}" ]; then
        _add_ccache_to_path
        _build_setup_aom
        _build
    else
        _install_product
    fi
}

build-libaom-main $*
