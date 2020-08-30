#!/usr/bin/env bash

set -eE

PRODUCT_NAME="OBS Pre-Built Dependencies"
BASE_DIR="$(git rev-parse --show-toplevel)"

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
export LIBRNNOISE_VERSION="90ec41ef659fd82cfec2103e9bb7fc235e9ea66c"
export LIBVORBIS_VERSION="1.3.6"
export LIBVPX_VERSION="1.8.2"
export LIBJANSSON_VERSION="2.12"
export LIBX264_VERSION="stable"
export LIBMBEDTLS_VERSION="2.16.5"
export LIBSRT_VERSION="1.4.1"
export FFMPEG_VERSION="4.2.2"
export LIBLUAJIT_VERSION="2.1.0-beta3"
export LIBFREETYPE_VERSION="2.10.1"
export PCRE_VERSION="8.44"
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
    cleanup $${BASE_DIR}
    exit 1
}

build_1853302a-aef3-4033-ac6a-de343ee03774() {
    step "Install Homebrew dependencies"
    trap "caught_error 'Install Homebrew dependencies'" ERR
    ensure_dir ${BASE_DIR}

    if [ -d /usr/local/opt/xz ]; then
      brew unlink xz
    fi
    brew update --preinstall
    brew bundle
}


build_300b8d91-7e4b-48f0-9188-da638631fc4b() {
    step "Get Current Date"
    trap "caught_error 'Get Current Date'" ERR
    ensure_dir ${BASE_DIR}


}


build_88125f28-f059-463c-aea1-b4d34dfa8cfd() {
    step "Build environment setup"
    trap "caught_error 'Build environment setup'" ERR
    ensure_dir ${BASE_DIR}

    mkdir -p CI_BUILD/obsdeps/bin
    mkdir -p CI_BUILD/obsdeps/include
    mkdir -p CI_BUILD/obsdeps/lib
    mkdir -p CI_BUILD/obsdeps/share
    
    
}


build_2677a766-b316-4882-bec0-dee900ce816d() {
    step "Build dependency swig"
    trap "caught_error 'Build dependency swig'" ERR
    ensure_dir ${BASE_DIR}/CI_BUILD

    curl --retry 5 -L -O "https://downloads.sourceforge.net/project/swig/swig/swig-${SWIG_VERSION}/swig-${SWIG_VERSION}.tar.gz"
    tar -xf swig-${SWIG_VERSION}.tar.gz
    cd swig-${SWIG_VERSION}
    mkdir build
    cd build
    curl --retry 5 -L -O "https://ftp.pcre.org/pub/pcre/pcre-${PCRE_VERSION}.tar.bz2"
    ../Tools/pcre-build.sh
    ../configure --disable-dependency-tracking --prefix="/tmp/obsdeps"
    make -j${PARALLELISM}
}


