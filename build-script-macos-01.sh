#!/usr/bin/env bash

set -eE

PRODUCT_NAME="OBS Pre-Built Dependencies"

COLOR_RED=$(tput setaf 1)
COLOR_GREEN=$(tput setaf 2)
COLOR_BLUE=$(tput setaf 4)
COLOR_ORANGE=$(tput setaf 3)
COLOR_RESET=$(tput sgr0)

export MAC_QT_VERSION="5.14.1"
export WIN_QT_VERSION="5.10"
export LIBPNG_VERSION="1.6.37"
export LIBOPUS_VERSION="1.3.1"
export LIBOGG_VERSION="68ca3841567247ac1f7850801a164f58738d8df9"
export LIBVORBIS_VERSION="1.3.6"
export LIBVPX_VERSION="1.8.2"
export LIBJANSSON_VERSION="2.12"
export LIBX264_VERSION="origin/stable"
export LIBMBEDTLS_VERSION="2.16.5"
export LIBSRT_VERSION="1.4.1"
export FFMPEG_VERSION="4.2.2"
export LIBLUAJIT_VERSION="2.1.0-beta3"
export LIBFREETYPE_VERSION="2.10.1"
export SWIG_VERSION="3.0.12"
export MACOSX_DEPLOYMENT_TARGET="10.13"
export PATH="/usr/local/opt/ccache/libexec:${PATH}"
export CURRENT_DATE="$(date +"%Y-%m-%d")"
export PKG_CONFIG_PATH="$PKG_CONFIG_PATH:/tmp/obsdeps/lib/pkgconfig"
export PARALLELISM="$(sysctl -n hw.ncpu)"

hr() {
     echo -e "${COLOR_BLUE}[${PRODUCT_NAME}] ${1}${COLOR_RESET}"
}

step() {
    echo -e "${COLOR_GREEN}  + ${1}${COLOR_RESET}"
}

info() {
    echo -e "${COLOR_ORANGE}  + ${1}${COLOR_RESET}"
}

error() {
     echo -e "${COLOR_RED}  + ${1}${COLOR_RESET}"
}

exists() {
    command -v "${1}" >/dev/null 2>&1
}

ensure_dir() {
    [[ -n ${1} ]] && /bin/mkdir -p ${1} && builtin cd ${1}
}

cleanup() {
    :
}

mkdir() {
    /bin/mkdir -p $*
}

trap cleanup EXIT

caught_error() {
    error "ERROR during build step: ${1}"
    cleanup $/home/runner/work/obs-deps/obs-deps
    exit 1
}

build_47cd2282-8965-4b61-ab28-62fec66c2cb4() {
    step "Install Homebrew dependencies"
    trap "caught_error 'Install Homebrew dependencies'" ERR
    ensure_dir /home/runner/work/obs-deps/obs-deps

    brew bundle
}


build_4a472a79-6484-4b41-b403-734d35e18080() {
    step "Get Current Date"
    trap "caught_error 'Get Current Date'" ERR
    ensure_dir /home/runner/work/obs-deps/obs-deps


}


build_9daf28d2-6c93-4c31-a049-0588be784b54() {
    step "Build environment setup"
    trap "caught_error 'Build environment setup'" ERR
    ensure_dir /home/runner/work/obs-deps/obs-deps

    mkdir -p CI_BUILD/obsdeps/bin
    mkdir -p CI_BUILD/obsdeps/include
    mkdir -p CI_BUILD/obsdeps/lib
    mkdir -p CI_BUILD/obsdeps/share
    
    
}


build_2f0aa16d-f472-4ada-a7d9-8c50c8840ec9() {
    step "Build dependency swig"
    trap "caught_error 'Build dependency swig'" ERR
    ensure_dir /home/runner/work/obs-deps/obs-deps/CI_BUILD

    curl --retry 5 -L -O "https://downloads.sourceforge.net/project/swig/swig/swig-${SWIG_VERSION}/swig-${SWIG_VERSION}.tar.gz"
    tar -xf swig-${SWIG_VERSION}.tar.gz
    cd swig-${SWIG_VERSION}
    mkdir build
    cd build
    ../configure --disable-dependency-tracking --prefix="/tmp/obsdeps"
    make -j${PARALLELISM}
}


