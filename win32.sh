#/bin/bash

rm -rf win32
mkdir win32
cd win32
mkdir bin
mkdir include
mkdir lib
cd ..

read -n1 -r -p "Press any key to build mbedtls.." key

mkdir mbedtlsbuild
mkdir mbedtlsbuild/win32
cd mbedtlsbuild/win32
rm -rf *
cmake ../../mbedtls -DCMAKE_SYSTEM_NAME=Windows -DCMAKE_C_COMPILER=i686-w64-mingw32-gcc -DCMAKE_INSTALL_PREFIX=/home/jim/packages/win32 -DCMAKE_RC_COMPILER=i686-w64-mingw32-windres -DCMAKE_SHARED_LINKER_FLAGS="-static-libgcc -Wl,--strip-debug" -DUSE_SHARED_MBEDTLS_LIBRARY=ON -DUSE_STATIC_MBEDTLS_LIBRARY=OFF -DENABLE_PROGRAMS=OFF -DENABLE_TESTING=OFF
make -j6
i686-w64-mingw32-dlltool -z mbedtls.orig.def --export-all-symbols library/libmbedtls.dll
i686-w64-mingw32-dlltool -z mbedcrypto.orig.def --export-all-symbols library/libmbedcrypto.dll
i686-w64-mingw32-dlltool -z mbedx509.orig.def --export-all-symbols library/libmbedx509.dll
grep "EXPORTS\|mbedtls" mbedtls.orig.def > mbedtls.def
grep "EXPORTS\|mbedtls" mbedcrypto.orig.def > mbedcrypto.def
grep "EXPORTS\|mbedtls" mbedx509.orig.def > mbedx509.def
sed -i -e "/\\t.*DATA/d" -e "/\\t\".*/d" -e "s/\s@.*//" mbedtls.def
sed -i -e "/\\t.*DATA/d" -e "/\\t\".*/d" -e "s/\s@.*//" mbedcrypto.def
sed -i -e "/\\t.*DATA/d" -e "/\\t\".*/d" -e "s/\s@.*//" mbedx509.def
i686-w64-mingw32-dlltool -m i386 -d mbedtls.def -l /home/jim/packages/win32/bin/mbedtls.lib -D library/libmbedtls.dll
i686-w64-mingw32-dlltool -m i386 -d mbedcrypto.def -l /home/jim/packages/win32/bin/mbedcrypto.lib -D library/libmbedcrypto.dll
i686-w64-mingw32-dlltool -m i386 -d mbedx509.def -l /home/jim/packages/win32/bin/mbedx509.lib -D library/libmbedx509.dll
make install
cd ../..

mv win32/lib/*.dll win32/bin
mkdir win32/lib/pkgconfig

#---------------------------------

cat > win32/lib/pkgconfig/mbedtls.pc <<EOF
prefix=/home/jim/packages/win32
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

#---------------------------------

cat > win32/lib/pkgconfig/mbedcrypto.pc <<EOF
prefix=/home/jim/packages/win32
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

#---------------------------------

cat > win32/lib/pkgconfig/mbedx509.pc <<EOF
prefix=/home/jim/packages/win32
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

read -n1 -r -p "Press any key to build pthread-win32.." key

cd pthread-win32
make DESTROOT=/home/jim/packages/win32 CROSS=i686-w64-mingw32- realclean GC-small-static
cp libpthreadGC2.a /home/jim/packages/win32/lib
cd ..

read -n1 -r -p "Press any key to build libsrt.." key

mkdir srtbuild
mkdir srtbuild/win32
cd srtbuild/win32
rm -rf *
cmake ../../srt -DCMAKE_SYSTEM_NAME=Windows -DCMAKE_C_COMPILER=i686-w64-mingw32-gcc -DCMAKE_INSTALL_PREFIX=/home/jim/packages/win32 -DCMAKE_RC_COMPILER=i686-w64-mingw32-windres -DUSE_ENCLIB=mbedtls -DENABLE_APPS=OFF -DENABLE_STATIC=OFF -DENABLE_SHARED=ON -DCMAKE_C_FLAGS="-I/home/jim/packages/pthread-win32" -DCMAKE_CXX_FLAGS="-I/home/jim/packages/pthread-win32" -DCMAKE_SHARED_LINKER_FLAGS="-static-libgcc -Wl,--strip-debug" -DPTHREAD_LIBRARY="/home/jim/packages/win32/lib/libpthreadGC2.a" -DPTHREAD_INCLUDE_DIR="/home/jim/packages/pthread-win32" -DUSE_OPENSSL_PC=OFF -DCMAKE_BUILD_TYPE=MinSizeRel
make -j6
i686-w64-mingw32-strip -w --keep-symbol=srt* libsrt.dll
make install
cd ../..

read -n1 -r -p "Press any key to build x264..." key

cd x264
make clean
LDFLAGS="-static-libgcc" ./configure --enable-shared --disable-avs --disable-ffms --disable-gpac --disable-interlaced --disable-lavf --cross-prefix=i686-w64-mingw32- --host=i686-pc-mingw32 --prefix="/home/jim/packages/win32"
make -j6
make install
i686-w64-mingw32-dlltool -z /home/jim/packages/win32/bin/x264.orig.def --export-all-symbols /home/jim/packages/win32/bin/libx264-157.dll
grep "EXPORTS\|x264" /home/jim/packages/win32/bin/x264.orig.def > /home/jim/packages/win32/bin/x264.def
rm -f /home/jim/packages/win32/bin/x264.org.def
sed -i -e "/\\t.*DATA/d" -e "/\\t\".*/d" -e "s/\s@.*//" /home/jim/packages/win32/bin/x264.def
i686-w64-mingw32-dlltool -m i386 -d /home/jim/packages/win32/bin/x264.def -l /home/jim/packages/win32/bin/x264.lib -D /home/jim/win32/packages/bin/libx264-157.dll
cd ..

