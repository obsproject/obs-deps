#!/bin/bash

##############################################################################
# macOS SpeexDSP build script
##############################################################################
#
# This script file can be included in build scripts for macOS or run directly
#
##############################################################################

# Halt on errors
set -eE

_fixup_libs() {
    LIBS=$(find "${BUILD_DIR}/lib" -type f -name "libspeexdsp*.dylib")

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

_patch_product() {
    cd "${PRODUCT_FOLDER}"

    step "Apply patches..."
    apply_patch "${CHECKOUT_DIR}/CI/macos/patches/speexdsp.patch" "1ea31b3f0b047abde09eac223e5dd277a0a871c6e6a4b8c8a56ea7e3a64adb5b"
}

_build_product() {
    cd "${PRODUCT_FOLDER}"
    BASE_DIR="$(pwd)"

    ./autogen.sh
    
    if [ "${ARCH}" = "x86_64" -o "${ARCH}" = "universal" ]; then
        mkdir -p "${BASE_DIR}/build_x86_64"
        cd "${BASE_DIR}/build_x86_64"


        step "Configure (x86_64)..."
        ../configure --prefix="${BUILD_DIR}" --disable-dependency-tracking --host=x86_64-apple-darwin${DARWIN_TARGET} CFLAGS="-arch x86_64"
        step "Build (x86_64)..."
        make -j${PARALLELISM}
    fi

    if [ "${ARCH}" = "arm64" -o "${ARCH}" = "universal" ]; then
        mkdir -p "${BASE_DIR}/build_arm64"
        cd "${BASE_DIR}/build_arm64"

        step "Configure (arm64)..."
        ../configure --prefix="${BUILD_DIR}" --disable-dependency-tracking --host=arm64-apple-darwin20 CFLAGS="-arch arm64"
        step "Build (arm64)..."
        make -j${PARALLELISM}
    fi

    if [ "${ARCH}" = "universal" ]; then
        step "Create universal binaries..."
        rm -rf "${BASE_DIR}/build_universal"
        cp -cpR "${BASE_DIR}/build_x86_64" "${BASE_DIR}/build_universal"
        cd "${BASE_DIR}/build_universal"
        lipo -create ../build_x86_64/libspeexdsp/.libs/libspeexdsp.a ../build_arm64/libspeexdsp/.libs/libspeexdsp.a -output ./libspeexdsp/.libs/libspeexdsp.a
        lipo -create ../build_x86_64/libspeexdsp/.libs/libspeexdsp.dylib ../build_arm64/libspeexdsp/.libs/libspeexdsp.dylib -output ./libspeexdsp/.libs/libspeexdsp.dylib
        lipo -create ../build_x86_64/libspeexdsp/.libs/libspeexdsp.1.dylib ../build_arm64/libspeexdsp/.libs/libspeexdsp.1.dylib -output ./libspeexdsp/.libs/libspeexdsp.1.dylib
    fi
}

_install_product() {
    cd "${PRODUCT_FOLDER}/build_${ARCH}"

    step "Install (${ARCH})..."
    make install

    _fixup_libs
}

build-speexdsp-main() {
    PRODUCT_NAME="${PRODUCT_NAME:-speexdsp}"

    if [ -z "${_RUN_OBS_BUILD_SCRIPT}" ]; then
        CHECKOUT_DIR="$(/usr/bin/git rev-parse --show-toplevel)"
        source "${CHECKOUT_DIR}/CI/include/build_support.sh"
        source "${CHECKOUT_DIR}/CI/include/build_support_macos.sh"

        _check_parameters $*
        _build_checks
    fi

    NOCONTINUE=TRUE
    PRODUCT_URL="https://github.com/xiph/speexdsp/archive/SpeexDSP-${PRODUCT_VERSION:-${CI_PRODUCT_VERSION}}.tar.gz"
    PRODUCT_FILENAME="$(basename "${PRODUCT_URL}")"
    PRODUCT_FOLDER="speexdsp-speexDSP-${PRODUCT_VERSION:-${CI_PRODUCT_VERSION}}"

    if [ -z "${INSTALL}" ]; then
        _add_ccache_to_path
        _build_setup
        _build
    else
        _install_product
    fi
}

build-speexdsp-main $*
