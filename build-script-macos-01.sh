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

build_3328133c-ec14-4842-b835-032959a9ba0c() {
    step "Install Homebrew dependencies"
    trap "caught_error 'Install Homebrew dependencies'" ERR
    ensure_dir ${BASE_DIR}

    if [ -d /usr/local/opt/xz ]; then
      brew unlink xz
    fi
    brew update --preinstall
    brew bundle
}


build_cf549414-44e3-4108-b6ab-d28e31402906() {
    step "Get Current Date"
    trap "caught_error 'Get Current Date'" ERR
    ensure_dir ${BASE_DIR}


}


build_efc457a5-0dc0-4624-a14a-42569976594e() {
    step "Build environment setup"
    trap "caught_error 'Build environment setup'" ERR
    ensure_dir ${BASE_DIR}

    mkdir -p CI_BUILD/obsdeps/bin
    mkdir -p CI_BUILD/obsdeps/include
    mkdir -p CI_BUILD/obsdeps/lib
    mkdir -p CI_BUILD/obsdeps/share
    
    
}


build_bc8d06e5-81cb-4046-b33b-bfd9d74c7b6c() {
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


build_65a6a263-e529-4c65-9428-30e18bcee63a() {
    step "Install dependency swig"
    trap "caught_error 'Install dependency swig'" ERR
    ensure_dir ${BASE_DIR}/CI_BUILD/swig-3.0.12/build

    cp swig ${BASE_DIR}/CI_BUILD/obsdeps/bin/
    mkdir -p ${BASE_DIR}/CI_BUILD/obsdeps/share/swig/${SWIG_VERSION}
    rsync -avh --include="*.i" --include="*.swg" --include="python" --include="lua" --include="typemaps" --exclude="*" ../Lib/* ${BASE_DIR}/CI_BUILD/obsdeps/share/swig/${SWIG_VERSION}
}


build_9ee4a5c5-13b0-439d-92f0-bcad524d05fc() {
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


build_03057d68-2aff-4f45-b729-27885e42526c() {
    step "Install dependency libpng"
    trap "caught_error 'Install dependency libpng'" ERR
    ensure_dir ${BASE_DIR}/CI_BUILD/libpng-1.6.37/build

    make install
}


build_2195785f-0cd1-4fa5-a26b-19623cd62a4b() {
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


build_06a60377-4125-47b7-ae1a-56d302c1d908() {
    step "Install dependency libopus"
    trap "caught_error 'Install dependency libopus'" ERR
    ensure_dir ${BASE_DIR}/CI_BUILD/opus-1.3.1/build

    make install
}


build_e1fe866e-b7a4-45f4-89be-405d6bcdf96c() {
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


build_ae5dead9-3572-4993-8617-027fd437d53b() {
    step "Install dependency libogg"
    trap "caught_error 'Install dependency libogg'" ERR
    ensure_dir ${BASE_DIR}/CI_BUILD/ogg-68ca3841567247ac1f7850801a164f58738d8df9/build

    make install
}


build_230a802f-5089-438e-8f9e-98ad6ee90983() {
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


build_3ec37d81-b60f-456d-96a0-ece878ee1255() {
    step "Install dependency libvorbis"
    trap "caught_error 'Install dependency libvorbis'" ERR
    ensure_dir ${BASE_DIR}/CI_BUILD/libvorbis-1.3.6/build

    make install
}


build_142ffdb7-e917-48b6-9a29-e6d619ae02ca() {
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


build_1cf3ba6f-bbe7-42ad-9938-c1fca2d3d70f() {
    step "Install dependency libvpx"
    trap "caught_error 'Install dependency libvpx'" ERR
    ensure_dir ${BASE_DIR}/CI_BUILD/libvpx-v1.8.2/build

    make install
}


build_3f20ff11-559f-4e2a-97db-c81a83956c81() {
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


build_f8ea9e47-07f6-402a-bda2-cbe75e8a1ccd() {
    step "Install dependency libjansson"
    trap "caught_error 'Install dependency libjansson'" ERR
    ensure_dir ${BASE_DIR}/CI_BUILD/jansson-2.12/build

    find . -name \*.dylib -exec cp -PR \{\} ${BASE_DIR}/CI_BUILD/obsdeps/bin/ \;
    rsync -avh --include="*/" --include="*.h" --exclude="*" ../src/* ${BASE_DIR}/CI_BUILD/obsdeps/include/
    rsync -avh --include="*/" --include="*.h" --exclude="*" ./src/* ${BASE_DIR}/CI_BUILD/obsdeps/include/
    cp ./*.h ${BASE_DIR}/CI_BUILD/obsdeps/include/
}


build_d9250439-d231-40fd-8adf-85a2df08ed84() {
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


build_3db44758-9f6c-461e-bdbc-d2a081c7fc7b() {
    step "Install dependency libx264"
    trap "caught_error 'Install dependency libx264'" ERR
    ensure_dir ${BASE_DIR}/CI_BUILD/x264-stable/build

    make install
}


build_32206489-29e4-48b0-a45c-3b68f572a45f() {
    step "Build dependency libx264 (dylib)"
    trap "caught_error 'Build dependency libx264 (dylib)'" ERR
    ensure_dir ${BASE_DIR}/CI_BUILD/x264-stable/build

    ../configure --extra-ldflags="-mmacosx-version-min=${MACOSX_DEPLOYMENT_TARGET}" --enable-shared --libdir="/tmp/obsdeps/bin" --prefix="/tmp/obsdeps"
    make -j${PARALLELISM}
}


build_1d839f9b-8b44-47cb-a0dc-5d937aa6ab8b() {
    step "Install dependency libx264 (dylib)"
    trap "caught_error 'Install dependency libx264 (dylib)'" ERR
    ensure_dir ${BASE_DIR}/CI_BUILD/x264-stable/build

    ln -f -s libx264.*.dylib libx264.dylib
    find . -name \*.dylib -exec cp -PR \{\} ${BASE_DIR}/CI_BUILD/obsdeps/bin/ \;
    rsync -avh --include="*/" --include="*.h" --exclude="*" ../* ${BASE_DIR}/CI_BUILD/obsdeps/include/
    rsync -avh --include="*/" --include="*.h" --exclude="*" ./* ${BASE_DIR}/CI_BUILD/obsdeps/include/
}


build_9870ddd5-7cd9-427f-9ff3-45597136beda() {
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


build_7f75863d-94ea-43cd-94d4-c89af047f600() {
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


build_fe56dc0e-10da-46d6-a6a1-f6b06776d8b5() {
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


build_7db41bbe-f33f-4d4b-bc50-0cef41c21880() {
    step "Install dependency libsrt"
    trap "caught_error 'Install dependency libsrt'" ERR
    ensure_dir ${BASE_DIR}/CI_BUILD/srt-1.4.1/build

    make install
}


build_8f5ff917-0879-4ba3-8aae-c0502a36719f() {
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


build_9d7c6744-eba7-447e-92f9-9e60398df9e8() {
    step "Install dependency ffmpeg"
    trap "caught_error 'Install dependency ffmpeg'" ERR
    ensure_dir ${BASE_DIR}/CI_BUILD/FFmpeg-n4.2.2/build

    find . -name \*.dylib -exec cp -PR \{\} ${BASE_DIR}/CI_BUILD/obsdeps/bin/ \;
    rsync -avh --include="*/" --include="*.h" --exclude="*" ../* ${BASE_DIR}/CI_BUILD/obsdeps/include/
    rsync -avh --include="*/" --include="*.h" --exclude="*" ./* ${BASE_DIR}/CI_BUILD/obsdeps/include/
}


build_dfe9ae6e-7740-4c4d-9e07-65a0ca838689() {
    step "Build dependency libluajit"
    trap "caught_error 'Build dependency libluajit'" ERR
    ensure_dir ${BASE_DIR}/CI_BUILD

    curl --retry 5 -L -C - -O https://LuaJIT.org/download/LuaJIT-${LIBLUAJIT_VERSION}.tar.gz
    tar -xf LuaJIT-${LIBLUAJIT_VERSION}.tar.gz
    cd LuaJIT-${LIBLUAJIT_VERSION}
    make PREFIX="/tmp/obsdeps" -j${PARALLELISM}
}


build_78a79063-7ffe-4be6-9789-146c19397d41() {
    step "Install dependency libluajit"
    trap "caught_error 'Install dependency libluajit'" ERR
    ensure_dir ${BASE_DIR}/CI_BUILD/LuaJIT-2.1.0-beta3

    make PREFIX="/tmp/obsdeps" install
    find /tmp/obsdeps/lib -name libluajit\*.dylib -exec cp -PR \{\} ${BASE_DIR}/CI_BUILD/obsdeps/lib/ \;
    rsync -avh --include="*/" --include="*.h" --exclude="*" src/* ${BASE_DIR}/CI_BUILD/obsdeps/include/
    make PREFIX="/tmp/obsdeps" uninstall
}


build_04132bb4-4e4a-4591-8263-807e2d57bb91() {
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


build_5906dc13-ad57-4d66-b7cb-9873c87f710f() {
    step "Install dependency libfreetype"
    trap "caught_error 'Install dependency libfreetype'" ERR
    ensure_dir ${BASE_DIR}/CI_BUILD/freetype-2.10.1/build

    make install
    find /tmp/obsdeps/lib -name libfreetype\*.dylib -exec cp -PR \{\} ${BASE_DIR}/CI_BUILD/obsdeps/lib/ \;
    rsync -avh --include="*/" --include="*.h" --exclude="*" ../include/* ${BASE_DIR}/CI_BUILD/obsdeps/include/
}


build_cbd2971a-ecb6-4fa2-a8e0-400bd5bbe5c2() {
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


build_4c4e00dc-6aa3-42fa-8e78-774aa8d7aba5() {
    step "Install dependency librnnoise"
    trap "caught_error 'Install dependency librnnoise'" ERR
    ensure_dir ${BASE_DIR}/CI_BUILD/rnnoise-90ec41ef659fd82cfec2103e9bb7fc235e9ea66c/build

    make install
    find /tmp/obsdeps/lib -name librnnoise\*.dylib -exec cp -PR \{\} ${BASE_DIR}/CI_BUILD/obsdeps/lib/ \;
    rsync -avh --include="*/" --include="*.h" --exclude="*" ../include/* ${BASE_DIR}/CI_BUILD/obsdeps/include/
}


build_43ff12e4-1356-4c62-9252-a647bdc9d03e() {
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

    build_3328133c-ec14-4842-b835-032959a9ba0c
    build_cf549414-44e3-4108-b6ab-d28e31402906
    build_efc457a5-0dc0-4624-a14a-42569976594e
    build_bc8d06e5-81cb-4046-b33b-bfd9d74c7b6c
    build_65a6a263-e529-4c65-9428-30e18bcee63a
    build_9ee4a5c5-13b0-439d-92f0-bcad524d05fc
    build_03057d68-2aff-4f45-b729-27885e42526c
    build_2195785f-0cd1-4fa5-a26b-19623cd62a4b
    build_06a60377-4125-47b7-ae1a-56d302c1d908
    build_e1fe866e-b7a4-45f4-89be-405d6bcdf96c
    build_ae5dead9-3572-4993-8617-027fd437d53b
    build_230a802f-5089-438e-8f9e-98ad6ee90983
    build_3ec37d81-b60f-456d-96a0-ece878ee1255
    build_142ffdb7-e917-48b6-9a29-e6d619ae02ca
    build_1cf3ba6f-bbe7-42ad-9938-c1fca2d3d70f
    build_3f20ff11-559f-4e2a-97db-c81a83956c81
    build_f8ea9e47-07f6-402a-bda2-cbe75e8a1ccd
    build_d9250439-d231-40fd-8adf-85a2df08ed84
    build_3db44758-9f6c-461e-bdbc-d2a081c7fc7b
    build_32206489-29e4-48b0-a45c-3b68f572a45f
    build_1d839f9b-8b44-47cb-a0dc-5d937aa6ab8b
    build_9870ddd5-7cd9-427f-9ff3-45597136beda
    build_7f75863d-94ea-43cd-94d4-c89af047f600
    build_fe56dc0e-10da-46d6-a6a1-f6b06776d8b5
    build_7db41bbe-f33f-4d4b-bc50-0cef41c21880
    build_8f5ff917-0879-4ba3-8aae-c0502a36719f
    build_9d7c6744-eba7-447e-92f9-9e60398df9e8
    build_dfe9ae6e-7740-4c4d-9e07-65a0ca838689
    build_78a79063-7ffe-4be6-9789-146c19397d41
    build_04132bb4-4e4a-4591-8263-807e2d57bb91
    build_5906dc13-ad57-4d66-b7cb-9873c87f710f
    build_cbd2971a-ecb6-4fa2-a8e0-400bd5bbe5c2
    build_4c4e00dc-6aa3-42fa-8e78-774aa8d7aba5
    build_43ff12e4-1356-4c62-9252-a647bdc9d03e

    hr "All Done"
}

obs-deps-build-main $*