build_2eb3744c-39a4-47dc-b47a-dddae7a940c2() {
    step "Install dependency swig"
    trap "caught_error 'Install dependency swig'" ERR
    ensure_dir ${BASE_DIR}/CI_BUILD/swig-3.0.12/build

    cp swig ${BASE_DIR}/CI_BUILD/obsdeps/bin/
    mkdir -p ${BASE_DIR}/CI_BUILD/obsdeps/share/swig/${SWIG_VERSION}
    rsync -avh --include="*.i" --include="*.swg" --include="python" --include="lua" --include="typemaps" --exclude="*" ../Lib/* ${BASE_DIR}/CI_BUILD/obsdeps/share/swig/${SWIG_VERSION}
}


build_0c82a3cd-4f1c-42ab-8d7f-8eab8603fef7() {
    step "Build dependency libpng"
    trap "caught_error 'Build dependency libpng'" ERR
    ensure_dir ${BASE_DIR}/CI_BUILD

    curl --retry 5 -L -O "https://downloads.sourceforge.net/project/libpng/libpng16/${LIBPNG_VERSION}/libpng-${LIBPNG_VERSION}.tar.xz"
    tar -xf libpng-${LIBPNG_VERSION}.tar.xz
    cd libpng-${LIBPNG_VERSION}
    mkdir build
    cd build
    ../configure --enable-static --disable-shared --prefix="/tmp/obsdeps"
    make -j${PARALLELISM}
}


build_f778a84d-6635-4ae3-ab6d-b17e430c1915() {
    step "Install dependency libpng"
    trap "caught_error 'Install dependency libpng'" ERR
    ensure_dir ${BASE_DIR}/CI_BUILD/libpng-1.6.37/build

    make install
}


build_3169edab-e279-449a-b2a2-8f62a8380e00() {
    step "Build dependency libopus"
    trap "caught_error 'Build dependency libopus'" ERR
    ensure_dir ${BASE_DIR}/CI_BUILD

    curl --retry 5 -L -C - -O "https://ftp.osuosl.org/pub/xiph/releases/opus/opus-${LIBOPUS_VERSION}.tar.gz"
    tar -xf opus-${LIBOPUS_VERSION}.tar.gz
    cd ./opus-${LIBOPUS_VERSION}
    mkdir build
    cd ./build
    ../configure --disable-shared --enable-static --prefix="/tmp/obsdeps"
    make -j${PARALLELISM}
}


build_d26abf98-2f7c-4018-8387-221bb6e7d9e4() {
    step "Install dependency libopus"
    trap "caught_error 'Install dependency libopus'" ERR
    ensure_dir ${BASE_DIR}/CI_BUILD/opus-1.3.1/build

    make install
}


build_c81df67e-ca1d-4118-932f-2c2e239d269d() {
    step "Build dependency libogg"
    trap "caught_error 'Build dependency libogg'" ERR
    ensure_dir ${BASE_DIR}/CI_BUILD

    curl --retry 5 -L -O https://gitlab.xiph.org/xiph/ogg/-/archive/${LIBOGG_VERSION}/ogg-${LIBOGG_VERSION}.tar.gz
    tar -xf ogg-${LIBOGG_VERSION}.tar.gz
    cd ./ogg-${LIBOGG_VERSION}
    mkdir build
    ./autogen.sh
    cd ./build
    ../configure --disable-shared --enable-static --prefix="/tmp/obsdeps"
    make -j${PARALLELISM}
}


build_f99bfba8-5a94-4a1c-a919-b8d4aae77cbf() {
    step "Install dependency libogg"
    trap "caught_error 'Install dependency libogg'" ERR
    ensure_dir ${BASE_DIR}/CI_BUILD/ogg-68ca3841567247ac1f7850801a164f58738d8df9/build

    make install
}


build_31dc653a-fe58-4a6c-80a1-d058f811aa90() {
    step "Build dependency libvorbis"
    trap "caught_error 'Build dependency libvorbis'" ERR
    ensure_dir ${BASE_DIR}/CI_BUILD

    curl --retry 5 -L -C - -O "https://ftp.osuosl.org/pub/xiph/releases/vorbis/libvorbis-${LIBVORBIS_VERSION}.tar.gz"
    tar -xf libvorbis-${LIBVORBIS_VERSION}.tar.gz
    cd ./libvorbis-${LIBVORBIS_VERSION}
    mkdir build
    cd ./build
    ../configure --disable-shared --enable-static --prefix="/tmp/obsdeps"
    make -j${PARALLELISM}
}


build_2e70f7d3-7c4e-4bca-b0dd-afa9a5fd2f6f() {
    step "Install dependency libvorbis"
    trap "caught_error 'Install dependency libvorbis'" ERR
    ensure_dir ${BASE_DIR}/CI_BUILD/libvorbis-1.3.6/build

    make install
}


build_76c27083-d30e-4626-acab-9a9eb7f23d5b() {
    step "Build dependency libvpx"
    trap "caught_error 'Build dependency libvpx'" ERR
    ensure_dir ${BASE_DIR}/CI_BUILD

    curl --retry 5 -L -O "https://chromium.googlesource.com/webm/libvpx/+archive/v${LIBVPX_VERSION}.tar.gz"
    mkdir -p ./libvpx-v${LIBVPX_VERSION}
    tar -xf v${LIBVPX_VERSION}.tar.gz -C $PWD/libvpx-v${LIBVPX_VERSION}
    cd ./libvpx-v${LIBVPX_VERSION}
    mkdir -p build
    cd ./build
    ../configure --disable-shared --prefix="/tmp/obsdeps" --libdir="/tmp/obsdeps/lib"
    make -j${PARALLELISM}
}


build_7c3837b2-ffe6-49d8-9554-778107e390b2() {
    step "Install dependency libvpx"
    trap "caught_error 'Install dependency libvpx'" ERR
    ensure_dir ${BASE_DIR}/CI_BUILD/libvpx-v1.8.2/build

    make install
}


build_e90420df-f09a-4cfd-a405-26d6b5441bcc() {
    step "Build dependency libjansson"
    trap "caught_error 'Build dependency libjansson'" ERR
    ensure_dir ${BASE_DIR}/CI_BUILD

    curl --retry 5 -L -C - -O http://www.digip.org/jansson/releases/jansson-${LIBJANSSON_VERSION}.tar.gz
    tar -xf jansson-${LIBJANSSON_VERSION}.tar.gz
    cd jansson-${LIBJANSSON_VERSION}
    mkdir build
    cd ./build
    ../configure --libdir="/tmp/obsdeps/bin" --enable-shared --disable-static
    make -j${PARALLELISM}
}


build_3b9840da-5752-40ff-888d-857205bf6a63() {
    step "Install dependency libjansson"
    trap "caught_error 'Install dependency libjansson'" ERR
    ensure_dir ${BASE_DIR}/CI_BUILD/jansson-2.12/build

    find . -name \*.dylib -exec cp -PR \{\} ${BASE_DIR}/CI_BUILD/obsdeps/bin/ \;
    rsync -avh --include="*/" --include="*.h" --exclude="*" ../src/* ${BASE_DIR}/CI_BUILD/obsdeps/include/
    rsync -avh --include="*/" --include="*.h" --exclude="*" ./src/* ${BASE_DIR}/CI_BUILD/obsdeps/include/
    cp ./*.h ${BASE_DIR}/CI_BUILD/obsdeps/include/
}


build_040964aa-efdc-418d-9b87-5e916971c455() {
    step "Build dependency libx264"
    trap "caught_error 'Build dependency libx264'" ERR
    ensure_dir ${BASE_DIR}/CI_BUILD

    # if [ ! -d ./x264-${LIBX264_VERSION} ]; then git clone https://code.videolan.org/videolan/x264.git x264-${LIBX264_VERSION}; fi
    if [ ! -d ./x264-${LIBX264_VERSION} ]; then git clone https://github.com/mirror/x264.git x264-${LIBX264_VERSION}; fi
    cd ./x264-${LIBX264_VERSION}
    git checkout origin/${LIBX264_VERSION}
    mkdir build
    cd ./build
    ../configure --extra-ldflags="-mmacosx-version-min=${MACOSX_DEPLOYMENT_TARGET}" --enable-static --prefix="/tmp/obsdeps"
    make -j${PARALLELISM}
}


build_a0b4a72b-1fea-4ca0-bc52-99d708d92aab() {
    step "Install dependency libx264"
    trap "caught_error 'Install dependency libx264'" ERR
    ensure_dir ${BASE_DIR}/CI_BUILD/x264-stable/build

    make install
}


build_c58f3f93-9862-4823-98ba-c6c4740fcdc1() {
    step "Build dependency libx264 (dylib)"
    trap "caught_error 'Build dependency libx264 (dylib)'" ERR
    ensure_dir ${BASE_DIR}/CI_BUILD/x264-stable/build

    ../configure --extra-ldflags="-mmacosx-version-min=${MACOSX_DEPLOYMENT_TARGET}" --enable-shared --libdir="/tmp/obsdeps/bin" --prefix="/tmp/obsdeps"
    make -j${PARALLELISM}
}


build_3fd09edd-b385-4e55-b4e3-b40296d853dd() {
    step "Install dependency libx264 (dylib)"
    trap "caught_error 'Install dependency libx264 (dylib)'" ERR
    ensure_dir ${BASE_DIR}/CI_BUILD/x264-stable/build

    ln -f -s libx264.*.dylib libx264.dylib
    find . -name \*.dylib -exec cp -PR \{\} ${BASE_DIR}/CI_BUILD/obsdeps/bin/ \;
    rsync -avh --include="*/" --include="*.h" --exclude="*" ../* ${BASE_DIR}/CI_BUILD/obsdeps/include/
    rsync -avh --include="*/" --include="*.h" --exclude="*" ./* ${BASE_DIR}/CI_BUILD/obsdeps/include/
}


build_4fbc1fb9-2df6-4cba-a021-81977eb61a91() {
    step "Build dependency libmbedtls"
    trap "caught_error 'Build dependency libmbedtls'" ERR
    ensure_dir ${BASE_DIR}/CI_BUILD

    curl --retry 5 -L -C - -O "https://tls.mbed.org/download/mbedtls-${LIBMBEDTLS_VERSION}-gpl.tgz"
    tar -xf mbedtls-${LIBMBEDTLS_VERSION}-gpl.tgz
    cd mbedtls-${LIBMBEDTLS_VERSION}
    sed -i '.orig' 's/\/\/\#define MBEDTLS_THREADING_PTHREAD/\#define MBEDTLS_THREADING_PTHREAD/g' include/mbedtls/config.h
    sed -i '.orig' 's/\/\/\#define MBEDTLS_THREADING_C/\#define MBEDTLS_THREADING_C/g' include/mbedtls/config.h
    mkdir build
    cd ./build
    cmake -DCMAKE_INSTALL_PREFIX="/tmp/obsdeps" -DUSE_SHARED_MBEDTLS_LIBRARY=ON -DENABLE_PROGRAMS=OFF ..
    make -j${PARALLELISM}
}


build_c57c0777-c306-42e8-91a2-4aa83e583f3d() {
    step "Install dependency libmbedtls"
    trap "caught_error 'Install dependency libmbedtls'" ERR
    ensure_dir ${BASE_DIR}/CI_BUILD/mbedtls-2.16.5/build

    make install
    install_name_tool -id /tmp/obsdeps/lib/libmbedtls.${LIBMBEDTLS_VERSION}.dylib /tmp/obsdeps/lib/libmbedtls.${LIBMBEDTLS_VERSION}.dylib
    install_name_tool -id /tmp/obsdeps/lib/libmbedcrypto.${LIBMBEDTLS_VERSION}.dylib /tmp/obsdeps/lib/libmbedcrypto.${LIBMBEDTLS_VERSION}.dylib
    install_name_tool -id /tmp/obsdeps/lib/libmbedx509.${LIBMBEDTLS_VERSION}.dylib /tmp/obsdeps/lib/libmbedx509.${LIBMBEDTLS_VERSION}.dylib
    install_name_tool -change libmbedx509.0.dylib /tmp/obsdeps/lib/libmbedx509.0.dylib /tmp/obsdeps/lib/libmbedtls.${LIBMBEDTLS_VERSION}.dylib
    install_name_tool -change libmbedcrypto.3.dylib /tmp/obsdeps/lib/libmbedcrypto.3.dylib /tmp/obsdeps/lib/libmbedtls.${LIBMBEDTLS_VERSION}.dylib
    install_name_tool -change libmbedcrypto.3.dylib /tmp/obsdeps/lib/libmbedcrypto.3.dylib /tmp/obsdeps/lib/libmbedx509.${LIBMBEDTLS_VERSION}.dylib
    find /tmp/obsdeps/lib -name libmbed\*.dylib -exec cp -PR \{\} ${BASE_DIR}/CI_BUILD/obsdeps/lib/ \;
    rsync -avh --include="*/" --include="*.h" --exclude="*" ./include/mbedtls/* ${BASE_DIR}/CI_BUILD/obsdeps/include/mbedtls
    rsync -avh --include="*/" --include="*.h" --exclude="*" ../include/mbedtls/* ${BASE_DIR}/CI_BUILD/obsdeps/include/mbedtls
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


build_d4fd605b-27d9-49b6-b6b5-c4490396b86f() {
    step "Build dependency libsrt"
    trap "caught_error 'Build dependency libsrt'" ERR
    ensure_dir ${BASE_DIR}/CI_BUILD

    curl --retry 5 -L -O https://github.com/Haivision/srt/archive/v${LIBSRT_VERSION}.tar.gz
    tar -xf v${LIBSRT_VERSION}.tar.gz
    cd srt-${LIBSRT_VERSION}
    mkdir build
    cd ./build
    cmake -DCMAKE_INSTALL_PREFIX="/tmp/obsdeps" -DENABLE_APPS=OFF -DUSE_ENCLIB="mbedtls" -DENABLE_STATIC=ON -DENABLE_SHARED=OFF -DSSL_INCLUDE_DIRS="/tmp/obsdeps/include" -DSSL_LIBRARY_DIRS="/tmp/obsdeps/lib" -DCMAKE_FIND_FRAMEWORK=LAST ..
    make -j${PARALLELISM}
}


build_34268ab5-800d-45e2-ad16-4a8d7e894dfd() {
    step "Install dependency libsrt"
    trap "caught_error 'Install dependency libsrt'" ERR
    ensure_dir ${BASE_DIR}/CI_BUILD/srt-1.4.1/build

    make install
}


build_086f5cf2-2b38-4019-ac52-042688ea2787() {
    step "Build dependency ffmpeg"
    trap "caught_error 'Build dependency ffmpeg'" ERR
    ensure_dir ${BASE_DIR}/CI_BUILD

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


build_a1aeb41e-78a4-4a41-9db5-a6588e367c66() {
    step "Install dependency ffmpeg"
    trap "caught_error 'Install dependency ffmpeg'" ERR
    ensure_dir ${BASE_DIR}/CI_BUILD/FFmpeg-n4.2.2/build

    find . -name \*.dylib -exec cp -PR \{\} ${BASE_DIR}/CI_BUILD/obsdeps/bin/ \;
    rsync -avh --include="*/" --include="*.h" --exclude="*" ../* ${BASE_DIR}/CI_BUILD/obsdeps/include/
    rsync -avh --include="*/" --include="*.h" --exclude="*" ./* ${BASE_DIR}/CI_BUILD/obsdeps/include/
}


build_b92fe953-8b71-49ba-a423-18d2a497da11() {
    step "Build dependency libluajit"
    trap "caught_error 'Build dependency libluajit'" ERR
    ensure_dir ${BASE_DIR}/CI_BUILD

    curl --retry 5 -L -C - -O https://LuaJIT.org/download/LuaJIT-${LIBLUAJIT_VERSION}.tar.gz
    tar -xf LuaJIT-${LIBLUAJIT_VERSION}.tar.gz
    cd LuaJIT-${LIBLUAJIT_VERSION}
    make PREFIX="/tmp/obsdeps" -j${PARALLELISM}
}


build_c124c71f-6d5a-4d45-8d29-96a1df6eed4e() {
    step "Install dependency libluajit"
    trap "caught_error 'Install dependency libluajit'" ERR
    ensure_dir ${BASE_DIR}/CI_BUILD/LuaJIT-2.1.0-beta3

    make PREFIX="/tmp/obsdeps" install
    find /tmp/obsdeps/lib -name libluajit\*.dylib -exec cp -PR \{\} ${BASE_DIR}/CI_BUILD/obsdeps/lib/ \;
    rsync -avh --include="*/" --include="*.h" --exclude="*" src/* ${BASE_DIR}/CI_BUILD/obsdeps/include/
    make PREFIX="/tmp/obsdeps" uninstall
}


