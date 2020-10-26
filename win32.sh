#/bin/bash

# make directories
rm -rf win32
mkdir win32
cd win32
mkdir bin
mkdir include
mkdir lib
cd ..
mkdir -p win32/lib/pkgconfig

# set build prefix
WORKDIR=$PWD
PREFIX=$PWD/win32
export PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig"


#---------------------------------


# start mbedTLS
read -n1 -r -p "Press any key to build mbedtls..." key

# download mbedTLS
curl --retry 5 -L -o mbedtls-2.23.0.tar.gz https://github.com/ARMmbed/mbedtls/archive/v2.23.0.tar.gz
tar -xf mbedtls-2.23.0.tar.gz
mv mbedtls-2.23.0 mbedtls

# build mbedTLS
# Enable the threading abstraction layer and use an alternate implementation
sed -i -e "s/\/\/#define MBEDTLS_THREADING_C/#define MBEDTLS_THREADING_C/" \
-e "s/\/\/#define MBEDTLS_THREADING_ALT/#define MBEDTLS_THREADING_ALT/" mbedtls/include/mbedtls/config.h
cp -p patch/mbedtls/threading_alt.h mbedtls/include/mbedtls/threading_alt.h

mkdir -p mbedtlsbuild/win32
cd mbedtlsbuild/win32
rm -rf *
cmake ../../mbedtls -DCMAKE_SYSTEM_NAME=Windows -DCMAKE_C_COMPILER=i686-w64-mingw32-gcc -DCMAKE_INSTALL_PREFIX=$PREFIX -DCMAKE_RC_COMPILER=i686-w64-mingw32-windres -DCMAKE_SHARED_LINKER_FLAGS="-static-libgcc -Wl,--strip-debug" -DUSE_SHARED_MBEDTLS_LIBRARY=ON -DUSE_STATIC_MBEDTLS_LIBRARY=OFF -DENABLE_PROGRAMS=OFF -DENABLE_TESTING=OFF
make -j$(nproc)
i686-w64-mingw32-dlltool -z mbedtls.orig.def --export-all-symbols library/libmbedtls.dll
i686-w64-mingw32-dlltool -z mbedcrypto.orig.def --export-all-symbols library/libmbedcrypto.dll
i686-w64-mingw32-dlltool -z mbedx509.orig.def --export-all-symbols library/libmbedx509.dll
grep "EXPORTS\|mbedtls" mbedtls.orig.def > mbedtls.def
grep "EXPORTS\|mbedtls" mbedcrypto.orig.def > mbedcrypto.def
grep "EXPORTS\|mbedtls" mbedx509.orig.def > mbedx509.def
sed -i -e "/\\t.*DATA/d" -e "/\\t\".*/d" -e "s/\s@.*//" mbedtls.def
sed -i -e "/\\t.*DATA/d" -e "/\\t\".*/d" -e "s/\s@.*//" mbedcrypto.def
sed -i -e "/\\t.*DATA/d" -e "/\\t\".*/d" -e "s/\s@.*//" mbedx509.def
i686-w64-mingw32-dlltool -m i386 -d mbedtls.def -l $PREFIX/bin/mbedtls.lib -D library/libmbedtls.dll
i686-w64-mingw32-dlltool -m i386 -d mbedcrypto.def -l $PREFIX/bin/mbedcrypto.lib -D library/libmbedcrypto.dll
i686-w64-mingw32-dlltool -m i386 -d mbedx509.def -l $PREFIX/bin/mbedx509.lib -D library/libmbedx509.dll
make install
cd ../..

