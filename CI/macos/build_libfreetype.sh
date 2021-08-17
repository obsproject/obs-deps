#!/bin/bash

##############################################################################
# macOS Freetype2 build script
##############################################################################
#
# This script file can be included in build scripts for macOS or run directly
#
##############################################################################

# Halt on errors
set -eE

_fixup_libs() {
    LIBS=$(find "${BUILD_DIR}/lib" -type f -name "libfreetype*.dylib")

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
        PKG_CONFIG_PATH="${BUILD_DIR}/lib/pkgconfig" ../configure \
            --enable-shared \
            --disable-static --without-harfbuzz --without-brotli \
            --prefix="${BUILD_DIR}" --host=x86_64-apple-darwin${DARWIN_TARGET} CFLAGS="-arch x86_64" LDFLAGS="-L${BUILD_DIR}/lib -arch x86_64"

        step "Build (x86_64)..."
        make -j${PARALLELISM}
    fi

    if [ "${ARCH}" = "arm64" -o "${ARCH}" = "universal" ]; then
        mkdir -p "${BASE_DIR}/build_arm64"
        cd "${BASE_DIR}/build_arm64"

        step "Configure (arm64)..."
        PKG_CONFIG_PATH="${BUILD_DIR}/lib/pkgconfig" ../configure \
            --enable-shared --disable-static --without-harfbuzz --without-brotli \
            --prefix="${BUILD_DIR}" --host=arm-apple-darwin20 CFLAGS="-arch arm64" LDFLAGS="-L${BUILD_DIR}/lib -arch arm64"

        step "Build (arm64)..."
        make -j${PARALLELISM}
    fi

    if [ "${ARCH}" = "universal" ]; then
        step "Create universal binaries..."
        rm -rf "${BASE_DIR}/build_universal"
        cp -cpR "${BASE_DIR}/build_x86_64" "${BASE_DIR}/build_universal"
        cd "${BASE_DIR}/build_universal"

        sed -i '.orig' "s/build_x86_64/build_universal/" ./Makefile
        lipo -create ../build_x86_64/.libs/libfreetype.dylib ../build_arm64/.libs/libfreetype.dylib -output ./.libs/libfreetype.dylib
        lipo -create ../build_x86_64/./.libs/libfreetype.6.dylib ../build_arm64/./.libs/libfreetype.6.dylib -output ./.libs/libfreetype.6.dylib
    fi
}

_install_product() {
    cd "${PRODUCT_FOLDER}/build_${ARCH}"

    step "Install (${ARCH})..."
    make install

    _fixup_libs
}

build-libfreetype-main() {
    PRODUCT_NAME="${PRODUCT_NAME:-libfreetype}"

    if [ -z "${_RUN_OBS_BUILD_SCRIPT}" ]; then
        CHECKOUT_DIR="$(/usr/bin/git rev-parse --show-toplevel)"
        source "${CHECKOUT_DIR}/CI/include/build_support.sh"
        source "${CHECKOUT_DIR}/CI/include/build_support_macos.sh"

        _check_parameters $*
        _build_checks
    fi


    NOCONTINUE=TRUE
    PRODUCT_URL="https://downloads.sourceforge.net/project/freetype/freetype2/${PRODUCT_VERSION:-${CI_PRODUCT_VERSION}}/freetype-${PRODUCT_VERSION:-${CI_PRODUCT_VERSION}}.tar.xz"
    PRODUCT_FILENAME="$(basename "${PRODUCT_URL}")"
    PRODUCT_FOLDER="${PRODUCT_FILENAME%.*.*}"

    if [ -z "${INSTALL}" ]; then
        _add_ccache_to_path
       _build_setup
       _build
    else
        _install_product
    fi
}

build-libfreetype-main $*
