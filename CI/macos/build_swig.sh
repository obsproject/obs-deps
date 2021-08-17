#!/bin/bash

##############################################################################
# macOS SWIG build script
##############################################################################
#
# This script file can be included in build scripts for macOS or run directly
#
##############################################################################

# Halt on errors
set -eE

_build_product() {
    cd "${PRODUCT_FOLDER}"
    BASE_DIR="$(pwd)"

    if [ "${ARCH}" = "x86_64" -o "${ARCH}" = "universal" ]; then
        mkdir -p "${BASE_DIR}/build_x86_64"
        cp -cpR "${CHECKOUT_DIR}/macos_build_temp/pcre-${PCRE_VERSION:-${CI_PCRE_VERSION}}.tar.bz2" ${BASE_DIR}/build_x86_64
        cd "${BASE_DIR}/build_x86_64"

        step "Build PCRE (x86_64)..."
        CFLAGS="-arch x86_64" LDFLAGS="-arch x86_64" CXXFLAGS="-arch x86_64" ../Tools/pcre-build.sh --host=x86_64-apple-darwin${DARWIN_TARGET}

        step "Configure (x86_64)..."
        ../configure --disable-dependency-tracking --prefix="${BUILD_DIR}" --host=x86_64-apple-darwin${DARWIN_TARGET} CFLAGS="-arch x86_64" LDFLAGS="-arch x86_64" CXXFLAGS="-arch x86_64"

        step "Build (x86_64)..."
        make -j${PARALLELISM}
    fi

    if [ "${ARCH}" = "arm64" -o "${ARCH}" = "universal" ]; then
        mkdir -p "${BASE_DIR}/build_arm64"
        cp -cpR "${CHECKOUT_DIR}/macos_build_temp/pcre-${PCRE_VERSION:-${CI_PCRE_VERSION}}.tar.bz2" ${BASE_DIR}/build_arm64
        cd "${BASE_DIR}/build_arm64"

        step "Build PCRE (arm64)..."
        CFLAGS="-arch arm64" LDFLAGS="-arch arm64" CXXFLAGS="-arch arm64" ../Tools/pcre-build.sh --host=aarch64-apple-darwin20

        step "Configure (arm64)..."
        ../configure --disable-dependency-tracking --prefix="${BUILD_DIR}" --host=aarch64-apple-darwin20 CFLAGS="-arch arm64" LDFLAGS="-arch arm64" CXXFLAGS="-arch arm64"

        step "Build (arm64)..."
        make -j${PARALLELISM}
    fi

    if [ "${ARCH}" = "universal" ]; then
        step "Create universal binaries..."
        rm -rf "${BASE_DIR}/build_universal"
        cp -cpR "${BASE_DIR}/build_x86_64" "${BASE_DIR}/build_universal"
        cd "${BASE_DIR}/build_universal"
        lipo -create swig ../build_arm64/swig -output ./swig
        lipo -create CCache/ccache-swig ../build_arm64/CCache/ccache-swig -output CCache/ccache-swig
    fi
}

_install_product() {
    cd "${PRODUCT_FOLDER}/build_${ARCH}"

    step "Install (${ARCH})..."
    make install
}

build-swig-main() {
    PRODUCT_NAME="${PRODUCT_NAME:-swig}"

    if [ -z "${_RUN_OBS_BUILD_SCRIPT}" ]; then
        CHECKOUT_DIR="$(/usr/bin/git rev-parse --show-toplevel)"
        source "${CHECKOUT_DIR}/CI/include/build_support.sh"
        source "${CHECKOUT_DIR}/CI/include/build_support_macos.sh"

        _check_parameters $*
        _build_checks
    fi

    PRODUCT_URL="https://downloads.sourceforge.net/project/swig/swig/swig-${PRODUCT_VERSION:-${CI_PRODUCT_VERSION}}/swig-${PRODUCT_VERSION:-${CI_PRODUCT_VERSION}}.tar.gz"
    PRODUCT_FILENAME="$(basename "${PRODUCT_URL}")"
    PRODUCT_FOLDER="${PRODUCT_NAME}-${PRODUCT_VERSION:-${CI_PRODUCT_VERSION}}"

    if [ -z "${INSTALL}" ]; then
        _add_ccache_to_path

        ensure_dir "${CHECKOUT_DIR}/macos_build_temp"
        CI_PCRE_VERSION=$(/bin/cat "${CI_WORKFLOW}" | /usr/bin/sed -En "s/[ ]+PCRE_VERSION: '([0-9\.]+)'/\1/p")
        CI_PCRE_HASH=$(/bin/cat "${CI_WORKFLOW}" | /usr/bin/sed -En "s/[ ]+PCRE_HASH: '([0-9a-f]+)'/\1/p")
        PCRE_DOWNLOAD_URL="https://ftp.pcre.org/pub/pcre/pcre-${PCRE_VERSION:-${CI_PCRE_VERSION}}.tar.bz2"
        check_and_fetch "${PCRE_DOWNLOAD_URL}" "${PCRE_HASH:-${CI_PCRE_HASH}}"

        NOCONTINUE=TRUE

        _build_setup
        _build
    else
        _install_product
    fi
}

build-swig-main $*
