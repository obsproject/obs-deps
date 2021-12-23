#!/bin/bash

##############################################################################
# macOS FFmpeg build script
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
    git add .
    git commit -m "OBS patches for flvenc, hlsenc, aomenc & librist"
}

_fixup_ffmpeg_libs() {
    LIBS=$(find "${BUILD_DIR}/lib" -type f \( -name "libav*.dylib" -o -name "libsw*.dylib" -o -name "libpostproc*.dylib" \))

    for LIB in ${LIBS}; do
        LIB_BASENAME="$(basename ${LIB})"
        LIB_NAME=${LIB_BASENAME%%.*}

        install_name_tool -delete_rpath ${BUILD_DIR}/lib "${LIB}"

        if [ "${ARCH}" = "universal" ]; then
            info "Create universal binary ${FILE}"
            if [ "${CURRENT_ARCH}" == "x86_64" ]; then
                OTHER_ARCH="arm64"
            else
                OTHER_ARCH="x86_64"
            fi

            CROSS_LIB="$(find ../build_${OTHER_ARCH} -type f -name "${LIB_NAME}*.dylib")"

            lipo -create "${LIB}" "${CROSS_LIB}" -output "${LIB}"
        fi

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

    step "Hide undesired libraries from FFmpeg..."
    if [ -d /usr/local/opt/xz ]; then
        brew unlink xz
    fi

    if [ -d /usr/local/opt/sdl2 ]; then
        brew unlink sdl2
    fi

    export LDFLAGS="-L${BUILD_DIR}/lib"
    export CFLAGS="-I${BUILD_DIR}/include"
    export LD_LIBRARY_PATH="${BUILD_DIR}/lib"

    if [ "${ARCH}" = "x86_64" -o "${ARCH}" = "universal" ]; then
        mkdir -p "${BASE_DIR}/build_x86_64"
        cd "${BASE_DIR}/build_x86_64"

        step "Configure (x86_64)..."

        PKG_CONFIG_PATH="${BUILD_DIR}/lib/pkgconfig" ../configure \
            --enable-libx264 --enable-libopus --enable-libvorbis --enable-libvpx --enable-libsrt --enable-librist --enable-libtheora --enable-libmp3lame --enable-libaom --enable-version3 --enable-gpl --enable-videotoolbox \
            --disable-libjack --disable-indev=jack --disable-outdev=sdl --disable-programs --disable-doc  \
            --enable-cross-compile --enable-shared --disable-static --enable-pthreads \
            --shlibdir="${BUILD_DIR}/lib" --pkg-config-flags="--static" --prefix="${BUILD_DIR}" --enable-rpath \
            --host-cflags="-I${BUILD_DIR}/include" --host-ldflags="-L${BUILD_DIR}/lib"  \
            --extra-ldflags="-target x86_64-apple-macos10.13 -L${BUILD_DIR}/lib -lstdc++" \
            --extra-cflags="-fno-stack-check -target x86_64-apple-macos10.13 -I${BUILD_DIR}/include" \
            --arch=x86_64

        step "Build (x86_64)..."
        make -j${PARALLELISM}
    fi

    if [ "${ARCH}" = "arm64" -o "${ARCH}" = "universal" ]; then
        mkdir -p "${BASE_DIR}/build_arm64"
        cd "${BASE_DIR}/build_arm64"

        step "Configure (arm64)..."
        PKG_CONFIG_PATH="${BUILD_DIR}/lib/pkgconfig" ../configure \
            --enable-libx264 --enable-libopus --enable-libvorbis --enable-libvpx --enable-libsrt --enable-librist --enable-libtheora --enable-libmp3lame --enable-libaom --enable-version3 --enable-gpl --enable-videotoolbox \
            --disable-libjack --disable-indev=jack --disable-outdev=sdl --disable-programs --disable-doc  \
            --enable-cross-compile --enable-shared --disable-static --enable-pthreads --enable-rpath \
            --shlibdir="${BUILD_DIR}/lib" --pkg-config-flags="--static" --prefix="${BUILD_DIR}" \
            --host-cflags="-I${BUILD_DIR}/include" --host-ldflags="-L${BUILD_DIR}/lib"  \
            --extra-ldflags="-target arm64-apple-macos11 -L${BUILD_DIR}/lib -lstdc++" \
            --extra-cflags="-fno-stack-check -target arm64-apple-macos11 -I${BUILD_DIR}/include" \
            --arch=arm64

        step "Build (arm64)..."
        make -j${PARALLELISM}
    fi

    step "Restore hidden libraries..."
    if [ -d /usr/local/opt/xz ] && [ ! -f /usr/local/lib/liblzma.dylib ]; then
        brew link xz
    fi

    if [ -d /usr/local/opt/sdl2 ] && ! [ -f /usr/local/lib/libSDL2.dylib ]; then
        brew link sdl2
    fi

    unset LDFLAGS
    unset CFLAGS
    unset LD_LIBRARY_PATH
}

_install_product() {
    if [ "${ARCH}" = "universal" ]; then
        cd "${PRODUCT_FOLDER}/build_${CURRENT_ARCH}"
    else
        cd "${PRODUCT_FOLDER}/build_${ARCH}"
    fi

    step "Install..."
    make install

    _fixup_ffmpeg_libs
}

build-ffmpeg-main() {
    PRODUCT_NAME="${PRODUCT_NAME:-ffmpeg}"

    if [ -z "${_RUN_OBS_BUILD_SCRIPT}" ]; then
        CHECKOUT_DIR="$(/usr/bin/git rev-parse --show-toplevel)"
        source "${CHECKOUT_DIR}/CI/include/build_support.sh"
        source "${CHECKOUT_DIR}/CI/include/build_support_macos.sh"

        _check_parameters $*
        _build_checks
    fi

    PRODUCT_PROJECT="FFmpeg"
    PRODUCT_REPO="ffmpeg"
    PRODUCT_FOLDER="${PRODUCT_REPO}-${PRODUCT_VERSION:-${CI_PRODUCT_VERSION}}"

    if [ -z "${INSTALL}" ]; then
        _add_ccache_to_path

        _build_setup_git
        _build
   else
        _install_product
    fi
}

build-ffmpeg-main $*