build_6cce7e1e-2351-4da7-813c-16c7d65ffe89() {
    step "Install dependency swig"
    trap "caught_error 'Install dependency swig'" ERR
    ensure_dir /home/runner/work/obs-deps/obs-deps/CI_BUILD/swig-3.0.12/build

    cp swig /home/runner/work/obs-deps/obs-deps/CI_BUILD/obsdeps/bin/
    mkdir -p /home/runner/work/obs-deps/obs-deps/CI_BUILD/obsdeps/share/swig/${SWIG_VERSION}
    rsync -avh --include="*.i" --include="*.swg" --include="python" --include="lua" --include="typemaps" --exclude="*" ../Lib/* /home/runner/work/obs-deps/obs-deps/CI_BUILD/obsdeps/share/swig/${SWIG_VERSION}
}


build_7870c90a-edb7-4670-b79f-377202ce0a89() {
    step "Build dependency libpng"
    trap "caught_error 'Build dependency libpng'" ERR
    ensure_dir /home/runner/work/obs-deps/obs-deps/CI_BUILD

    curl --retry 5 -L -O "https://downloads.sourceforge.net/project/libpng/libpng16/${LIBPNG_VERSION}/libpng-${LIBPNG_VERSION}.tar.xz"
    tar -xf libpng-${LIBPNG_VERSION}.tar.xz
    cd libpng-${LIBPNG_VERSION}
    mkdir build
    cd build
    ../configure --enable-static --disable-shared --prefix="/tmp/obsdeps"
    make -j${PARALLELISM}
}


build_17d343fe-15d1-4fcd-a41d-2b8b35ab7305() {
    step "Install dependency libpng"
    trap "caught_error 'Install dependency libpng'" ERR
    ensure_dir /home/runner/work/obs-deps/obs-deps/CI_BUILD/libpng-1.6.37/build

    make install
}


build_b02ec058-c61d-4670-a0ad-0e55b317f8fd() {
    step "Build dependency libopus"
    trap "caught_error 'Build dependency libopus'" ERR
    ensure_dir /home/runner/work/obs-deps/obs-deps/CI_BUILD

    curl --retry 5 -L -C - -O "https://ftp.osuosl.org/pub/xiph/releases/opus/opus-${LIBOPUS_VERSION}.tar.gz"
    tar -xf opus-${LIBOPUS_VERSION}.tar.gz
    cd ./opus-${LIBOPUS_VERSION}
    mkdir build
    cd ./build
    ../configure --disable-shared --enable-static --prefix="/tmp/obsdeps"
    make -j${PARALLELISM}
}


build_45dd03a7-e455-4d23-a31c-8b9054b75b6c() {
    step "Install dependency libopus"
    trap "caught_error 'Install dependency libopus'" ERR
    ensure_dir /home/runner/work/obs-deps/obs-deps/CI_BUILD/opus-1.3.1/build

    make install
}


build_546a5d90-1b4f-47e4-b359-50a2ea10c191() {
    step "Build dependency libogg"
    trap "caught_error 'Build dependency libogg'" ERR
    ensure_dir /home/runner/work/obs-deps/obs-deps/CI_BUILD

    curl --retry 5 -L -O https://gitlab.xiph.org/xiph/ogg/-/archive/${LIBOGG_VERSION}/ogg-${LIBOGG_VERSION}.tar.gz
    tar -xf ogg-${LIBOGG_VERSION}.tar.gz
    cd ./ogg-${LIBOGG_VERSION}
    mkdir build
    ./autogen.sh
    cd ./build
    ../configure --disable-shared --enable-static --prefix="/tmp/obsdeps"
    make -j${PARALLELISM}
}


build_c6086b77-5e5e-4f3e-8799-294185078080() {
    step "Install dependency libogg"
    trap "caught_error 'Install dependency libogg'" ERR
    ensure_dir /home/runner/work/obs-deps/obs-deps/CI_BUILD/ogg-68ca3841567247ac1f7850801a164f58738d8df9/build

    make install
}


build_7f599a16-96d4-426e-a72a-23d19d23a592() {
    step "Build dependency libvorbis"
    trap "caught_error 'Build dependency libvorbis'" ERR
    ensure_dir /home/runner/work/obs-deps/obs-deps/CI_BUILD

    curl --retry 5 -L -C - -O "https://ftp.osuosl.org/pub/xiph/releases/vorbis/libvorbis-${LIBVORBIS_VERSION}.tar.gz"
    tar -xf libvorbis-${LIBVORBIS_VERSION}.tar.gz
    cd ./libvorbis-${LIBVORBIS_VERSION}
    mkdir build
    cd ./build
    ../configure --disable-shared --enable-static --prefix="/tmp/obsdeps"
    make -j${PARALLELISM}
}


build_d9ea00d0-7d17-4448-8bfe-22008a0b5f1d() {
    step "Install dependency libvorbis"
    trap "caught_error 'Install dependency libvorbis'" ERR
    ensure_dir /home/runner/work/obs-deps/obs-deps/CI_BUILD/libvorbis-1.3.6/build

    make install
}


build_66f24758-7e0f-4987-8ad8-d667187700cc() {
    step "Build dependency libvpx"
    trap "caught_error 'Build dependency libvpx'" ERR
    ensure_dir /home/runner/work/obs-deps/obs-deps/CI_BUILD

    curl --retry 5 -L -O "https://chromium.googlesource.com/webm/libvpx/+archive/v${LIBVPX_VERSION}.tar.gz"
    mkdir -p ./libvpx-v${LIBVPX_VERSION}
    tar -xf v${LIBVPX_VERSION}.tar.gz -C $PWD/libvpx-v${LIBVPX_VERSION}
    cd ./libvpx-v${LIBVPX_VERSION}
    mkdir -p build
    cd ./build
    ../configure --disable-shared --prefix="/tmp/obsdeps" --libdir="/tmp/obsdeps/lib"
    make -j${PARALLELISM}
}


build_8395dc25-155f-4048-94cc-52bd98d5f418() {
    step "Install dependency libvpx"
    trap "caught_error 'Install dependency libvpx'" ERR
    ensure_dir /home/runner/work/obs-deps/obs-deps/CI_BUILD/libvpx-v1.8.2/build

    make install
}


build_e36fba56-e72e-4237-98be-9325773282bb() {
    step "Build dependency libjansson"
    trap "caught_error 'Build dependency libjansson'" ERR
    ensure_dir /home/runner/work/obs-deps/obs-deps/CI_BUILD

    curl --retry 5 -L -C - -O http://www.digip.org/jansson/releases/jansson-${LIBJANSSON_VERSION}.tar.gz
    tar -xf jansson-${LIBJANSSON_VERSION}.tar.gz
    cd jansson-${LIBJANSSON_VERSION}
    mkdir build
    cd ./build
    ../configure --libdir="/tmp/obsdeps/bin" --enable-shared --disable-static
    make -j${PARALLELISM}
}


build_789673d5-6cb2-4f88-b1a1-adeb8f264dc9() {
    step "Install dependency libjansson"
    trap "caught_error 'Install dependency libjansson'" ERR
    ensure_dir /home/runner/work/obs-deps/obs-deps/CI_BUILD/jansson-2.12/build

    find . -name \*.dylib -exec cp -PR \{\} /home/runner/work/obs-deps/obs-deps/CI_BUILD/obsdeps/bin/ \;
    rsync -avh --include="*/" --include="*.h" --exclude="*" ../src/* /home/runner/work/obs-deps/obs-deps/CI_BUILD/obsdeps/include/
    rsync -avh --include="*/" --include="*.h" --exclude="*" ./src/* /home/runner/work/obs-deps/obs-deps/CI_BUILD/obsdeps/include/
    cp ./*.h /home/runner/work/obs-deps/obs-deps/CI_BUILD/obsdeps/include/
}


build_d3cd16bd-9ff2-4c55-bfbc-a36278bfeaff() {
    step "Build dependency libx264"
    trap "caught_error 'Build dependency libx264'" ERR
    ensure_dir /home/runner/work/obs-deps/obs-deps/CI_BUILD

    if [ ! -d ./x264 ]; then git clone https://code.videolan.org/videolan/x264.git; fi
    cd ./x264
    git checkout ${LIBX264_VERSION}
    mkdir build
    cd ./build
    ../configure --extra-ldflags="-mmacosx-version-min=${MACOSX_DEPLOYMENT_TARGET}" --enable-static --prefix="/tmp/obsdeps"
    make -j${PARALLELISM}
}


build_36dfe32d-2255-4a3d-873a-daaa29b198e9() {
    step "Install dependency libx264"
    trap "caught_error 'Install dependency libx264'" ERR
    ensure_dir /home/runner/work/obs-deps/obs-deps/CI_BUILD/x264/build

    make install
}


build_304b4465-63e3-4413-9365-e21a4e025170() {
    step "Build dependency libx264 (dylib)"
    trap "caught_error 'Build dependency libx264 (dylib)'" ERR
    ensure_dir /home/runner/work/obs-deps/obs-deps/CI_BUILD/x264/build

    ../configure --extra-ldflags="-mmacosx-version-min=${MACOSX_DEPLOYMENT_TARGET}" --enable-shared --libdir="/tmp/obsdeps/bin" --prefix="/tmp/obsdeps"
    make -j${PARALLELISM}
}


build_14a337ca-49c7-47bc-bed9-3c03d1607fd0() {
    step "Install dependency libx264 (dylib)"
    trap "caught_error 'Install dependency libx264 (dylib)'" ERR
    ensure_dir /home/runner/work/obs-deps/obs-deps/CI_BUILD/x264/build

    ln -f -s libx264.*.dylib libx264.dylib
    find . -name \*.dylib -exec cp -PR \{\} /home/runner/work/obs-deps/obs-deps/CI_BUILD/obsdeps/bin/ \;
    rsync -avh --include="*/" --include="*.h" --exclude="*" ../* /home/runner/work/obs-deps/obs-deps/CI_BUILD/obsdeps/include/
    rsync -avh --include="*/" --include="*.h" --exclude="*" ./* /home/runner/work/obs-deps/obs-deps/CI_BUILD/obsdeps/include/
}


build_ed02c88a-2cc9-48ab-83a8-d8634dbcdb46() {
    step "Build dependency libmbedtls"
    trap "caught_error 'Build dependency libmbedtls'" ERR
    ensure_dir /home/runner/work/obs-deps/obs-deps/CI_BUILD

    curl --retry 5 -L -C - -O https://tls.mbed.org/download/mbedtls-${LIBMBEDTLS_VERSION}-gpl.tgz
    tar -xf mbedtls-${LIBMBEDTLS_VERSION}-gpl.tgz
    cd mbedtls-${LIBMBEDTLS_VERSION}
    sed -i '.orig' 's/\/\/\#define MBEDTLS_THREADING_PTHREAD/\#define MBEDTLS_THREADING_PTHREAD/g' include/mbedtls/config.h
    sed -i '.orig' 's/\/\/\#define MBEDTLS_THREADING_C/\#define MBEDTLS_THREADING_C/g' include/mbedtls/config.h
    mkdir build
    cd ./build
    cmake -DCMAKE_INSTALL_PREFIX="/tmp/obsdeps" -DUSE_SHARED_MBEDTLS_LIBRARY=ON -DENABLE_PROGRAMS=OFF ..
    make -j${PARALLELISM}
}


build_2802676a-13c9-457d-bf32-41548f8693a6() {
    step "Install dependency libmbedtls"
    trap "caught_error 'Install dependency libmbedtls'" ERR
    ensure_dir /home/runner/work/obs-deps/obs-deps/CI_BUILD/mbedtls-2.16.5/build

    make install
    install_name_tool -id /tmp/obsdeps/lib/libmbedtls.${LIBMBEDTLS_VERSION}.dylib /tmp/obsdeps/lib/libmbedtls.${LIBMBEDTLS_VERSION}.dylib
    install_name_tool -id /tmp/obsdeps/lib/libmbedcrypto.${LIBMBEDTLS_VERSION}.dylib /tmp/obsdeps/lib/libmbedcrypto.${LIBMBEDTLS_VERSION}.dylib
    install_name_tool -id /tmp/obsdeps/lib/libmbedx509.${LIBMBEDTLS_VERSION}.dylib /tmp/obsdeps/lib/libmbedx509.${LIBMBEDTLS_VERSION}.dylib
    install_name_tool -change libmbedx509.0.dylib /tmp/obsdeps/lib/libmbedx509.0.dylib /tmp/obsdeps/lib/libmbedtls.${LIBMBEDTLS_VERSION}.dylib
    install_name_tool -change libmbedcrypto.3.dylib /tmp/obsdeps/lib/libmbedcrypto.3.dylib /tmp/obsdeps/lib/libmbedtls.${LIBMBEDTLS_VERSION}.dylib
    install_name_tool -change libmbedcrypto.3.dylib /tmp/obsdeps/lib/libmbedcrypto.3.dylib /tmp/obsdeps/lib/libmbedx509.${LIBMBEDTLS_VERSION}.dylib
    find /tmp/obsdeps/lib -name libmbed\*.dylib -exec cp -PR \{\} /home/runner/work/obs-deps/obs-deps/CI_BUILD/obsdeps/lib/ \;
    rsync -avh --include="*/" --include="*.h" --exclude="*" ./include/mbedtls/* /home/runner/work/obs-deps/obs-deps/CI_BUILD/obsdeps/include/mbedtls
    rsync -avh --include="*/" --include="*.h" --exclude="*" ../include/mbedtls/* /home/runner/work/obs-deps/obs-deps/CI_BUILD/obsdeps/include/mbedtls
    if [ ! -d /tmp/obsdeps/lib/pkgconfig ]; then
        mkdir -p /tmp/obsdeps/lib/pkgconfig
    fi
    cat <<EOF > /tmp/obsdeps/lib/pkgconfig/mbedcrypto.pc
prefix=/tmp/obsdeps
libdir=\${prefix}/lib
includedir=\${prefix}/include
 
Name: mbedcrypto
Description: lightweight crypto and SSL/TLS library.
Version: ${LIBMBEDTLS_VERSION}
 
Libs: -L\${libdir} -lmbedcrypto
Cflags: -I\${includedir}
 
EOF
    cat <<EOF > /tmp/obsdeps/lib/pkgconfig/mbedtls.pc
prefix=/tmp/obsdeps
libdir=\${prefix}/lib
includedir=\${prefix}/include
 
Name: mbedtls
Description: lightweight crypto and SSL/TLS library.
Version: ${LIBMBEDTLS_VERSION}
 
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
Version: ${LIBMBEDTLS_VERSION}
 
Libs: -L\${libdir} -lmbedx509
Cflags: -I\${includedir}
Requires.private: mbedcrypto
 
EOF
}


build_7d5a2071-b648-48fa-aa8c-34edb3d9c954() {
    step "Build dependency libsrt"
    trap "caught_error 'Build dependency libsrt'" ERR
    ensure_dir /home/runner/work/obs-deps/obs-deps/CI_BUILD

    curl --retry 5 -L -O https://github.com/Haivision/srt/archive/v${LIBSRT_VERSION}.tar.gz
    tar -xf v${LIBSRT_VERSION}.tar.gz
    cd srt-${LIBSRT_VERSION}
    mkdir build
    cd ./build
    cmake -DCMAKE_INSTALL_PREFIX="/tmp/obsdeps" -DENABLE_APPS=OFF -DUSE_ENCLIB="mbedtls" -DENABLE_STATIC=ON -DENABLE_SHARED=OFF -DSSL_INCLUDE_DIRS="/tmp/obsdeps/include" -DSSL_LIBRARY_DIRS="/tmp/obsdeps/lib" -DCMAKE_FIND_FRAMEWORK=LAST ..
    make -j${PARALLELISM}
}


build_211d3e18-2145-4b81-b7a5-60fb9068e4b1() {
    step "Install dependency libsrt"
    trap "caught_error 'Install dependency libsrt'" ERR
    ensure_dir /home/runner/work/obs-deps/obs-deps/CI_BUILD/srt-1.4.1/build

    make install
}


build_8417055a-4767-435b-ab87-5124a7c7b2e7() {
    step "Build dependency ffmpeg"
    trap "caught_error 'Build dependency ffmpeg'" ERR
    ensure_dir /home/runner/work/obs-deps/obs-deps/CI_BUILD

    export LDFLAGS="-L/tmp/obsdeps/lib"
    export CFLAGS="-I/tmp/obsdeps/include"
    export LD_LIBRARY_PATH="/tmp/obsdeps/lib"
    
    # FFMPEG
    curl --retry 5 -L -O https://github.com/FFmpeg/FFmpeg/archive/n${FFMPEG_VERSION}.zip
    unzip -q -u ./n${FFMPEG_VERSION}.zip
    cd ./FFmpeg-n${FFMPEG_VERSION}
    mkdir build
    cd ./build
    ../configure --pkg-config-flags="--static" --extra-ldflags="-mmacosx-version-min=${MACOSX_DEPLOYMENT_TARGET}" --enable-shared --disable-static --shlibdir="/tmp/obsdeps/bin" --enable-gpl --disable-doc --enable-libx264 --enable-libopus --enable-libvorbis --enable-libvpx --enable-libsrt --disable-outdev=sdl
    make -j${PARALLELISM}
}


build_74d271ae-f6e0-4972-82db-226fedce0877() {
    step "Install dependency ffmpeg"
    trap "caught_error 'Install dependency ffmpeg'" ERR
    ensure_dir /home/runner/work/obs-deps/obs-deps/CI_BUILD/FFmpeg-n4.2.2/build

    find . -name \*.dylib -exec cp -PR \{\} /home/runner/work/obs-deps/obs-deps/CI_BUILD/obsdeps/bin/ \;
    rsync -avh --include="*/" --include="*.h" --exclude="*" ../* /home/runner/work/obs-deps/obs-deps/CI_BUILD/obsdeps/include/
    rsync -avh --include="*/" --include="*.h" --exclude="*" ./* /home/runner/work/obs-deps/obs-deps/CI_BUILD/obsdeps/include/
}


build_b1e56d19-844d-4603-aa3d-2a46f58c3bf9() {
    step "Build dependency libluajit"
    trap "caught_error 'Build dependency libluajit'" ERR
    ensure_dir /home/runner/work/obs-deps/obs-deps/CI_BUILD

    curl --retry 5 -L -C - -O https://LuaJIT.org/download/LuaJIT-${LIBLUAJIT_VERSION}.tar.gz
    tar -xf LuaJIT-${LIBLUAJIT_VERSION}.tar.gz
    cd LuaJIT-${LIBLUAJIT_VERSION}
    make PREFIX="/tmp/obsdeps" -j${PARALLELISM}
}


build_c6a7d0d2-ebd9-4849-aadf-a5dd33efa3d0() {
    step "Install dependency libluajit"
    trap "caught_error 'Install dependency libluajit'" ERR
    ensure_dir /home/runner/work/obs-deps/obs-deps/CI_BUILD/LuaJIT-2.1.0-beta3

    make PREFIX="/tmp/obsdeps" install
    find /tmp/obsdeps/lib -name libluajit\*.dylib -exec cp -PR \{\} /home/runner/work/obs-deps/obs-deps/CI_BUILD/obsdeps/lib/ \;
    rsync -avh --include="*/" --include="*.h" --exclude="*" src/* /home/runner/work/obs-deps/obs-deps/CI_BUILD/obsdeps/include/
    make PREFIX="/tmp/obsdeps" uninstall
}


