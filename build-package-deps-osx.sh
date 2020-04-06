#!/usr/bin/env bash

set -eE

# This script builds a tar file that contains a bunch of deps that OBS needs for
# advanced functionality on OSX. Currently this tar file is pulled down off of s3
# and used in the CI build process on travis.
# Mostly this sets build flags to compile with older SDKS and make sure that
# the libs are portable.

BUILD_PACKAGES=(
    "opus 1.3.1"
    "ogg 68ca384"
    "vorbis 1.3.6"
    "vpx 1.8.2"
    "jansson 2.12"
    "x264 origin/stable"
    "mbedtls 2.16.5"
    "srt 1.4.1"
    "ffmpeg 4.2.2"
    "luajit 2.0.5"
)

## START UTILITIES ##
hr() {
  echo "───────────────────────────────────────────────────"
  echo -e $1
  echo "───────────────────────────────────────────────────"
}

exists()
{
  command -v "$1" >/dev/null 2>&1
}

# deletes the temp directory
cleanup() {
  rm -rf "${WORK_DIR}/*"
  hr "Deleted contents of temp working directory ${WORK_DIR}"
}

# register the cleanup function to be called on the EXIT signal
trap cleanup EXIT

caught_error() {
    hr "ERROR while building package ${1}"
    exit 1
}

## END UTILITIES ##

## START DEPENDENCIES ##
for DEPENDENCY in nasm automake pkg-config; do
    if ! exists ${DEPENDENCY}; then
        hr "${DEPENDENCY} not found. Please install homebrew (https://brew.sh) and run './osx-install-tools.sh'."
        exit 1
    fi
done
## END DEPENDENCIES ##

## START ENV SETUP ##
CURDIR=$(pwd)
# the temp directory
WORK_DIR=`mktemp -d`
cd ${WORK_DIR}

DEPS_DEST=${WORK_DIR}/obsdeps

# make dest dirs
mkdir ${DEPS_DEST}
mkdir ${DEPS_DEST}/bin
mkdir ${DEPS_DEST}/include
mkdir ${DEPS_DEST}/lib

# OSX COMPAT
export MACOSX_DEPLOYMENT_TARGET=10.11

# If you need an olders SDK and Xcode won't give it to you
# https://github.com/phracker/MacOSX-SDKs
export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:/tmp/obsdeps/lib/pkgconfig
## END ENV SETUP ##

## START BUILD FUNCS ##

build_opus() {
    OPUS_VERSION=${1}
    hr "Building libopus v${OPUS_VERSION}"

    # libopus
    curl -L -O https://ftp.osuosl.org/pub/xiph/releases/opus/opus-${OPUS_VERSION}.tar.gz
    tar -xf opus-${OPUS_VERSION}.tar.gz
    cd ./opus-${OPUS_VERSION}
    mkdir build
    cd ./build
    ../configure --disable-shared --enable-static --prefix="/tmp/obsdeps"
    make -j
    make install

    cd $WORK_DIR
}

build_ogg() {
    OGG_VERSION=${1}
    hr "Building libogg v${OGG_VERSION}"

    # libogg
    curl -L -o ogg-${OGG_VERSION}.tar.gz 'https://git.xiph.org/?p=ogg.git;a=snapshot;h=68ca3841567247ac1f7850801a164f58738d8df9;sf=tgz'
    tar -xf ogg-${OGG_VERSION}.tar.gz
    cd ./ogg-${OGG_VERSION}
    mkdir build
    ./autogen.sh
    cd ./build
    ../configure --disable-shared --enable-static --prefix="/tmp/obsdeps"
    make -j
    make install

    cd $WORK_DIR
}

build_vorbis() {
    VORBIS_VERSION=${1}
    hr "Building libvorbis v${VORBIS_VERSION}"
    # libvorbis
    curl -L -O https://ftp.osuosl.org/pub/xiph/releases/vorbis/libvorbis-${VORBIS_VERSION}.tar.gz
    tar -xf libvorbis-${VORBIS_VERSION}.tar.gz
    cd ./libvorbis-${VORBIS_VERSION}
    mkdir build
    cd ./build
    ../configure --disable-shared --enable-static --prefix="/tmp/obsdeps"
    make -j
    make install

    cd $WORK_DIR
}

