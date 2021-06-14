#!/bin/bash

##############################################################################
# macOS LuaJIT build script
##############################################################################
#
# This script file can be included in build scripts for macOS or run directly
#
##############################################################################

# Halt on errors
set -eE

_fixup_libs() {
    LIBS=$(find "${BUILD_DIR}/lib" -type f -name "libluajit*.dylib")

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
        rsync -ah ../etc ../src ../dynasm ../doc .

        step "Build (x86_64)..."
        make PREFIX="${BUILD_DIR}" TARGET_CFLAGS="-arch x86_64" TARGET_SHLDFLAGS="-arch x86_64" TARGET_LDFLAGS="-arch x86_64" -j${PARALLELISM} -f ../Makefile
    fi

    if [ "${ARCH}" = "arm64" -o "${ARCH}" = "universal" ]; then
        mkdir -p "${BASE_DIR}/build_arm64"
        cd "${BASE_DIR}/build_arm64"
        rsync -ah ../etc ../src ../dynasm ../doc .

        step "Build (arm64)..."
        make PREFIX="${BUILD_DIR}" TARGET_CFLAGS="-arch arm64" TARGET_SHLDFLAGS="-arch arm64" TARGET_LDFLAGS="-arch arm64" -j${PARALLELISM} -f ../Makefile
    fi

    if [ "${ARCH}" = "universal" ]; then
        step "Create universal binaries..."
        cp -cpR "${BASE_DIR}/build_x86_64" "${BASE_DIR}/build_universal"
        cd "${BASE_DIR}/build_universal"
        lipo -create ../build_x86_64/src/libluajit.so ../build_arm64/src/libluajit.so -output ./src/libluajit.so
        lipo -create ../build_x86_64/src/libluajit.a ../build_arm64/src/libluajit.a -output ./src/libluajit.a
    fi
}

_install_product() {
    cd "${PRODUCT_FOLDER}/build_${ARCH}"

    step "Install (${ARCH})..."
    make install PREFIX="${BUILD_DIR}" -f ../Makefile

    _fixup_libs
}

build-libluajit-main() {
    PRODUCT_NAME="${PRODUCT_NAME:-libluajit}"

    if [ -z "${_RUN_OBS_BUILD_SCRIPT}" ]; then
        CHECKOUT_DIR="$(/usr/bin/git rev-parse --show-toplevel)"
        source "${CHECKOUT_DIR}/CI/include/build_support.sh"
        source "${CHECKOUT_DIR}/CI/include/build_support_macos.sh"

        _check_parameters $*
        _build_checks
    fi

    PRODUCT_REPO="LuaJIT"
    PRODUCT_PROJECT="LuaJIT"
    PRODUCT_FOLDER="${PRODUCT_REPO}-${PRODUCT_VERSION:-${CI_PRODUCT_VERSION}}"

    if [ -z "${INSTALL}" ]; then
        _add_ccache_to_path
        _build_setup_git
        _build
    else
        _install_product
    fi
}

build-libluajit-main $*