build_1ad8eb04-55e9-429c-8156-7be6ffa29531() {
    step "Build dependency libfreetype"
    trap "caught_error 'Build dependency libfreetype'" ERR
    ensure_dir /home/runner/work/obs-deps/obs-deps/CI_BUILD

    export CFLAGS="-mmacosx-version-min=${MACOSX_DEPLOYMENT_TARGET}"
    
    curl --retry 5 -L -C - -O "https://download.savannah.gnu.org/releases/freetype/freetype-${LIBFREETYPE_VERSION}.tar.gz"
    tar -xf freetype-${LIBFREETYPE_VERSION}.tar.gz
    cd freetype-${LIBFREETYPE_VERSION}
    mkdir build
    cd build
    ../configure --enable-shared --disable-static --prefix="/tmp/obsdeps" --enable-freetype-config --without-harfbuzz
    make -j${PARALLELISM}
}


build_e0461cdf-975d-4040-83f0-a2884b77fb2b() {
    step "Install dependency libfreetype"
    trap "caught_error 'Install dependency libfreetype'" ERR
    ensure_dir /home/runner/work/obs-deps/obs-deps/CI_BUILD/freetype-2.10.1/build

    make install
    find /tmp/obsdeps/lib -name libfreetype\*.dylib -exec cp -PR \{\} /home/runner/work/obs-deps/obs-deps/CI_BUILD/obsdeps/lib/ \;
    rsync -avh --include="*/" --include="*.h" --exclude="*" ../include/* /home/runner/work/obs-deps/obs-deps/CI_BUILD/obsdeps/include/
    unset CFLAGS
}


build_6f69bd52-7ade-472e-ad06-e815b2e9eac9() {
    step "Package dependencies"
    trap "caught_error 'Package dependencies'" ERR
    ensure_dir /home/runner/work/obs-deps/obs-deps/CI_BUILD

    tar -czf macos-deps-${CURRENT_DATE}.tar.gz obsdeps
    if [ ! -d "/home/runner/work/obs-deps/obs-deps/macos" ]; then
      mkdir /home/runner/work/obs-deps/obs-deps/macos
    fi
    mv ./macos-deps-${CURRENT_DATE}.tar.gz /home/runner/work/obs-deps/obs-deps/macos
}


obs-deps-build-main() {
    ensure_dir /home/runner/work/obs-deps/obs-deps

    build_47cd2282-8965-4b61-ab28-62fec66c2cb4
    build_4a472a79-6484-4b41-b403-734d35e18080
    build_9daf28d2-6c93-4c31-a049-0588be784b54
    build_2f0aa16d-f472-4ada-a7d9-8c50c8840ec9
    build_6cce7e1e-2351-4da7-813c-16c7d65ffe89
    build_7870c90a-edb7-4670-b79f-377202ce0a89
    build_17d343fe-15d1-4fcd-a41d-2b8b35ab7305
    build_b02ec058-c61d-4670-a0ad-0e55b317f8fd
    build_45dd03a7-e455-4d23-a31c-8b9054b75b6c
    build_546a5d90-1b4f-47e4-b359-50a2ea10c191
    build_c6086b77-5e5e-4f3e-8799-294185078080
    build_7f599a16-96d4-426e-a72a-23d19d23a592
    build_d9ea00d0-7d17-4448-8bfe-22008a0b5f1d
    build_66f24758-7e0f-4987-8ad8-d667187700cc
    build_8395dc25-155f-4048-94cc-52bd98d5f418
    build_e36fba56-e72e-4237-98be-9325773282bb
    build_789673d5-6cb2-4f88-b1a1-adeb8f264dc9
    build_d3cd16bd-9ff2-4c55-bfbc-a36278bfeaff
    build_36dfe32d-2255-4a3d-873a-daaa29b198e9
    build_304b4465-63e3-4413-9365-e21a4e025170
    build_14a337ca-49c7-47bc-bed9-3c03d1607fd0
    build_ed02c88a-2cc9-48ab-83a8-d8634dbcdb46
    build_2802676a-13c9-457d-bf32-41548f8693a6
    build_7d5a2071-b648-48fa-aa8c-34edb3d9c954
    build_211d3e18-2145-4b81-b7a5-60fb9068e4b1
    build_8417055a-4767-435b-ab87-5124a7c7b2e7
    build_74d271ae-f6e0-4972-82db-226fedce0877
    build_b1e56d19-844d-4603-aa3d-2a46f58c3bf9
    build_c6a7d0d2-ebd9-4849-aadf-a5dd33efa3d0
    build_1ad8eb04-55e9-429c-8156-7be6ffa29531
    build_e0461cdf-975d-4040-83f0-a2884b77fb2b
    build_6f69bd52-7ade-472e-ad06-e815b2e9eac9

    hr "All Done"
}

obs-deps-build-main $*