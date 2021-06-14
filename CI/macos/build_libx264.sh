#!/bin/bash

##############################################################################
# macOS libx264 build script
##############################################################################
#
# This script file can be included in build scripts for macOS or run directly
#
##############################################################################

# Halt on errors
set -eE

_fixup_libs() {
    LIBS=$(find "${BUILD_DIR}/lib" -type f -name "libx264*.dylib")

    for LIB in ${LIBS}; do
        LIB_BASENAME="$(basename ${LIB})"
        LIB_NAME=${LIB_BASENAME%%.*}
        for LINKED_LIB in $(otool -L ${LIB} | grep "obs-dependencies-${ARCH}" | grep -v ${LIB_NAME} | cut -d " " -f 1 | sed -e 's/^[[:space:]]*//'); do
            info "Fix library path ${LINKED_LIB} in ${LIB}"
            install_name_tool -change "${LINKED_LIB}" "@rpath/$(basename "${LINKED_LIB}")" "${LIB}"
        done

        info "Fix id of ${LIB}"
        install_name_tool -id "@rpath/${LIB_BASENAME}" "${LIB}"
    done
}

_build_product() {
    cd "${PRODUCT_FOLDER}"
    BASE_DIR="$(pwd)"

    if [ "${ARCH}" = "x86_64" -o "${ARCH}" = "universal" ]; then
        mkdir -p "${BASE_DIR}/build_x86_64"
        cd "${BASE_DIR}/build_x86_64"

        step "Configure (x86_64)..."
        ../configure --extra-ldflags="-mmacosx-version-min=${MACOSX_DEPLOYMENT_TARGET:-${CI_MACOSX_DEPLOYMENT_TARGET}}" \
            --enable-shared --enable-static --enable-strip --enable-pic \
            --disable-lsmash --disable-swscale --disable-ffms \
            --prefix="${BUILD_DIR}" --host="x86_64-apple-darwin${DARWIN_TARGET}"
        step "Compile (x86_64)..."
        make -j${PARALLELISM}
    fi

    if [ "${ARCH}" = "arm64" -o "${ARCH}" = "universal" ]; then
        mkdir -p "${BASE_DIR}/build_arm64"
        cd "${BASE_DIR}/build_arm64"

        step "Configure (arm64)..."
        ../configure --enable-shared --enable-static --enable-strip --enable-pic --disable-lsmash --disable-swscale --disable-ffms \
            --prefix="${BUILD_DIR}" --host="aarch64-apple-darwin20"
        step "Compile (arm64)..."
        make -j${PARALLELISM}
    fi

    if [ "${ARCH}" = "universal" ]; then
        step "Create universal binaries..."
        cp -cpR "${BASE_DIR}/build_x86_64" "${BASE_DIR}/build_universal"
        cd "${BASE_DIR}/build_universal"
        lipo -create ../build_x86_64/libx264.a ../build_arm64/libx264.a -output ./libx264.a
        lipo -create ../build_x86_64/x264 ../build_arm64/x264 -output ./x264
        DYLIB_NAME=$(basename $(find . -maxdepth 1 -type f -name "*.dylib"))
        lipo -create ../build_x86_64/${DYLIB_NAME} ../build_arm64/${DYLIB_NAME} -output ./${DYLIB_NAME}
        unset DYLIB_NAME
    fi
}

_install_product() {
    cd "${PRODUCT_FOLDER}/build_${ARCH}"

    step "Install (${ARCH})..."
    make install

    _fixup_libs
}

build-libx264-main() {
    PRODUCT_NAME="${PRODUCT_NAME:-libx264}"

    if [ -z "${_RUN_OBS_BUILD_SCRIPT}" ]; then
        CHECKOUT_DIR="$(/usr/bin/git rev-parse --show-toplevel)"
        source "${CHECKOUT_DIR}/CI/include/build_support.sh"
        source "${CHECKOUT_DIR}/CI/include/build_support_macos.sh"

        _check_parameters $*
        _build_checks
    fi

    PRODUCT_REPO="x264"
    PRODUCT_PROJECT="mirror"
    PRODUCT_FOLDER="${PRODUCT_REPO}-${PRODUCT_VERSION:-${CI_PRODUCT_VERSION}}"

    if [ -z "${INSTALL}" ]; then
        _add_ccache_to_path

        _build_setup_git
        _build
    else
        _install_product
    fi
}

build-libx264-main $*
