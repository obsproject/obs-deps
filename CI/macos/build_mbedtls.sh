#!/bin/bash

##############################################################################
# macOS mbedtls build script
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
    apply_patch "${CHECKOUT_DIR}/CI/macos/patches/mbedtls.patch" "363e6b8359f1c5fb8cc8e3c47439223c79de09935697e1d38c20336529fb9a5d"
}

_build_product() {
    cd "${PRODUCT_FOLDER}"

    step "Configure (${ARCH})..."
    cmake -S . -B build_${ARCH} -G Ninja ${CMAKE_CCACHE_OPTIONS} \
        -DCMAKE_INSTALL_PREFIX="${BUILD_DIR}" \
        -DCMAKE_OSX_ARCHITECTURES="${CMAKE_ARCHS}" \
        -DUSE_SHARED_MBEDTLS_LIBRARY=ON \
        -DENABLE_PROGRAMS=OFF \
        -DENABLE_TESTING=OFF \
        -DCMAKE_MACOSX_RPATH=ON \
        ${QUIET:+-Wno-deprecated -Wno-dev --log-level=ERROR}

    step "Build (${ARCH})..."
    cmake --build build_${ARCH} --config "Release"
}

_install_product() {
    cd "${PRODUCT_FOLDER}"

    step "Install (${ARCH})..."
    cmake --install build_${ARCH} --config "Release"
    _install_pkgconfig
}

_install_pkgconfig() {
    mkdir -p "${BUILD_DIR}/lib/pkgconfig"

    bash -c "cat <<'EOF' > '${BUILD_DIR}/lib/pkgconfig/mbedcrypto.pc'
prefix='${BUILD_DIR}'
libdir=\${prefix}/lib
includedir=\${prefix}/include
Name: mbedcrypto
Description: lightweight crypto and SSL/TLS library.
Version: ${PRODUCT_VERSION:-${CI_PRODUCT_VERSION}}
Libs: -L\${libdir} -lmbedcrypto
Cflags: -I\${includedir}
EOF"

    bash -c "cat <<'EOF' > '${BUILD_DIR}/lib/pkgconfig/mbedtls.pc'
prefix='${BUILD_DIR}'
libdir=\${prefix}/lib
includedir=\${prefix}/include
Name: mbedtls
Description: lightweight crypto and SSL/TLS library.
Version: ${PRODUCT_VERSION:-${CI_PRODUCT_VERSION}}
Libs: -L\${libdir} -lmbedtls
Cflags: -I\${includedir}
Requires.private: mbedx509
EOF"

    bash -c "cat <<'EOF' > '${BUILD_DIR}/lib/pkgconfig/mbedx509.pc'
prefix='${BUILD_DIR}'
libdir=\${prefix}/lib
includedir=\${prefix}/include
Name: mbedx509
Description: The mbedTLS X.509 library
Version: ${PRODUCT_VERSION:-${CI_PRODUCT_VERSION}}
Libs: -L\${libdir} -lmbedx509
Cflags: -I\${includedir}
Requires.private: mbedcrypto
EOF"
}

build-mbedtls-main() {
    PRODUCT_NAME="${PRODUCT_NAME:-mbedtls}"

    if [ -z "${_RUN_OBS_BUILD_SCRIPT}" ]; then
        CHECKOUT_DIR="$(/usr/bin/git rev-parse --show-toplevel)"
        source "${CHECKOUT_DIR}/CI/include/build_support.sh"
        source "${CHECKOUT_DIR}/CI/include/build_support_macos.sh"

        _check_parameters $*
        _build_checks
    fi

    NOCONTINUE=TRUE
    PRODUCT_URL="https://github.com/ARMmbed/mbedtls/archive/refs/tags/mbedtls-${PRODUCT_VERSION:-${CI_PRODUCT_VERSION}}.tar.gz"
    PRODUCT_FILENAME="$(basename "${PRODUCT_URL}")"
    PRODUCT_FOLDER="mbedtls-mbedtls-${PRODUCT_VERSION:-${CI_PRODUCT_VERSION}}"

    if [ -z "${INSTALL}" ]; then
        _build_setup
        _build
    else
        _install_product
    fi
}

build-mbedtls-main $*