build_73290a5e-976b-4939-8ff9-3103d0278493() {
    step "Build dependency libfreetype"
    trap "caught_error 'Build dependency libfreetype'" ERR
    ensure_dir ${BASE_DIR}/CI_BUILD

    export CFLAGS="-mmacosx-version-min=${MACOSX_DEPLOYMENT_TARGET}"
    curl --retry 5 -L -C - -O "https://download.savannah.gnu.org/releases/freetype/freetype-${LIBFREETYPE_VERSION}.tar.gz"
    tar -xf freetype-${LIBFREETYPE_VERSION}.tar.gz
    cd freetype-${LIBFREETYPE_VERSION}
    mkdir build
    cd build
    ../configure --enable-shared --disable-static --prefix="/tmp/obsdeps" --enable-freetype-config --without-harfbuzz
    make -j${PARALLELISM}
}


build_d90dfcc0-a10b-4350-9bb5-6da0cd588344() {
    step "Install dependency libfreetype"
    trap "caught_error 'Install dependency libfreetype'" ERR
    ensure_dir ${BASE_DIR}/CI_BUILD/freetype-2.10.1/build

    make install
    find /tmp/obsdeps/lib -name libfreetype\*.dylib -exec cp -PR \{\} ${BASE_DIR}/CI_BUILD/obsdeps/lib/ \;
    rsync -avh --include="*/" --include="*.h" --exclude="*" ../include/* ${BASE_DIR}/CI_BUILD/obsdeps/include/
}


build_b2cf8beb-13ac-4d9c-8677-a2baf3810494() {
    step "Build dependency librnnoise"
    trap "caught_error 'Build dependency librnnoise'" ERR
    ensure_dir ${BASE_DIR}/CI_BUILD

    if [ ! -d ./rnnoise-${LIBRNNOISE_VERSION} ]; then git clone https://github.com/xiph/rnnoise.git rnnoise-${LIBRNNOISE_VERSION}; fi
    cd ./rnnoise-${LIBRNNOISE_VERSION}
    git checkout ${LIBRNNOISE_VERSION}
    ./autogen.sh
    mkdir build
    cd build
    ../configure --prefix="/tmp/obsdeps"
    make -j${PARALLELISM}
}


build_612495f2-799f-40d4-9cf9-e046fb39a75a() {
    step "Install dependency librnnoise"
    trap "caught_error 'Install dependency librnnoise'" ERR
    ensure_dir ${BASE_DIR}/CI_BUILD/rnnoise-90ec41ef659fd82cfec2103e9bb7fc235e9ea66c/build

    make install
    find /tmp/obsdeps/lib -name librnnoise\*.dylib -exec cp -PR \{\} ${BASE_DIR}/CI_BUILD/obsdeps/lib/ \;
    rsync -avh --include="*/" --include="*.h" --exclude="*" ../include/* ${BASE_DIR}/CI_BUILD/obsdeps/include/
}


