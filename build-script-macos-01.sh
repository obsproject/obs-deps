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

build_59ce2b31-5467-41da-aaab-ccbbcc7eb398() {
    step "Install Homebrew dependencies"
    trap "caught_error 'Install Homebrew dependencies'" ERR
    ensure_dir ${BASE_DIR}

    if [ -d /usr/local/opt/xz ]; then
      brew unlink xz
    fi
    brew update --preinstall
    brew bundle
}


build_a2d4ea25-d09a-4dda-9455-7329828305d2() {
    step "Get Current Date"
    trap "caught_error 'Get Current Date'" ERR
    ensure_dir ${BASE_DIR}


}


build_61f07504-e5c5-471d-bf9f-7315b5451ba5() {
    step "Build environment setup"
    trap "caught_error 'Build environment setup'" ERR
    ensure_dir ${BASE_DIR}

    mkdir -p CI_BUILD/obsdeps/bin
    mkdir -p CI_BUILD/obsdeps/include
    mkdir -p CI_BUILD/obsdeps/lib
    mkdir -p CI_BUILD/obsdeps/share
    
    
}


build_423728af-6249-4823-ae41-976ba2745a3e() {
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


build_52666fd7-055e-438f-bf73-75ead92d8c96() {
    step "Install dependency swig"
    trap "caught_error 'Install dependency swig'" ERR
    ensure_dir ${BASE_DIR}/CI_BUILD/swig-3.0.12/build

    cp swig ${BASE_DIR}/CI_BUILD/obsdeps/bin/
    mkdir -p ${BASE_DIR}/CI_BUILD/obsdeps/share/swig/${SWIG_VERSION}
    rsync -avh --include="*.i" --include="*.swg" --include="python" --include="lua" --include="typemaps" --exclude="*" ../Lib/* ${BASE_DIR}/CI_BUILD/obsdeps/share/swig/${SWIG_VERSION}
}


build_f629d59a-e247-490e-a3ca-94b2cca06c7f() {
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


build_e3528333-44b8-40be-9548-30e2e8a6f5d4() {
    step "Install dependency libpng"
    trap "caught_error 'Install dependency libpng'" ERR
    ensure_dir ${BASE_DIR}/CI_BUILD/libpng-1.6.37/build

    make install
}


build_7eb6035b-c9eb-4263-bbef-b25821bf3f86() {
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


build_bf259c70-d7fb-414f-911f-a13f881bb11e() {
    step "Install dependency libopus"
    trap "caught_error 'Install dependency libopus'" ERR
    ensure_dir ${BASE_DIR}/CI_BUILD/opus-1.3.1/build

    make install
}


build_88f61949-71fd-474e-9685-9fe4d33d0cce() {
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


build_23bbe5ed-c5cb-460e-9173-c9abdec6f914() {
    step "Install dependency libogg"
    trap "caught_error 'Install dependency libogg'" ERR
    ensure_dir ${BASE_DIR}/CI_BUILD/ogg-68ca3841567247ac1f7850801a164f58738d8df9/build

    make install
}


build_8c9c3ebc-992f-4508-aac6-7751e8e0661d() {
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


build_34ad0174-c77e-42a2-b5b5-db3041dbe22a() {
    step "Install dependency libvorbis"
    trap "caught_error 'Install dependency libvorbis'" ERR
    ensure_dir ${BASE_DIR}/CI_BUILD/libvorbis-1.3.6/build

    make install
}


build_7aa7b818-b3f8-469d-b584-a705fee7d1a9() {
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


build_f6ee4096-2cbb-40d7-b8fb-2ab714abf84c() {
    step "Install dependency libvpx"
    trap "caught_error 'Install dependency libvpx'" ERR
    ensure_dir ${BASE_DIR}/CI_BUILD/libvpx-v1.8.2/build

    make install
}


build_f2694f96-51b7-43a1-a5f6-308bb27e054f() {
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


build_535953ea-5097-4184-86e5-f56852379a61() {
    step "Install dependency libjansson"
    trap "caught_error 'Install dependency libjansson'" ERR
    ensure_dir ${BASE_DIR}/CI_BUILD/jansson-2.12/build

    find . -name \*.dylib -exec cp -PR \{\} ${BASE_DIR}/CI_BUILD/obsdeps/bin/ \;
    rsync -avh --include="*/" --include="*.h" --exclude="*" ../src/* ${BASE_DIR}/CI_BUILD/obsdeps/include/
    rsync -avh --include="*/" --include="*.h" --exclude="*" ./src/* ${BASE_DIR}/CI_BUILD/obsdeps/include/
    cp ./*.h ${BASE_DIR}/CI_BUILD/obsdeps/include/
}


build_54bf2d9d-7f17-4253-b909-fb5f7d5f46a1() {
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


build_e97056a8-dd0c-4869-82e0-c78ca78e92a1() {
    step "Install dependency libx264"
    trap "caught_error 'Install dependency libx264'" ERR
    ensure_dir ${BASE_DIR}/CI_BUILD/x264-stable/build

    make install
}


build_6986f504-e132-4846-86d7-665f2ed51558() {
    step "Build dependency libx264 (dylib)"
    trap "caught_error 'Build dependency libx264 (dylib)'" ERR
    ensure_dir ${BASE_DIR}/CI_BUILD/x264-stable/build

    ../configure --extra-ldflags="-mmacosx-version-min=${MACOSX_DEPLOYMENT_TARGET}" --enable-shared --libdir="/tmp/obsdeps/bin" --prefix="/tmp/obsdeps"
    make -j${PARALLELISM}
}


build_cc184050-2093-4576-9943-a30ee1c729fc() {
    step "Install dependency libx264 (dylib)"
    trap "caught_error 'Install dependency libx264 (dylib)'" ERR
    ensure_dir ${BASE_DIR}/CI_BUILD/x264-stable/build

    ln -f -s libx264.*.dylib libx264.dylib
    find . -name \*.dylib -exec cp -PR \{\} ${BASE_DIR}/CI_BUILD/obsdeps/bin/ \;
    rsync -avh --include="*/" --include="*.h" --exclude="*" ../* ${BASE_DIR}/CI_BUILD/obsdeps/include/
    rsync -avh --include="*/" --include="*.h" --exclude="*" ./* ${BASE_DIR}/CI_BUILD/obsdeps/include/
}


build_794ea3b0-f192-41b0-8faa-adf5c5612f33() {
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


build_1de13dae-dd2b-4204-a05c-63c52c26b39c() {
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


build_ef6735a9-cd86-4304-966f-3426dd69bf7d() {
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


build_5d0b20f6-1692-457c-a9bd-9f3b2d84f8fc() {
    step "Install dependency libsrt"
    trap "caught_error 'Install dependency libsrt'" ERR
    ensure_dir ${BASE_DIR}/CI_BUILD/srt-1.4.1/build

    make install
}


build_31017168-ee4c-44a6-afe6-dfd3653e341f() {
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


build_a449abda-89a8-420b-a375-7d466c54430a() {
    step "Install dependency ffmpeg"
    trap "caught_error 'Install dependency ffmpeg'" ERR
    ensure_dir ${BASE_DIR}/CI_BUILD/FFmpeg-n4.2.2/build

    find . -name \*.dylib -exec cp -PR \{\} ${BASE_DIR}/CI_BUILD/obsdeps/bin/ \;
    rsync -avh --include="*/" --include="*.h" --exclude="*" ../* ${BASE_DIR}/CI_BUILD/obsdeps/include/
    rsync -avh --include="*/" --include="*.h" --exclude="*" ./* ${BASE_DIR}/CI_BUILD/obsdeps/include/
}


build_077e5666-c915-4b49-889d-f1b3c8c31b8f() {
    step "Build dependency libluajit"
    trap "caught_error 'Build dependency libluajit'" ERR
    ensure_dir ${BASE_DIR}/CI_BUILD

    curl --retry 5 -L -C - -O https://LuaJIT.org/download/LuaJIT-${LIBLUAJIT_VERSION}.tar.gz
    tar -xf LuaJIT-${LIBLUAJIT_VERSION}.tar.gz
    cd LuaJIT-${LIBLUAJIT_VERSION}
    make PREFIX="/tmp/obsdeps" -j${PARALLELISM}
}


build_f354067c-fa80-428b-88aa-0ddef29c06b2() {
    step "Install dependency libluajit"
    trap "caught_error 'Install dependency libluajit'" ERR
    ensure_dir ${BASE_DIR}/CI_BUILD/LuaJIT-2.1.0-beta3

    make PREFIX="/tmp/obsdeps" install
    find /tmp/obsdeps/lib -name libluajit\*.dylib -exec cp -PR \{\} ${BASE_DIR}/CI_BUILD/obsdeps/lib/ \;
    rsync -avh --include="*/" --include="*.h" --exclude="*" src/* ${BASE_DIR}/CI_BUILD/obsdeps/include/
    make PREFIX="/tmp/obsdeps" uninstall
}


build_1a4f59d3-4164-4edb-a403-d75d73a1ff44() {
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


build_f375771d-8937-4d12-8b6d-285e9d4e25f9() {
    step "Install dependency libfreetype"
    trap "caught_error 'Install dependency libfreetype'" ERR
    ensure_dir ${BASE_DIR}/CI_BUILD/freetype-2.10.1/build

    make install
    find /tmp/obsdeps/lib -name libfreetype\*.dylib -exec cp -PR \{\} ${BASE_DIR}/CI_BUILD/obsdeps/lib/ \;
    rsync -avh --include="*/" --include="*.h" --exclude="*" ../include/* ${BASE_DIR}/CI_BUILD/obsdeps/include/
}


build_203f8424-fca2-4ecb-a3fa-b96a5be09dd5() {
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


build_e48dbb77-b040-44f1-95f7-cac806fcbea1() {
    step "Install dependency librnnoise"
    trap "caught_error 'Install dependency librnnoise'" ERR
    ensure_dir ${BASE_DIR}/CI_BUILD/rnnoise-90ec41ef659fd82cfec2103e9bb7fc235e9ea66c/build

    make install
    find /tmp/obsdeps/lib -name librnnoise\*.dylib -exec cp -PR \{\} ${BASE_DIR}/CI_BUILD/obsdeps/lib/ \;
    rsync -avh --include="*/" --include="*.h" --exclude="*" ../include/* ${BASE_DIR}/CI_BUILD/obsdeps/include/
}


build_38a1b1fa-5144-493a-8e1d-dcaf98afe704() {
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

    build_59ce2b31-5467-41da-aaab-ccbbcc7eb398
    build_a2d4ea25-d09a-4dda-9455-7329828305d2
    build_61f07504-e5c5-471d-bf9f-7315b5451ba5
    build_423728af-6249-4823-ae41-976ba2745a3e
    build_52666fd7-055e-438f-bf73-75ead92d8c96
    build_f629d59a-e247-490e-a3ca-94b2cca06c7f
    build_e3528333-44b8-40be-9548-30e2e8a6f5d4
    build_7eb6035b-c9eb-4263-bbef-b25821bf3f86
    build_bf259c70-d7fb-414f-911f-a13f881bb11e
    build_88f61949-71fd-474e-9685-9fe4d33d0cce
    build_23bbe5ed-c5cb-460e-9173-c9abdec6f914
    build_8c9c3ebc-992f-4508-aac6-7751e8e0661d
    build_34ad0174-c77e-42a2-b5b5-db3041dbe22a
    build_7aa7b818-b3f8-469d-b584-a705fee7d1a9
    build_f6ee4096-2cbb-40d7-b8fb-2ab714abf84c
    build_f2694f96-51b7-43a1-a5f6-308bb27e054f
    build_535953ea-5097-4184-86e5-f56852379a61
    build_54bf2d9d-7f17-4253-b909-fb5f7d5f46a1
    build_e97056a8-dd0c-4869-82e0-c78ca78e92a1
    build_6986f504-e132-4846-86d7-665f2ed51558
    build_cc184050-2093-4576-9943-a30ee1c729fc
    build_794ea3b0-f192-41b0-8faa-adf5c5612f33
    build_1de13dae-dd2b-4204-a05c-63c52c26b39c
    build_ef6735a9-cd86-4304-966f-3426dd69bf7d
    build_5d0b20f6-1692-457c-a9bd-9f3b2d84f8fc
    build_31017168-ee4c-44a6-afe6-dfd3653e341f
    build_a449abda-89a8-420b-a375-7d466c54430a
    build_077e5666-c915-4b49-889d-f1b3c8c31b8f
    build_f354067c-fa80-428b-88aa-0ddef29c06b2
    build_1a4f59d3-4164-4edb-a403-d75d73a1ff44
    build_f375771d-8937-4d12-8b6d-285e9d4e25f9
    build_203f8424-fca2-4ecb-a3fa-b96a5be09dd5
    build_e48dbb77-b040-44f1-95f7-cac806fcbea1
    build_38a1b1fa-5144-493a-8e1d-dcaf98afe704

    hr "All Done"
}

obs-deps-build-main $*