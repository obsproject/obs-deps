#/bin/bash

# exit when any command fails
set -e

mkdir buildprefix
mkdir buildprefix/pkgconfig

PREFIX=$PWD/buildprefix

export PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig"

git clone git://git.videolan.org/x264.git
cd x264
LDFLAGS="-static-libgcc" ./configure --enable-static --enable-shared --enable-win32thread --disable-avs \
	--disable-ffms --disable-gpac --disable-interlaced --disable-lavf --cross-prefix=x86_64-w64-mingw32- \
	--host=x86_64-pc-mingw32 --prefix="$PREFIX"
make -j
make install
x86_64-w64-mingw32-dlltool -z $PREFIX/bin/x264.orig.def --export-all-symbols $PREFIX/bin/libx264-157.dll
grep "EXPORTS\|x264" $PREFIX/bin/x264.orig.def >$PREFIX/bin/x264.def
rm -f $PREFIX/bin/x264.org.def
sed -i -e "/\\t.*DATA/d" -e "/\\t\".*/d" -e "s/\s@.*//" $PREFIX/bin/x264.def
x86_64-w64-mingw32-dlltool -m i386:x86-64 -d $PREFIX/bin/x264.def -l $PREFIX/bin/x264.lib -D $PREFIX/libx264-157.dll
cd ..

curl -L -O https://ftp.osuosl.org/pub/xiph/releases/opus/opus-1.2.1.tar.gz
tar -xf opus-1.2.1.tar.gz
cd ./opus-1.2.1
LDFLAGS="-static-libgcc" ./configure -host=x86_64-w64-mingw32 --prefix="$PREFIX" --enable-shared
make -j6
make install
cd ..

curl -L -O https://www.zlib.net/zlib-1.2.11.tar.gz
tar -xf zlib-1.2.11.tar.gz
cd ./zlib-1.2.11
mkdir build
cd ./build
cmake .. -DCMAKE_SYSTEM_NAME=Windows -DCMAKE_C_COMPILER=x86_64-w64-mingw32-gcc -DCMAKE_INSTALL_PREFIX=$PREFIX \
	-DCMAKE_RC_COMPILER=x86_64-w64-mingw32-windres -DCMAKE_SHARED_LINKER_FLAGS="-static-libgcc"
make -j6
make install
mv $PREFIX/lib/libzlib.dll.a $PREFIX/lib/libz.dll.a
mv $PREFIX/lib/libzlibstatic.a $PREFIX/lib/libz.a
#cp $PREFIX/zlib.def $PREFIX/bin
x86_64-w64-mingw32-dlltool -m i386:x86-64 -d ../win32/zlib.def -l $PREFIX/bin/zlib.lib -D $PREFIX/bin/zlib.dll
cd ../..

wget http://curl.haxx.se/download/curl-7.65.3.tar.gz
tar xzf curl-7.65.3.tar.gz
cd curl-7.65.3/
PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig" ./configure --prefix="$PREFIX" -host=x86_64-w64-mingw32
make
make install
cd ..

tar -xf libpng-1.6.37.tar.gz
cd ./libpng-1.6.37
PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig" LDFLAGS="-L$PREFIX/lib" CPPFLAGS="-I$PREFIX/include" \
	./configure -host=x86_64-w64-mingw32 --prefix="$PREFIX" --enable-shared
make -j6
make install
cd ..

curl -L -O https://ftp.osuosl.org/pub/xiph/releases/ogg/libogg-1.3.3.tar.gz
tar -xf libogg-1.3.3.tar.gz
cd ./libogg-1.3.3
PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig" LDFLAGS="-L$PREFIX/lib -static-libgcc" \
	CPPFLAGS="-I$PREFIX/include" ./configure -host=x86_64-w64-mingw32 --prefix="$PREFIX" --enable-shared --enable-static
make -j6
make install
cd ..

curl -L -O https://ftp.osuosl.org/pub/xiph/releases/vorbis/libvorbis-1.3.6.tar.gz
tar -xf libvorbis-1.3.6.tar.gz
cd ./libvorbis-1.3.6
PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig" LDFLAGS="-L$PREFIX/lib -static-libgcc" CPPFLAGS="-I$PREFIX/include" ./configure -host=x86_64-w64-mingw32 \
	--prefix="$PREFIX" --enable-shared --enable-static --with-ogg="$PREFIX"
make -j6
make install
cd ..

curl -L -O https://chromium.googlesource.com/webm/libvpx/+archive/v1.7.0.tar.gz
mkdir -p ./libvpx-v1.7.0
tar -xf v1.7.0.tar.gz -C $PWD/libvpx-v1.7.0
cd ./libvpx-v1.7.0
mkdir vpxbuild
cd ./vpxbuild
PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig" CROSS=x86_64-w64-mingw32- LDFLAGS="-static-libgcc" \
	../configure --prefix=$PREFIX --enable-vp8 --enable-vp9 \
	--disable-examples --enable-runtime-cpu-detect --enable-realtime-only \
	--disable-install-docs --disable-unit-tests --target=x86_64-win64-gcc
make -j6
make install
make libvpx.def
x86_64-w64-mingw32-dlltool -m i386:x86-64 -d libvpx.def -l $PREFIX/bin/vpx.lib -D $PREFIX/bin/libvpx-1.dll
cd ../../

PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig" pkg-config --libs vpx

git clone https://git.videolan.org/git/ffmpeg/nv-codec-headers.git
cd nv-codec-headers
make
sudo make install PREFIX=$PREFIX
cd ..

curl -L -O https://github.com/FFmpeg/FFmpeg/archive/n4.1.4.zip
unzip ./n4.1.4.zip
cp ./nvidia/nvEncodeAPI.h $PREFIX/include
cd ./FFmpeg-n4.1.4
PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig" LDFLAGS="-L$PREFIX/lib" CPPFLAGS="-I$PREFIX/include" \
	./configure --enable-gpl --disable-doc --arch=x86_64 --enable-shared --enable-nvenc --enable-libx264 --enable-libopus \
	--enable-libvorbis --enable-libvpx --disable-debug --cross-prefix=x86_64-w64-mingw32- --target-os=mingw32 --pkg-config=pkg-config \
	--disable-w32threads \
	--prefix="$PREFIX" --disable-postproc --extra-ldlibflags="-static -pthread" --pkg-config-flags="--static" 
make -j6
make install
cd ..
