#!/usr/bin/env bash

set -e

# This script builds a tar file that contains a bunch of deps that OBS needs for
# advanced functionality on OSX. Currently this tar file is pulled down off of s3
# and used in the CI build process on travis.
# Mostly this sets build flags to compile with older SDKS and make sure that 
# the libs are portable.

exists()
{
  command -v "$1" >/dev/null 2>&1
}

if ! exists nasm; then
    echo "nasm not found. Try brew install nasm"
    exit
fi

CURDIR=$(pwd)

# the temp directory
WORK_DIR=`mktemp -d`

# deletes the temp directory
function cleanup {
  #rm -rf "$WORK_DIR"
  echo "Deleted temp working directory $WORK_DIR"
}

# register the cleanup function to be called on the EXIT signal
trap cleanup EXIT

cd $WORK_DIR

DEPS_DEST=$WORK_DIR/obsdeps

# make dest dirs
mkdir $DEPS_DEST
mkdir $DEPS_DEST/bin
mkdir $DEPS_DEST/include
mkdir $DEPS_DEST/lib

# OSX COMPAT
export MACOSX_DEPLOYMENT_TARGET=10.11

# If you need an olders SDK and Xcode won't give it to you
# https://github.com/phracker/MacOSX-SDKs

export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:/tmp/obsdeps/lib/pkgconfig

# libopus
curl -L -O https://ftp.osuosl.org/pub/xiph/releases/opus/opus-1.3.1.tar.gz
tar -xf opus-1.3.1.tar.gz
cd ./opus-1.3.1
mkdir build
cd ./build
../configure --disable-shared --enable-static --prefix="/tmp/obsdeps"
make -j
make install

cd $WORK_DIR

# libogg
curl -L -o ogg-68ca384.tar.gz 'https://git.xiph.org/?p=ogg.git;a=snapshot;h=68ca3841567247ac1f7850801a164f58738d8df9;sf=tgz'
tar -xf ogg-68ca384.tar.gz
cd ./ogg-68ca384
mkdir build
./autogen.sh
cd ./build
../configure --disable-shared --enable-static --prefix="/tmp/obsdeps"
make -j
make install

cd $WORK_DIR

# libvorbis
curl -L -O https://ftp.osuosl.org/pub/xiph/releases/vorbis/libvorbis-1.3.6.tar.gz
tar -xf libvorbis-1.3.6.tar.gz
cd ./libvorbis-1.3.6
mkdir build
cd ./build
../configure --disable-shared --enable-static --prefix="/tmp/obsdeps"
make -j
make install

cd $WORK_DIR

# libvpx
curl -L -O https://chromium.googlesource.com/webm/libvpx/+archive/v1.8.2.tar.gz
mkdir -p ./libvpx-v1.8.2
tar -xf v1.8.2.tar.gz -C $PWD/libvpx-v1.8.2
cd ./libvpx-v1.8.2
mkdir -p build
cd ./build
../configure --disable-shared --prefix="/tmp/obsdeps" --libdir="/tmp/obsdeps/lib"
make -j
make install

cd $WORK_DIR

# x264
git clone https://code.videolan.org/videolan/x264.git
cd ./x264
git checkout origin/stable
mkdir build
cd ./build
../configure --extra-ldflags="-mmacosx-version-min=10.11" --enable-static --prefix="/tmp/obsdeps"
make -j
make install
../configure --extra-ldflags="-mmacosx-version-min=10.11" --enable-shared --libdir="/tmp/obsdeps/bin" --prefix="/tmp/obsdeps"
make -j
ln -f -s libx264.*.dylib libx264.dylib
find . -name \*.dylib -exec cp \{\} $DEPS_DEST/bin/ \;
rsync -avh --include="*/" --include="*.h" --exclude="*" ../* $DEPS_DEST/include/
rsync -avh --include="*/" --include="*.h" --exclude="*" ./* $DEPS_DEST/include/

cd $WORK_DIR

# janson
curl -L -O http://www.digip.org/jansson/releases/jansson-2.12.tar.gz
tar -xf jansson-2.12.tar.gz
cd jansson-2.12
mkdir build
cd ./build
../configure --libdir="/tmp/obsdeps/bin" --enable-shared --disable-static
make -j
find . -name \*.dylib -exec cp \{\} $DEPS_DEST/bin/ \;
rsync -avh --include="*/" --include="*.h" --exclude="*" ../* $DEPS_DEST/include/
rsync -avh --include="*/" --include="*.h" --exclude="*" ./* $DEPS_DEST/include/