build_vpx() {
    VPX_VERSION=${1}
    hr "Building libvpx v${VPX_VERSION}"

    # libvpx
    curl -L -O https://chromium.googlesource.com/webm/libvpx/+archive/v${VPX_VERSION}.tar.gz
    mkdir -p ./libvpx-v${VPX_VERSION}
    tar -xf v${VPX_VERSION}.tar.gz -C $PWD/libvpx-v${VPX_VERSION}
    cd ./libvpx-v${VPX_VERSION}
    mkdir -p build
    cd ./build
    ../configure --disable-shared --prefix="/tmp/obsdeps" --libdir="/tmp/obsdeps/lib"
    make -j
    make install

    cd $WORK_DIR
}

build_x264() {
    X264_VERSION=${1}
    hr "Building x264 ${X264_VERSION}"

    # x264
    git clone https://code.videolan.org/videolan/x264.git
    cd ./x264
    git checkout ${X264_VERSION}
    mkdir build
    cd ./build
    ../configure --extra-ldflags="-mmacosx-version-min=10.11" --enable-static --prefix="/tmp/obsdeps"
    make -j
    make install
    ../configure --extra-ldflags="-mmacosx-version-min=10.11" --enable-shared --libdir="/tmp/obsdeps/bin" --prefix="/tmp/obsdeps"
    make -j
    ln -f -s libx264.*.dylib libx264.dylib
    find . -name \*.dylib -exec cp \{\} ${DEPS_DEST}/bin/ \;
    rsync -avh --include="*/" --include="*.h" --exclude="*" ../* ${DEPS_DEST}/include/
    rsync -avh --include="*/" --include="*.h" --exclude="*" ./* ${DEPS_DEST}/include/

    cd $WORK_DIR
}

build_jansson() {
    JANSSON_VERSION=${1}
    hr "Building libjansson v${JANSSON_VERSION}"

    # janson
    curl -L -O http://www.digip.org/jansson/releases/jansson-${JANSSON_VERSION}.tar.gz
    tar -xf jansson-${JANSSON_VERSION}.tar.gz
    cd jansson-${JANSSON_VERSION}
    mkdir build
    cd ./build
    ../configure --libdir="/tmp/obsdeps/bin" --enable-shared --disable-static
    make -j
    find . -name \*.dylib -exec cp \{\} ${DEPS_DEST}/bin/ \;
    rsync -avh --include="*/" --include="*.h" --exclude="*" ../* ${DEPS_DEST}/include/
    rsync -avh --include="*/" --include="*.h" --exclude="*" ./* ${DEPS_DEST}/include/

    cd $WORK_DIR
}

