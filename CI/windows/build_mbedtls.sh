#!/bin/bash

################################################################################
# Windows mbedtls cross-compile build script
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
    apply_patch "${CHECKOUT_DIR}/CI/windows/patches/mbedtls/mbedtls-enable-alt-threading-01.patch" "306b8aaee8f291cc0dbd4cbee12ea185e722469eb06b8b7113f0a60feca6bbe6"

    if [ ! -f "include/mbedtls/threading_alt.h" ]; then
        apply_patch "${CHECKOUT_DIR}/CI/windows/patches/mbedtls/mbedtls-enable-alt-threading-02.patch" "d0dde0836dc6b100edf218207feffbbf808d04b1d0065082cdc5c838f8a4a7c7"
    fi
}

_build_product() {
    ensure_dir "${PRODUCT_FOLDER}/build_${ARCH}"

    step "Configure (${ARCH})..."
    cmake .. ${CMAKE_CCACHE_OPTIONS} \
        -DCMAKE_SYSTEM_NAME=Windows \
        -DCMAKE_C_COMPILER=$WIN_CROSS_TOOL_PREFIX-w64-mingw32-gcc \
        -DCMAKE_INSTALL_PREFIX="${BUILD_DIR}" \
        -DCMAKE_RC_COMPILER=$WIN_CROSS_TOOL_PREFIX-w64-mingw32-windres \
        -DCMAKE_SHARED_LINKER_FLAGS="-static-libgcc -Wl,--strip-debug" \
        -DUSE_SHARED_MBEDTLS_LIBRARY=ON \
        -DUSE_STATIC_MBEDTLS_LIBRARY=OFF \
        -DENABLE_PROGRAMS=OFF \
        -DENABLE_TESTING=OFF \
        ${QUIET:+-Wno-deprecated -Wno-dev --log-level=ERROR}

    step "Build (${ARCH})..."
    make -j$PARALLELISM
}

_install_product() {
    ensure_dir "${PRODUCT_FOLDER}/build_${ARCH}"

    step "Install (${ARCH})..."
    $WIN_CROSS_TOOL_PREFIX-w64-mingw32-dlltool -z mbedtls.orig.def --export-all-symbols library/libmbedtls.dll
    $WIN_CROSS_TOOL_PREFIX-w64-mingw32-dlltool -z mbedcrypto.orig.def --export-all-symbols library/libmbedcrypto.dll
    $WIN_CROSS_TOOL_PREFIX-w64-mingw32-dlltool -z mbedx509.orig.def --export-all-symbols library/libmbedx509.dll
    grep "EXPORTS\|mbedtls" mbedtls.orig.def > mbedtls.def
    grep "EXPORTS\|mbedtls" mbedcrypto.orig.def > mbedcrypto.def
    grep "EXPORTS\|mbedtls" mbedx509.orig.def > mbedx509.def
    sed -i -e "/\\t.*DATA/d" -e "/\\t\".*/d" -e "s/\s@.*//" mbedtls.def
    sed -i -e "/\\t.*DATA/d" -e "/\\t\".*/d" -e "s/\s@.*//" mbedcrypto.def
    sed -i -e "/\\t.*DATA/d" -e "/\\t\".*/d" -e "s/\s@.*//" mbedx509.def
    $WIN_CROSS_TOOL_PREFIX-w64-mingw32-dlltool -m $WIN_CROSS_MVAL -d mbedtls.def -l ${BUILD_DIR}/bin/mbedtls.lib -D library/libmbedtls.dll
    $WIN_CROSS_TOOL_PREFIX-w64-mingw32-dlltool -m $WIN_CROSS_MVAL -d mbedcrypto.def -l ${BUILD_DIR}/bin/mbedcrypto.lib -D library/libmbedcrypto.dll
    $WIN_CROSS_TOOL_PREFIX-w64-mingw32-dlltool -m $WIN_CROSS_MVAL -d mbedx509.def -l ${BUILD_DIR}/bin/mbedx509.lib -D library/libmbedx509.dll

    make install
    mv "${BUILD_DIR}"/lib/*.dll "${BUILD_DIR}"/bin
    _install_pkgconfig
}

_install_pkgconfig() {
    mkdir -p "${BUILD_DIR}/lib/pkgconfig"

    bash -c "cat <<'EOF' > '${BUILD_DIR}/lib/pkgconfig/mbedcrypto.pc'
prefix='${BUILD_DIR}'
exec_prefix=\${prefix}
libdir=\${prefix}/lib
includedir=\${prefix}/include

Name: mbedcrypto
Description: lightweight crypto and SSL/TLS library.
Version: ${PRODUCT_VERSION:-${CI_PRODUCT_VERSION}}
Requires:
Conflicts:
Libs: -L\${libdir} -lmbedcrypto
Cflags: -I\${includedir} -I\${includedir}/mbedtls
EOF"

    bash -c "cat <<'EOF' > '${BUILD_DIR}/lib/pkgconfig/mbedtls.pc'
prefix='${BUILD_DIR}'
exec_prefix=\${prefix}
libdir=\${prefix}/lib
includedir=\${prefix}/include

Name: mbedtls
Description: lightweight crypto and SSL/TLS library.
Version: ${PRODUCT_VERSION:-${CI_PRODUCT_VERSION}}
Requires.private: mbedx509
Conflicts:
Libs: -L\${libdir} -lmbedtls
Cflags: -I\${includedir} -I\${includedir}/mbedtls
EOF"

    bash -c "cat <<'EOF' > '${BUILD_DIR}/lib/pkgconfig/mbedx509.pc'
prefix='${BUILD_DIR}'
exec_prefix=\${prefix}
libdir=\${prefix}/lib
includedir=\${prefix}/include

Name: mbedx509
Description: The mbedTLS X.509 library
Version: ${PRODUCT_VERSION:-${CI_PRODUCT_VERSION}}
Requires.private: mbedcrypto
Conflicts:
Libs: -L\${libdir} -lmbedx509
Cflags: -I\${includedir} -I\${includedir}/mbedtls
EOF"
}

build-mbedtls-main() {
    PRODUCT_NAME="${PRODUCT_NAME:-mbedtls}"

    if [ -z "${_RUN_OBS_BUILD_SCRIPT}" ]; then
        CHECKOUT_DIR="$(/usr/bin/git rev-parse --show-toplevel)"
        source "${CHECKOUT_DIR}/CI/include/build_support.sh"
        source "${CHECKOUT_DIR}/CI/include/build_support_windows_cross.sh"

        _check_parameters $*
        _build_checks
    fi

    NOCONTINUE=TRUE
    PRODUCT_PROJECT="ARMmbed"
    PRODUCT_REPO="mbedtls"
    PRODUCT_FOLDER="${PRODUCT_REPO}"

    if [ -z "${INSTALL}" ]; then
        _build_setup_git
        _build
    else
        _install_product
    fi
}

build-mbedtls-main $*