cd $WORK_DIR

# mbedtls
curl -L -O https://tls.mbed.org/download/mbedtls-2.16.5-apache.tgz
tar -xf mbedtls-2.16.5-apache.tgz
cd mbedtls-2.16.5
sed -i '.orig' 's/\/\/\#define MBEDTLS_THREADING_PTHREAD/\#define MBEDTLS_THREADING_PTHREAD/g' include/mbedtls/config.h
sed -i '.orig' 's/\/\/\#define MBEDTLS_THREADING_C/\#define MBEDTLS_THREADING_C/g' include/mbedtls/config.h
mkdir build
cd ./build
cmake -DCMAKE_INSTALL_PREFIX="/tmp/obsdeps" -DUSE_SHARED_MBEDTLS_LIBRARY=ON -DCMAKE_FIND_FRAMEWORK=LAST -DENABLE_PROGRAMS=OFF ..
make -j
make install
find /tmp/obsdeps/lib -name libmbed\*.dylib -exec cp \{\} $DEPS_DEST/bin/ \;
install_name_tool -id $DEPS_DEST/bin/libmbedtls.12.dylib $DEPS_DEST/bin/libmbedtls.12.dylib
install_name_tool -id $DEPS_DEST/bin/libmbedcrypto.3.dylib $DEPS_DEST/bin/libmbedcrypto.3.dylib
install_name_tool -id $DEPS_DEST/bin/libmbedx509.0.dylib $DEPS_DEST/bin/libmbedx509.0.dylib
install_name_tool -change libmbedtls.12.dylib $DEPS_DEST/bin/libmbedtls.12.dylib $DEPS_DEST/bin/libmbedcrypto.3.dylib
install_name_tool -change libmbedx509.0.dylib $DEPS_DEST/bin/libmbedx509.0.dylib $DEPS_DEST/bin/libmbedx509.0.dylib
install_name_tool -change libmbedcrypto.3.dylib $DEPS_DEST/bin/libmbedcrypto.3.dylib $DEPS_DEST/bin/libmbedx509.0.dylib
install_name_tool -change libmbedtls.12.dylib $DEPS_DEST/bin/libmbedtls.12.dylib $DEPS_DEST/bin/libmbedtls.12.dylib
install_name_tool -change libmbedx509.0.dylib $DEPS_DEST/bin/libmbedx509.0.dylib $DEPS_DEST/bin/libmbedtls.12.dylib
install_name_tool -change libmbedcrypto.3.dylib $DEPS_DEST/bin/libmbedcrypto.3.dylib $DEPS_DEST/bin/libmbedtls.12.dylib
rsync -avh --include="*/" --include="*.h" --exclude="*" ./include/mbedtls/* $DEPS_DEST/include/mbedtls
rsync -avh --include="*/" --include="*.h" --exclude="*" ../include/mbedtls/* $DEPS_DEST/include/mbedtls
if ! [ -d /tmp/obsdeps/lib/pkgconfig ]; then
    mkdir -p /tmp/obsdeps/lib/pkgconfig
fi
cat <<EOF > /tmp/obsdeps/lib/pkgconfig/mbedcrypto.pc
prefix=/tmp/obsdeps
libdir=\${prefix}/lib
includedir=\${prefix}/include

Name: mbedcrypto
Description: lightweight crypto and SSL/TLS library.
Version: 2.16.5

Libs: -L\${libdir} -lmbedcrypto
Cflags: -I\${includedir}
EOF
cat <<EOF > /tmp/obsdeps/lib/pkgconfig/mbedtls.pc
prefix=/tmp/obsdeps
libdir=\${prefix}/lib
includedir=\${prefix}/include

Name: mbedtls
Description: lightweight crypto and SSL/TLS library.
Version: 2.16.5

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
Version: 2.16.5

Libs: -L\${libdir} -lmbedx509
Cflags: -I\${includedir}
Requires.private: mbedcrypto
EOF

cd $WORK_DIR