mv $PREFIX/lib/*.dll $PREFIX/bin

# create pkgconfig files for mbedTLS
cat > $PKG_CONFIG_PATH/mbedtls.pc <<EOF
prefix=$PREFIX
exec_prefix=\${prefix}
libdir=\${exec_prefix}/lib
includedir=\${prefix}/include

Name: mbedtls
Description:
Version: 1.0.0
Requires:
Conflicts:
Libs: -L\${libdir} -lmbedtls
Cflags: -I\${includedir} -I\${includedir}/mbedtls
EOF

cat > $PKG_CONFIG_PATH/mbedcrypto.pc <<EOF
prefix=$PREFIX
exec_prefix=\${prefix}
libdir=\${exec_prefix}/lib
includedir=\${prefix}/include

Name: mbedcrypto
Description:
Version: 1.0.0
Requires:
Conflicts:
Libs: -L\${libdir} -lmbedcrypto
Cflags: -I\${includedir} -I\${includedir}/mbedtls
EOF

cat > $PKG_CONFIG_PATH/mbedx509.pc <<EOF
prefix=$PREFIX
exec_prefix=\${prefix}
libdir=\${exec_prefix}/lib
includedir=\${prefix}/include

Name: mbedx509
Description:
Version: 1.0.0
Requires:
Conflicts:
Libs: -L\${libdir} -lmbedx509
Cflags: -I\${includedir} -I\${includedir}/mbedtls
EOF


#---------------------------------


# pthread-win32
read -n1 -r -p "Press any key to build pthread-win32..." key

# download pthread-win32
curl --retry 5 -L -o pthread-win32-master.zip https://github.com/GerHobbelt/pthread-win32/archive/master.zip
unzip pthread-win32-master.zip
mv pthread-win32-master pthread-win32

# build pthread-win32
cd pthread-win32
make DESTROOT=$PREFIX CROSS=i686-w64-mingw32- realclean GC-small-static
cp libpthreadGC2.a $PREFIX/lib
cd ..


#---------------------------------


read -n1 -r -p "Press any key to build libsrt..." key

# download libsrt
curl --retry 5 -L -o srt-v1.4.1.tar.gz https://github.com/Haivision/srt/archive/v1.4.1.tar.gz
tar -xf srt-v1.4.1.tar.gz
mv srt-1.4.1 srt

# build libsrt
mkdir -p srtbuild/win32
cd srtbuild/win32
rm -rf *
cmake ../../srt -DCMAKE_SYSTEM_NAME=Windows -DCMAKE_C_COMPILER=i686-w64-mingw32-gcc -DCMAKE_CXX_COMPILER=i686-w64-mingw32-g++ -DCMAKE_INSTALL_PREFIX=$PREFIX -DCMAKE_RC_COMPILER=i686-w64-mingw32-windres -DUSE_ENCLIB=mbedtls -DENABLE_APPS=OFF -DENABLE_STATIC=OFF -DENABLE_SHARED=ON -DCMAKE_C_FLAGS="-I$WORKDIR/pthread-win32" -DCMAKE_CXX_FLAGS="-I$WORKDIR/pthread-win32" -DCMAKE_SHARED_LINKER_FLAGS="-static-libgcc -Wl,--strip-debug" -DPTHREAD_LIBRARY="$PREFIX/lib/libpthreadGC2.a" -DPTHREAD_INCLUDE_DIR="$WORKDIR/pthread-win32" -DUSE_OPENSSL_PC=OFF -DCMAKE_BUILD_TYPE=MinSizeRel
make -j$(nproc)
i686-w64-mingw32-strip -w --keep-symbol=srt* libsrt.dll
make install
cd ../..


#---------------------------------


# x264
read -n1 -r -p "Press any key to build x264..." key

# download and prep x264
git clone https://code.videolan.org/videolan/x264.git
cd x264
git checkout 72db437770fd1ce3961f624dd57a8e75ff65ae0b

# build x264
x264_api="$(grep '#define X264_BUILD' < x264.h | sed 's/^.* \([1-9][0-9]*\).*$/\1/')"
make clean
LDFLAGS="-static-libgcc" ./configure --enable-shared --disable-avs --disable-ffms --disable-gpac --disable-interlaced --disable-lavf --cross-prefix=i686-w64-mingw32- --host=i686-pc-mingw32 --prefix="$PREFIX"
make -j$(nproc)
make install
i686-w64-mingw32-dlltool -z $PREFIX/bin/x264.orig.def --export-all-symbols $PREFIX/bin/libx264-$x264_api.dll
grep "EXPORTS\|x264" $PREFIX/bin/x264.orig.def > $PREFIX/bin/x264.def
rm -f $PREFIX/bin/x264.orig.def
sed -i -e "/\\t.*DATA/d" -e "/\\t\".*/d" -e "s/\s@.*//" $PREFIX/bin/x264.def
i686-w64-mingw32-dlltool -m i386 -d $PREFIX/bin/x264.def -l $PREFIX/bin/x264.lib -D $PREFIX/bin/libx264-$x264_api.dll
cd ..


#---------------------------------


# opus
#read -n1 -r -p "Press any key to build opus..." key

# download opus
curl --retry 5 -L -O https://ftp.osuosl.org/pub/xiph/releases/opus/opus-1.3.1.tar.gz
tar -xf opus-1.3.1.tar.gz
mv opus-1.3.1 opus

# build opus
cd opus
make clean
LDFLAGS="-static-libgcc" ./configure --host=i686-w64-mingw32 --prefix="$PREFIX" --enable-shared
make -j$(nproc)
make install
cd ..


#---------------------------------


# zlib
#read -n1 -r -p "Press any key to build zlib..." key

# download zlib
curl --retry 5 -L -O https://www.zlib.net/zlib-1.2.11.tar.gz
tar -xf zlib-1.2.11.tar.gz
mv zlib-1.2.11 zlib

# patch CMakeLists.txt to remove the "lib" prefix when building shared libraries
cd zlib
patch -p1 < $WORKDIR/patch/zlib/zlib-disable-shared-lib-prefix.patch

# build zlib
mkdir build32
cd build32
make clean
cmake .. -DCMAKE_SYSTEM_NAME=Windows -DCMAKE_C_COMPILER=i686-w64-mingw32-gcc -DCMAKE_INSTALL_PREFIX=$PREFIX -DINSTALL_PKGCONFIG_DIR=$PREFIX/lib/pkgconfig -DCMAKE_RC_COMPILER=i686-w64-mingw32-windres -DCMAKE_SHARED_LINKER_FLAGS="-static-libgcc -Wl,--strip-debug"
make -j$(nproc)
make install
mv $PREFIX/lib/libzlib.dll.a $PREFIX/lib/libz.dll.a
mv $PREFIX/lib/libzlibstatic.a $PREFIX/lib/libz.a
cp ../win32/zlib.def $PREFIX/bin
i686-w64-mingw32-dlltool -m i386 -d ../win32/zlib.def -l $PREFIX/bin/zlib.lib -D $PREFIX/bin/zlib.dll
cd ../..