build_mbedtls() {
    MBEDTLS_VERSION=${1}
    hr "Building mbedtls v${MBEDTLS_VERSION}"

    # mbedtls
    curl -L -O https://tls.mbed.org/download/mbedtls-${MBEDTLS_VERSION}-apache.tgz
    tar -xf mbedtls-${MBEDTLS_VERSION}-apache.tgz
    cd mbedtls-${MBEDTLS_VERSION}
    sed -i '.orig' 's/\/\/\#define MBEDTLS_THREADING_PTHREAD/\#define MBEDTLS_THREADING_PTHREAD/g' include/mbedtls/config.h
    sed -i '.orig' 's/\/\/\#define MBEDTLS_THREADING_C/\#define MBEDTLS_THREADING_C/g' include/mbedtls/config.h
    mkdir build
    cd ./build
    cmake -DCMAKE_INSTALL_PREFIX="/tmp/obsdeps" -DUSE_SHARED_MBEDTLS_LIBRARY=ON -DCMAKE_FIND_FRAMEWORK=LAST -DENABLE_PROGRAMS=OFF ..
    make -j
    make install
    find /tmp/obsdeps/lib -name libmbed\*.dylib -exec cp \{\} ${DEPS_DEST}/bin/ \;
    install_name_tool -id /tmp/obsdeps/bin/libmbedtls.12.dylib ${DEPS_DEST}/bin/libmbedtls.12.dylib
    install_name_tool -id /tmp/obsdeps/bin/libmbedcrypto.3.dylib ${DEPS_DEST}/bin/libmbedcrypto.3.dylib
    install_name_tool -id /tmp/obsdeps/bin/libmbedx509.0.dylib ${DEPS_DEST}/bin/libmbedx509.0.dylib
    install_name_tool -change libmbedtls.12.dylib /tmp/obsdeps/bin/libmbedtls.12.dylib ${DEPS_DEST}/bin/libmbedcrypto.3.dylib
    install_name_tool -change libmbedx509.0.dylib /tmp/obsdeps/bin/libmbedx509.0.dylib ${DEPS_DEST}/bin/libmbedx509.0.dylib
    install_name_tool -change libmbedcrypto.3.dylib /tmp/obsdeps/bin/libmbedcrypto.3.dylib ${DEPS_DEST}/bin/libmbedx509.0.dylib
    install_name_tool -change libmbedtls.12.dylib /tmp/obsdeps/bin/libmbedtls.12.dylib ${DEPS_DEST}/bin/libmbedtls.12.dylib
    install_name_tool -change libmbedx509.0.dylib /tmp/obsdeps/bin/libmbedx509.0.dylib ${DEPS_DEST}/bin/libmbedtls.12.dylib
    install_name_tool -change libmbedcrypto.3.dylib /tmp/obsdeps/bin/libmbedcrypto.3.dylib ${DEPS_DEST}/bin/libmbedtls.12.dylib
    rsync -avh --include="*/" --include="*.h" --exclude="*" ./include/mbedtls/* ${DEPS_DEST}/include/mbedtls
    rsync -avh --include="*/" --include="*.h" --exclude="*" ../include/mbedtls/* ${DEPS_DEST}/include/mbedtls
    if ! [ -d /tmp/obsdeps/lib/pkgconfig ]; then
        mkdir -p /tmp/obsdeps/lib/pkgconfig
    fi
    cat <<EOF > /tmp/obsdeps/lib/pkgconfig/mbedcrypto.pc
prefix=/tmp/obsdeps
libdir=\${prefix}/lib
includedir=\${prefix}/include

Name: mbedcrypto
Description: lightweight crypto and SSL/TLS library.
Version: ${MBEDTLS_VERSION}

Libs: -L\${libdir} -lmbedcrypto
Cflags: -I\${includedir}
EOF
    cat <<EOF > /tmp/obsdeps/lib/pkgconfig/mbedtls.pc
prefix=/tmp/obsdeps
libdir=\${prefix}/lib
includedir=\${prefix}/include

Name: mbedtls
Description: lightweight crypto and SSL/TLS library.
Version: ${MBEDTLS_VERSION}

Libs: -L\${libdir} -lmbedtls
Cflags: -I\${includedir}
Requires.private: mbedx509
EOF
    cat <<EOF > /tmp/obsdeps/lib/pkgconfig/mbedx509.pc
prefix=/tmp/obsdeps
libdir=\${prefix}/lib
includedir=\${prefix}/include

Name: mbedx509
Description: The mbedTLS X.509 library
Version: ${MBEDTLS_VERSION}

Libs: -L\${libdir} -lmbedx509
Cflags: -I\${includedir}
Requires.private: mbedcrypto
EOF

    cd $WORK_DIR
}

build_srt() {
    SRT_VERSION=${1}
    hr "Building libsrt v${SRT_VERSION}"

    # srt
    curl -L -O https://github.com/Haivision/srt/archive/v${SRT_VERSION}.tar.gz
    tar -xf v${SRT_VERSION}.tar.gz
    cd srt-${SRT_VERSION}
    mkdir build
    cd ./build
    cmake -DCMAKE_INSTALL_PREFIX="/tmp/obsdeps" -DENABLE_APPS=OFF -DUSE_ENCLIB="mbedtls" -DENABLE_STATIC=ON -DENABLE_SHARED=OFF  -DSSL_INCLUDE_DIRS="/tmp/obsdeps/include" -DSSL_LIBRARY_DIRS="/tmp/obsdeps/lib" -DCMAKE_FIND_FRAMEWORK=LAST ..
    make -j
    make install

    cd $WORK_DIR
}

