#!/bin/bash

################################################################################
# Windows FFmpeg cross-compile build script
################################################################################
#
# This script file can be included in build scripts for Windows or run directly
#
################################################################################

# Halt on errors
set -eE

_patch_product() {
    cd "${PRODUCT_FOLDER}"

    set +eE
    check_git
    set -eE

    step "Apply patches..."
    # apply flv, hls, aom patch
    apply_patch "${CHECKOUT_DIR}/CI/patches/FFmpeg-9010.patch" "97ac6385c2b7a682360c0cfb3e311ef4f3a48041d3f097d6b64f8c13653b6450"
    apply_patch "${CHECKOUT_DIR}/CI/patches/FFmpeg-4.4.1-OBS.patch" "710fb5a381f7b68c95dcdf865af4f3c63a9405c305abef55d24c7ab54e90b182"
   # The librist patch consists in these 3 commits which haven't been backported to FFmpeg 4.4 :
    # [1] avformat/internal: Move ff_read_line_to_bprint_overwrite to avio_internal.h
    # https://github.com/FFmpeg/FFmpeg/commit/fd101c9c3bcdeb2d74274aaeaa968fe8ead3622d#diff-bc82665cda5e82b13bcd3e1ee74d820952d80acba839ac46ffed3f0785644200
    # [2] avformat/librist: replace deprecated functions
    # https://github.com/FFmpeg/FFmpeg/commit/5274f2f7f8c5e40d18b84055fbb232752bd24f2f#diff-bc82665cda5e82b13bcd3e1ee74d820952d80acba839ac46ffed3f0785644200
    # [3] avformat/librist: correctly initialize logging_settings
    # https://github.com/FFmpeg/FFmpeg/commit/9b15f43cf8c7976fba115da686a990377f7b5ab9
    # The following is an important patch submitted by librist devs, but not yet merged into FFmpeg master
    # [4] avformat/librist: allow setting fifo size and fail on overflow.
    # http://ffmpeg.org/pipermail/ffmpeg-devel/2021-November/287914.html
    apply_patch "${CHECKOUT_DIR}/CI/patches/FFmpeg-4.4.1-libaomenc.patch" "AEDBA40CEA296D73CBF8BFC6365C0D93237F9177986B96B07C1D2C4C5CFB896C"
    apply_patch "${CHECKOUT_DIR}/CI/patches/FFmpeg-4.4.1-librist.patch" "1B95F21375421830263A73C74B80852E60EFE10991513CFCC8FB7CBE066887F5"

    # Apply patches for libavcodec/libsvtav1
    apply_patch "https://github.com/obsproject/FFmpeg/commit/9ee65983b32b3aa637a839f5171aa16d7bc3650d.patch?full_index=1" "a7b0850f6ab1e688a02ba98f05b2a60d6fc1cb306ca825a3bd4e7eacb2fc0a75"
    apply_patch "https://github.com/obsproject/FFmpeg/commit/3558b7c140f86551cd65e7e7aa9815cc2db6e16b.patch?full_index=1" "865bbc3dd389569786a6f6972faee7d3e36a7f0d724226c286dd2dfa8ac4efdf"
    apply_patch "https://github.com/obsproject/FFmpeg/commit/8451b7c1d4ade3477b9446b8cd5bfd6ddbf71e83.patch?full_index=1" "5c41f4702927b0dc35fae9d22f32f6d2ac54f69ca7042e375a38ffdd17fff3af"
    apply_patch "https://github.com/obsproject/FFmpeg/commit/2927d888cbfda5d19b3147eb5b3a6f423b23cc33.patch?full_index=1" "5d00f30410a3ceb8c47bcd14935151ead13ed834d87e570771836b1e3e7b768a"

    git add .
    git commit -m "OBS patches for flvenc, hlsenc, aomenc & librist"
}

_build_product() {
    ensure_dir "${PRODUCT_FOLDER}"

    step "Configure (${ARCH})..."
    make clean >&2 || true

    if [ "${ARCH}" = "x86" ]; then
        SWITCH="disable"
    else
        SWITCH="enable"
    fi

    PKG_CONFIG_PATH="${BUILD_DIR}/lib/pkgconfig" \
        LDFLAGS="-L${BUILD_DIR}/lib -static-libgcc" \
        CFLAGS="-I${BUILD_DIR}/include -I${CHECKOUT_DIR}/windows_cross_build_temp/pthread-win32" \
        CPPFLAGS="-I${BUILD_DIR}/include -I${CHECKOUT_DIR}/windows_cross_build_temp/pthread-win32" \
        ./configure \
        --enable-gpl \
        --disable-programs \
        --disable-doc \
        --arch=$WIN_CROSS_TARGET \
        --enable-shared \
        --enable-nvenc \
        --enable-amf \
        --enable-libx264 \
        --enable-libopus \
        --enable-libvorbis \
        --enable-libvpx \
        --enable-libsrt \
        --enable-librist \
        --$SWITCH-libaom \
        --$SWITCH-libsvtav1 \
        --disable-debug \
        --cross-prefix=$WIN_CROSS_TOOL_PREFIX-w64-mingw32- \
        --target-os=mingw32 \
        --pkg-config=pkg-config \
        --prefix="${BUILD_DIR}" \
        --disable-postproc

    step "Build (${ARCH})..."
    make -j$PARALLELISM
}

_install_product() {
    cd "${PRODUCT_FOLDER}"

    step "Install..."
    make install
}

build-ffmpeg-main() {
    PRODUCT_NAME="${PRODUCT_NAME:-ffmpeg}"

    if [ -z "${_RUN_OBS_BUILD_SCRIPT}" ]; then
        CHECKOUT_DIR="$(/usr/bin/git rev-parse --show-toplevel)"
        source "${CHECKOUT_DIR}/CI/include/build_support.sh"
        source "${CHECKOUT_DIR}/CI/include/build_support_windows_cross.sh"

        _check_parameters $*
        _build_checks
    fi

    PRODUCT_PROJECT="FFmpeg"
    PRODUCT_REPO="ffmpeg"
    PRODUCT_FOLDER="ffmpeg"

    if [ -z "${INSTALL}" ]; then
        _add_ccache_to_path

        _build_setup_git
        _build
   else
        _install_product
    fi
}

build-ffmpeg-main $*