# patch include/zconf.h
cd $PREFIX
patch -p1 < $WORKDIR/patch/zlib/zlib-include-zconf.patch
cd $WORKDIR


#---------------------------------


# libpng
#read -n1 -r -p "Press any key to build libpng..." key

# download libpng
curl --retry 5 -L -o libpng-1.6.37.tar.gz https://github.com/glennrp/libpng/archive/v1.6.37.tar.gz
tar -xf libpng-1.6.37.tar.gz
mv libpng-1.6.37 libpng

# build libpng
cd libpng
make clean
PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig" LDFLAGS="-L$PREFIX/lib -static-libgcc" CPPFLAGS="-I$PREFIX/include" ./configure --host=i686-w64-mingw32 --prefix="$PREFIX" --enable-shared
make -j$(nproc)
make install
cd ..


#---------------------------------


# libogg
#read -n1 -r -p "Press any key to build libogg..." key

# download libogg
curl --retry 5 -L -o ogg-68ca3841567247ac1f7850801a164f58738d8df9.tar.gz https://gitlab.xiph.org/xiph/ogg/-/archive/68ca3841567247ac1f7850801a164f58738d8df9/ogg-68ca3841567247ac1f7850801a164f58738d8df9.tar.gz
tar -xf ogg-68ca3841567247ac1f7850801a164f58738d8df9.tar.gz
mv ogg-68ca3841567247ac1f7850801a164f58738d8df9 libogg

# build libogg
cd libogg
mkdir build32
./autogen.sh
cd build32
make clean
PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig" LDFLAGS="-L$PREFIX/lib -static-libgcc" CPPFLAGS="-I$PREFIX/include" ../configure --host=i686-w64-mingw32 --prefix="$PREFIX" --enable-shared
make -j$(nproc)
make install
cd ../..


#---------------------------------


# libvorbis
#read -n1 -r -p "Press any key to build libvorbis..." key

# download libvorbis
curl --retry 5 -L -O https://ftp.osuosl.org/pub/xiph/releases/vorbis/libvorbis-1.3.6.tar.gz
tar -xf libvorbis-1.3.6.tar.gz
mv libvorbis-1.3.6 libvorbis

# build libvorbis
cd libvorbis
make clean
PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig" LDFLAGS="-L$PREFIX/lib -static-libgcc" CPPFLAGS="-I$PREFIX/include" ./configure --host=i686-w64-mingw32 --prefix="$PREFIX" --enable-shared --with-ogg="$PREFIX"
make -j$(nproc)
make install
cd ..


#---------------------------------


# libvpx
#read -n1 -r -p "Press any key to build libvpx..." key

# download libvpx
curl --retry 5 -L -o libvpx-v1.8.1.tar.gz https://chromium.googlesource.com/webm/libvpx/+archive/v1.8.1.tar.gz
mkdir -p libvpx
tar -xf libvpx-v1.8.1.tar.gz -C $PWD/libvpx

# build libvpx
cd libvpx
patch -p1 < ../patch/libvpx/libvpx-crosscompile-win-dll.patch
cd ..
mkdir -p libvpxbuild
cd libvpxbuild
make clean
PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig" CROSS=i686-w64-mingw32- LDFLAGS="-static-libgcc" ../libvpx/configure --prefix=$PREFIX --enable-vp8 --enable-vp9 --disable-docs --disable-examples --enable-shared --disable-static --enable-runtime-cpu-detect --enable-realtime-only --disable-install-bins --disable-install-docs --disable-unit-tests --target=x86-win32-gcc
make -j$(nproc)
make install
i686-w64-mingw32-dlltool -m i386 -d libvpx.def -l $PREFIX/bin/vpx.lib -D /home/jim/win32/packages/bin/libvpx-1.dll
cd ..

pkg-config --libs vpx


#---------------------------------


read -n1 -r -p "Press any key to build FFmpeg..." key

cd nv-codec-headers
make PREFIX="$PREFIX"
make PREFIX="$PREFIX" install
cd ..

mkdir $PREFIX/include/AMF
cp -a AMF/amf/public/include/* $PREFIX/include/AMF

cd ffmpeg
make clean
PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig" LDFLAGS="-L$PREFIX/lib -static-libgcc" CFLAGS="-I$PREFIX/include -I$WORKDIR/pthread-win32" ./configure --enable-gpl --disable-programs --disable-doc --arch=x86 --enable-shared --enable-nvenc --enable-amf --enable-libx264 --enable-libopus --enable-libvorbis --enable-libvpx --enable-libsrt --disable-debug --cross-prefix=i686-w64-mingw32- --target-os=mingw32 --pkg-config=pkg-config --prefix="$PREFIX" --disable-postproc
read -n1 -r -p "Press any key to continue building FFmpeg..." key
make -j$(nproc)
make install
cd ..