build_712e6b86-eea2-4e60-827a-ae7d4cb82a88() {
    step "Package dependencies"
    trap "caught_error 'Package dependencies'" ERR
    ensure_dir ${BASE_DIR}/CI_BUILD

    tar -czf macos-deps-${CURRENT_DATE}.tar.gz obsdeps
    if [ ! -d "${BASE_DIR}/macos" ]; then
      mkdir ${BASE_DIR}/macos
    fi
    mv ./macos-deps-${CURRENT_DATE}.tar.gz ${BASE_DIR}/macos
}


obs-deps-build-main() {
    ensure_dir ${BASE_DIR}

    build_1853302a-aef3-4033-ac6a-de343ee03774
    build_300b8d91-7e4b-48f0-9188-da638631fc4b
    build_88125f28-f059-463c-aea1-b4d34dfa8cfd
    build_2677a766-b316-4882-bec0-dee900ce816d
    build_2eb3744c-39a4-47dc-b47a-dddae7a940c2
    build_0c82a3cd-4f1c-42ab-8d7f-8eab8603fef7
    build_f778a84d-6635-4ae3-ab6d-b17e430c1915
    build_3169edab-e279-449a-b2a2-8f62a8380e00
    build_d26abf98-2f7c-4018-8387-221bb6e7d9e4
    build_c81df67e-ca1d-4118-932f-2c2e239d269d
    build_f99bfba8-5a94-4a1c-a919-b8d4aae77cbf
    build_31dc653a-fe58-4a6c-80a1-d058f811aa90
    build_2e70f7d3-7c4e-4bca-b0dd-afa9a5fd2f6f
    build_76c27083-d30e-4626-acab-9a9eb7f23d5b
    build_7c3837b2-ffe6-49d8-9554-778107e390b2
    build_e90420df-f09a-4cfd-a405-26d6b5441bcc
    build_3b9840da-5752-40ff-888d-857205bf6a63
    build_040964aa-efdc-418d-9b87-5e916971c455
    build_a0b4a72b-1fea-4ca0-bc52-99d708d92aab
    build_c58f3f93-9862-4823-98ba-c6c4740fcdc1
    build_3fd09edd-b385-4e55-b4e3-b40296d853dd
    build_4fbc1fb9-2df6-4cba-a021-81977eb61a91
    build_c57c0777-c306-42e8-91a2-4aa83e583f3d
    build_d4fd605b-27d9-49b6-b6b5-c4490396b86f
    build_34268ab5-800d-45e2-ad16-4a8d7e894dfd
    build_086f5cf2-2b38-4019-ac52-042688ea2787
    build_a1aeb41e-78a4-4a41-9db5-a6588e367c66
    build_b92fe953-8b71-49ba-a423-18d2a497da11
    build_c124c71f-6d5a-4d45-8d29-96a1df6eed4e
    build_73290a5e-976b-4939-8ff9-3103d0278493
    build_d90dfcc0-a10b-4350-9bb5-6da0cd588344
    build_b2cf8beb-13ac-4d9c-8677-a2baf3810494
    build_612495f2-799f-40d4-9cf9-e046fb39a75a
    build_712e6b86-eea2-4e60-827a-ae7d4cb82a88

    hr "All Done"
}

obs-deps-build-main $*