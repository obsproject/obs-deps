#!/bin/bash

##############################################################################
# macOS rnnoise build script
##############################################################################
#
# This script file can be included in build scripts for macOS or run directly
#
##############################################################################

# Halt on errors
set -eE

_fixup_libs() {
    LIBS=$(find "${BUILD_DIR}/lib" -type f -name "librnnoise*.dylib")

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

    ./autogen.sh

    if [ "${ARCH}" = "x86_64" -o "${ARCH}" = "universal" ]; then
        mkdir -p "${BASE_DIR}/build_x86_64"
        cd "${BASE_DIR}/build_x86_64"

        step "Configure (x86_64)..."
        ../configure --prefix="${BUILD_DIR}" --host=x86_64-apple-darwin${DARWIN_TARGET} CFLAGS="-arch x86_64" LDFLAGS="-arch x86_64"

        step "Build (x86_64)..."
        make -j${PARALLELISM}
    fi

    if [ "${ARCH}" = "arm64" -o "${ARCH}" = "universal" ]; then
        mkdir -p "${BASE_DIR}/build_arm64"
        cd "${BASE_DIR}/build_arm64"

        step "Configure (arm64)..."
        ../configure --prefix="${BUILD_DIR}" --host=arm-apple-darwin20 CFLAGS="-arch arm64" LDFLAGS="-arch arm64"

        step "Build (arm64)..."
        make -j${PARALLELISM}
    fi

    if [ "${ARCH}" = "universal" ]; then
        step "Create universal binaries..."
        rm -rf "${BASE_DIR}/build_universal"
        cp -cpR "${BASE_DIR}/build_x86_64" "${BASE_DIR}/build_universal"
        cd "${BASE_DIR}/build_universal"

        lipo -create ../build_x86_64/.libs/librnnoise.0.dylib ../build_arm64/.libs/librnnoise.0.dylib -output ./.libs/librnnoise.0.dylib
        lipo -create ../build_x86_64/.libs/librnnoise.dylib ../build_arm64/.libs/librnnoise.dylib -output ./.libs/librnnoise.dylib
    fi
}

_install_product() {
    cd "${PRODUCT_FOLDER}/build_${ARCH}"

    step "Install (${ARCH})..."
    make install

    _fixup_libs
}

build-librnnoise-main() {
    PRODUCT_NAME="${PRODUCT_NAME:-librnnoise}"

    if [ -z "${_RUN_OBS_BUILD_SCRIPT}" ]; then
        CHECKOUT_DIR="$(/usr/bin/git rev-parse --show-toplevel)"
        source "${CHECKOUT_DIR}/CI/include/build_support.sh"
        source "${CHECKOUT_DIR}/CI/include/build_support_macos.sh"

        _check_parameters $*
        _build_checks
    fi

    PRODUCT_REPO="rnnoise"
    PRODUCT_PROJECT="xiph"
    PRODUCT_FOLDER="${PRODUCT_REPO}-${PRODUCT_VERSION:-${CI_PRODUCT_VERSION}}"

    if [ -z "${INSTALL}" ]; then
        _add_ccache_to_path
        _build_setup_git
        _build
    else
        _install_product
    fi
}

build-librnnoise-main $*