build_ffmpeg() {
    FFMPEG_VERSION=${1}
    hr "Building ffmpeg v${FFMPEG_VERSION}"

    export LDFLAGS="-L/tmp/obsdeps/lib"
    export CFLAGS="-I/tmp/obsdeps/include"
    export LD_LIBRARY_PATH="/tmp/obsdeps/lib"

    # FFMPEG
    curl -L -O https://github.com/FFmpeg/FFmpeg/archive/n${FFMPEG_VERSION}.zip
    unzip ./n${FFMPEG_VERSION}.zip
    cd ./FFmpeg-n${FFMPEG_VERSION}
    mkdir build
    cd ./build
    ../configure --pkg-config-flags="--static" --extra-ldflags="-mmacosx-version-min=10.11" --enable-shared --disable-static --shlibdir="/tmp/obsdeps/bin" --enable-gpl --disable-doc --enable-libx264 --enable-libopus --enable-libvorbis --enable-libvpx --enable-libsrt --disable-outdev=sdl
    make -j
    find . -name \*.dylib -exec cp \{\} ${DEPS_DEST}/bin/ \;
    rsync -avh --include="*/" --include="*.h" --exclude="*" ../* ${DEPS_DEST}/include/
    rsync -avh --include="*/" --include="*.h" --exclude="*" ./* ${DEPS_DEST}/include/
    install_name_tool -change libmbedcrypto.3.dylib /tmp/obsdeps/bin/libmbedcrypto.3.dylib ${DEPS_DEST}/bin/libavfilter.7.dylib
    install_name_tool -change libmbedcrypto.3.dylib /tmp/obsdeps/bin/libmbedcrypto.3.dylib ${DEPS_DEST}/bin/libavdevice.58.dylib
    install_name_tool -change libmbedcrypto.3.dylib /tmp/obsdeps/bin/libmbedcrypto.3.dylib ${DEPS_DEST}/bin/libavformat.58.dylib
    install_name_tool -change libmbedx509.0.dylib /tmp/obsdeps/bin/libmbedx509.0.dylib ${DEPS_DEST}/bin/libavfilter.7.dylib
    install_name_tool -change libmbedx509.0.dylib /tmp/obsdeps/bin/libmbedx509.0.dylib ${DEPS_DEST}/bin/libavdevice.58.dylib
    install_name_tool -change libmbedx509.0.dylib /tmp/obsdeps/bin/libmbedx509.0.dylib ${DEPS_DEST}/bin/libavformat.58.dylib
    install_name_tool -change libmbedtls.12.dylib /tmp/obsdeps/bin/libmbedtls.12.dylib ${DEPS_DEST}/bin/libavfilter.7.dylib
    install_name_tool -change libmbedtls.12.dylib /tmp/obsdeps/bin/libmbedtls.12.dylib ${DEPS_DEST}/bin/libavdevice.58.dylib
    install_name_tool -change libmbedtls.12.dylib /tmp/obsdeps/bin/libmbedtls.12.dylib ${DEPS_DEST}/bin/libavformat.58.dylib

    unset LDFLAGS
    unset CFLAGS
    unset LD_LIBRARY_PATH
    cd $WORK_DIR
}

build_luajit() {
    LUAJIT_VERSION=${1}
    hr "Building libluajit v${LUAJIT_VERSION}"

    #luajit
    curl -L -O https://luajit.org/download/LuaJIT-${LUAJIT_VERSION}.tar.gz
    tar -xf LuaJIT-${LUAJIT_VERSION}.tar.gz
    cd LuaJIT-${LUAJIT_VERSION}
    make PREFIX=/tmp/obsdeps
    make PREFIX=/tmp/obsdeps install
    find /tmp/obsdeps/lib -name libluajit\*.dylib -exec cp \{\} ${DEPS_DEST}/lib/ \;
    rsync -avh --include="*/" --include="*.h" --exclude="*" src/* ${DEPS_DEST}/include/
    make PREFIX=/tmp/obsdeps uninstall

    cd $WORK_DIR
}
## END BUILD FUNCS ##

package_deps() {
    VERSION=${1}

    hr "Packaging dependencies as osx-deps-${VERSION}.tar.gz.."

    tar -czf osx-deps-${VERSION}.tar.gz obsdeps

    if ! [ -d "${CURDIR}/osx" ]; then
        mkdir ${CURDIR}/osx
    fi
    cp ./osx-deps-${VERSION}.tar.gz ${CURDIR}/osx
}

BUILD_INFO="Building OBS macOS dependencies with this configuration:"

for PACKAGE in "${BUILD_PACKAGES[@]}"; do
    set -- ${PACKAGE}
    BUILD_INFO="${BUILD_INFO}\n${1}\t: ${2}"
done

hr "${BUILD_INFO}"

for PACKAGE in "${BUILD_PACKAGES[@]}"; do
    set -- ${PACKAGE}
    trap 'caught_error ${1}' ERR
    FUNC_NAME="build_${1}"
    ${FUNC_NAME} ${2}
done

package_deps "$(date +"%Y-%m-%d")"

hr "All Done!"