#read -n1 -r -p "Press any key to build opus..." key

cd opus
make clean
LDFLAGS="-static-libgcc" ./configure -host=i686-w64-mingw32 --prefix="/home/jim/packages/win32" --enable-shared
make -j6
make install
cd ..

#read -n1 -r -p "Press any key to build zlib..." key

cd zlib/build32
make clean
cmake .. -DCMAKE_SYSTEM_NAME=Windows -DCMAKE_C_COMPILER=i686-w64-mingw32-gcc -DCMAKE_INSTALL_PREFIX=/home/jim/packages/win32 -DINSTALL_PKGCONFIG_DIR=/home/jim/packages/win32/lib/pkgconfig -DCMAKE_RC_COMPILER=i686-w64-mingw32-windres -DCMAKE_SHARED_LINKER_FLAGS="-static-libgcc -Wl,--strip-debug"
make -j6
make install
mv ../../win32/lib/libzlib.dll.a ../../win32/lib/libz.dll.a
mv ../../win32/lib/libzlibstatic.a ../../win32/lib/libz.a
cp ../win32/zlib.def /home/jim/packages/win32/bin
i686-w64-mingw32-dlltool -m i386 -d ../win32/zlib.def -l /home/jim/packages/win32/bin/zlib.lib -D /home/jim/win32/packages/bin/zlib.dll
cd ../..

#read -n1 -r -p "Press any key to build libpng..." key

cd libpng
make clean
PKG_CONFIG_PATH="/home/jim/packages/win32/lib/pkgconfig" LDFLAGS="-L/home/jim/packages/win32/lib -static-libgcc" CPPFLAGS="-I/home/jim/packages/win32/include" ./configure -host=i686-w64-mingw32 --prefix="/home/jim/packages/win32" --enable-shared
make -j6
make install
cd ..

#read -n1 -r -p "Press any key to build libogg..." key

cd libogg
make clean
PKG_CONFIG_PATH="/home/jim/packages/win32/lib/pkgconfig" LDFLAGS="-L/home/jim/packages/win32/lib -static-libgcc" CPPFLAGS="-I/home/jim/packages/win32/include" ./configure -host=i686-w64-mingw32 --prefix="/home/jim/packages/win32" --enable-shared
make -j6
make install
cd ..

#read -n1 -r -p "Press any key to build libvorbis..." key

cd libvorbis
make clean
PKG_CONFIG_PATH="/home/jim/packages/win32/lib/pkgconfig" LDFLAGS="-L/home/jim/packages/win32/lib -static-libgcc" CPPFLAGS="-I/home/jim/packages/win32/include" ./configure -host=i686-w64-mingw32 --prefix="/home/jim/packages/win32" --enable-shared --with-ogg="/home/jim/packages/win32"
make -j6
make install
cd ..

#read -n1 -r -p "Press any key to build libvpx..." key

cd libvpxbuild
make clean
PKG_CONFIG_PATH="/home/jim/packages/win32/lib/pkgconfig" CROSS=i686-w64-mingw32- LDFLAGS="-static-libgcc" ../libvpx/configure --prefix=/home/jim/packages/win32 --enable-vp8 --enable-vp9 --disable-docs --disable-examples --enable-shared --disable-static --enable-runtime-cpu-detect --enable-realtime-only --disable-install-bins --disable-install-docs --disable-unit-tests --target=x86-win32-gcc
make -j6
make install
i686-w64-mingw32-dlltool -m i386 -d libvpx.def -l /home/jim/packages/win32/bin/vpx.lib -D /home/jim/win32/packages/bin/libvpx-1.dll
cd ..

read -n1 -r -p "Press any key to build FFmpeg..." key

cd nv-codec-headers
make PREFIX="/home/jim/packages/win32"
make PREFIX="/home/jim/packages/win32" install
cd ..

mkdir win32/include/AMF
cp -a AMF/amf/public/include/* /home/jim/packages/win32/include/AMF

cd ffmpeg
make clean
PKG_CONFIG_PATH="/home/jim/packages/win32/lib/pkgconfig" LDFLAGS="-L/home/jim/packages/win32/lib -static-libgcc" CFLAGS="-I/home/jim/packages/win32/include -I/home/jim/packages/pthread-win32" ./configure --enable-gpl --disable-programs --disable-doc --arch=x86 --enable-shared --enable-nvenc --enable-amf --enable-libx264 --enable-libopus --enable-libvorbis --enable-libvpx --enable-libsrt --disable-debug --cross-prefix=i686-w64-mingw32- --target-os=mingw32 --pkg-config=pkg-config --prefix="/home/jim/packages/win32" --disable-postproc
read -n1 -r -p "Press any key to continue building FFmpeg..." key
make -j6
make install
cd ..