# srt
curl -L -O https://github.com/Haivision/srt/archive/v1.4.1.tar.gz
tar -xf v1.4.1.tar.gz
cd srt-1.4.1
mkdir build
cd ./build
cmake -DCMAKE_INSTALL_PREFIX="/tmp/obsdeps" -DENABLE_APPS=OFF -DUSE_ENCLIB="mbedtls" -DENABLE_STATIC=ON -DENABLE_SHARED=OFF  -DSSL_INCLUDE_DIRS="/tmp/obsdeps/include" -DSSL_LIBRARY_DIRS="/tmp/obsdeps/lib" -DCMAKE_FIND_FRAMEWORK=LAST ..
make -j
make install

cd $WORK_DIR
export LDFLAGS="-L/tmp/obsdeps/lib"
export CFLAGS="-I/tmp/obsdeps/include"
export LD_LIBRARY_PATH="/tmp/obsdeps/lib"

# FFMPEG
curl -L -O https://github.com/FFmpeg/FFmpeg/archive/n4.2.2.zip
unzip ./n4.2.2.zip
cd ./FFmpeg-n4.2.2
mkdir build
cd ./build
../configure --pkg-config-flags="--static" --extra-ldflags="-mmacosx-version-min=10.11" --enable-shared --disable-static --shlibdir="/tmp/obsdeps/bin" --enable-gpl --disable-doc --enable-libx264 --enable-libopus --enable-libvorbis --enable-libvpx --enable-libsrt --disable-outdev=sdl
make -j
find . -name \*.dylib -exec cp \{\} $DEPS_DEST/bin/ \;
rsync -avh --include="*/" --include="*.h" --exclude="*" ../* $DEPS_DEST/include/
rsync -avh --include="*/" --include="*.h" --exclude="*" ./* $DEPS_DEST/include/
install_name_tool -change libmbedcrypto.3.dylib /tmp/obsdeps/bin/libmbedcrypto.3.dylib $DEPS_DEST/bin/libavfilter.7.dylib
install_name_tool -change libmbedcrypto.3.dylib /tmp/obsdeps/bin/libmbedcrypto.3.dylib $DEPS_DEST/bin/libavdevice.58.dylib
install_name_tool -change libmbedcrypto.3.dylib /tmp/obsdeps/bin/libmbedcrypto.3.dylib $DEPS_DEST/bin/libavformat.58.dylib
install_name_tool -change libmbedx509.0.dylib /tmp/obsdeps/bin/libmbedx509.0.dylib $DEPS_DEST/bin/libavfilter.7.dylib
install_name_tool -change libmbedx509.0.dylib /tmp/obsdeps/bin/libmbedx509.0.dylib $DEPS_DEST/bin/libavdevice.58.dylib
install_name_tool -change libmbedx509.0.dylib /tmp/obsdeps/bin/libmbedx509.0.dylib $DEPS_DEST/bin/libavformat.58.dylib
install_name_tool -change libmbedtls.12.dylib /tmp/obsdeps/bin/libmbedtls.12.dylib $DEPS_DEST/bin/libavfilter.7.dylib
install_name_tool -change libmbedtls.12.dylib /tmp/obsdeps/bin/libmbedtls.12.dylib $DEPS_DEST/bin/libavdevice.58.dylib
install_name_tool -change libmbedtls.12.dylib /tmp/obsdeps/bin/libmbedtls.12.dylib $DEPS_DEST/bin/libavformat.58.dylib

cd $WORK_DIR

#luajit
curl -L -O https://luajit.org/download/LuaJIT-2.0.5.tar.gz
tar -xf LuaJIT-2.0.5.tar.gz
cd LuaJIT-2.0.5
make PREFIX=/tmp/obsdeps
make PREFIX=/tmp/obsdeps install
find /tmp/obsdeps/lib -name libluajit\*.dylib -exec cp \{\} $DEPS_DEST/lib/ \;
rsync -avh --include="*/" --include="*.h" --exclude="*" src/* $DEPS_DEST/include/
make PREFIX=/tmp/obsdeps uninstall

cd $WORK_DIR

tar -czf osx-deps.tar.gz obsdeps

mkdir $CURDIR/osx
cp ./osx-deps.tar.gz $CURDIR/osx
