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

build_b96545c3-fd65-4a2c-8033-5a8341d0f827() {
    step "Install Homebrew dependencies"
    trap "caught_error 'Install Homebrew dependencies'" ERR
    ensure_dir /home/runner/work/obs-deps/obs-deps

    brew bundle
}


build_c8ebcfb8-bf1f-4d9b-bbaa-52e191ba3269() {
    step "Get Current Date"
    trap "caught_error 'Get Current Date'" ERR
    ensure_dir /home/runner/work/obs-deps/obs-deps


}


build_412dc87a-fb95-4b11-8ce0-1a0edd003834() {
    step "Build environment setup"
    trap "caught_error 'Build environment setup'" ERR
    ensure_dir /home/runner/work/obs-deps/obs-deps

    mkdir -p CI_BUILD/obsdeps/bin
    mkdir -p CI_BUILD/obsdeps/include
    mkdir -p CI_BUILD/obsdeps/lib
    mkdir -p CI_BUILD/obsdeps/share
    
    
}


build_de21b3b3-8765-4148-ab13-5299df6b6082() {
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


build_a1e48a03-667b-4bfd-95ba-08f8ec0f587a() {
    step "Install dependency swig"
    trap "caught_error 'Install dependency swig'" ERR
    ensure_dir /home/runner/work/obs-deps/obs-deps/CI_BUILD/swig-3.0.12/build

    cp swig /home/runner/work/obs-deps/obs-deps/CI_BUILD/obsdeps/bin/
    mkdir -p /home/runner/work/obs-deps/obs-deps/CI_BUILD/obsdeps/share/swig/${SWIG_VERSION}
    rsync -avh --include="*.i" --include="*.swg" --include="python" --include="lua" --include="typemaps" --exclude="*" ../Lib/* /home/runner/work/obs-deps/obs-deps/CI_BUILD/obsdeps/share/swig/${SWIG_VERSION}
}


build_e61ca4f2-a119-4e3d-aee0-00fc047d6cbe() {
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


build_06e7c257-51cd-4510-a294-c00def3a621d() {
    step "Install dependency libpng"
    trap "caught_error 'Install dependency libpng'" ERR
    ensure_dir /home/runner/work/obs-deps/obs-deps/CI_BUILD/libpng-1.6.37/build

    make install
}


build_c6068e37-b1d4-41f3-b450-f8d4163cc7dc() {
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


build_2d9e27c3-8c31-45b5-86d5-f8ad2f816dcf() {
    step "Install dependency libopus"
    trap "caught_error 'Install dependency libopus'" ERR
    ensure_dir /home/runner/work/obs-deps/obs-deps/CI_BUILD/opus-1.3.1/build

    make install
}


build_9b7b1cd0-7897-47cb-b875-5bf579dba029() {
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


build_0a50357d-cad4-495f-8be6-4bdeae313244() {
    step "Install dependency libogg"
    trap "caught_error 'Install dependency libogg'" ERR
    ensure_dir /home/runner/work/obs-deps/obs-deps/CI_BUILD/ogg-68ca3841567247ac1f7850801a164f58738d8df9/build

    make install
}


build_3f19fe04-fbae-46d4-8d36-4be912870f8e() {
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


build_1a884933-24c0-4d2b-977b-22d946293634() {
    step "Install dependency libvorbis"
    trap "caught_error 'Install dependency libvorbis'" ERR
    ensure_dir /home/runner/work/obs-deps/obs-deps/CI_BUILD/libvorbis-1.3.6/build

    make install
}


build_0a874bdd-8456-4f69-aac9-ebe738c641a7() {
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


build_153a8285-7213-43b1-a7da-3e6ec66c64e5() {
    step "Install dependency libvpx"
    trap "caught_error 'Install dependency libvpx'" ERR
    ensure_dir /home/runner/work/obs-deps/obs-deps/CI_BUILD/libvpx-v1.8.2/build

    make install
}


build_69c1cccd-879f-44ce-a45c-fe5fe7218dde() {
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


build_950fece5-dddd-4ee6-80f5-f77979e6cc58() {
    step "Install dependency libjansson"
    trap "caught_error 'Install dependency libjansson'" ERR
    ensure_dir /home/runner/work/obs-deps/obs-deps/CI_BUILD/jansson-2.12/build

    find . -name \*.dylib -exec cp \{\} /home/runner/work/obs-deps/obs-deps/CI_BUILD/obsdeps/bin/ \;
    rsync -avh --include="*/" --include="*.h" --exclude="*" ../src/* /home/runner/work/obs-deps/obs-deps/CI_BUILD/obsdeps/include/
    rsync -avh --include="*/" --include="*.h" --exclude="*" ./src/* /home/runner/work/obs-deps/obs-deps/CI_BUILD/obsdeps/include/
    cp ./*.h /home/runner/work/obs-deps/obs-deps/CI_BUILD/obsdeps/include/
}


build_729cd2ea-8fcd-47ee-ac56-b725825c93bd() {
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


build_3fd08d0c-b966-4942-bd0a-73bbad7a2f83() {
    step "Install dependency libx264"
    trap "caught_error 'Install dependency libx264'" ERR
    ensure_dir /home/runner/work/obs-deps/obs-deps/CI_BUILD/x264/build

    make install
}


build_6f4b0bcd-ec34-4a08-a8d9-7ff0a988433d() {
    step "Build dependency libx264 (dylib)"
    trap "caught_error 'Build dependency libx264 (dylib)'" ERR
    ensure_dir /home/runner/work/obs-deps/obs-deps/CI_BUILD/x264/build

    ../configure --extra-ldflags="-mmacosx-version-min=${MACOSX_DEPLOYMENT_TARGET}" --enable-shared --libdir="/tmp/obsdeps/bin" --prefix="/tmp/obsdeps"
    make -j
}


build_b8b7d727-7f1e-405b-925b-c33ad91243fb() {
    step "Install dependency libx264 (dylib)"
    trap "caught_error 'Install dependency libx264 (dylib)'" ERR
    ensure_dir /home/runner/work/obs-deps/obs-deps/CI_BUILD/x264/build

    ln -f -s libx264.*.dylib libx264.dylib
    find . -name \*.dylib -exec cp \{\} /home/runner/work/obs-deps/obs-deps/CI_BUILD/obsdeps/bin/ \;
    rsync -avh --include="*/" --include="*.h" --exclude="*" ../* /home/runner/work/obs-deps/obs-deps/CI_BUILD/obsdeps/include/
    rsync -avh --include="*/" --include="*.h" --exclude="*" ./* /home/runner/work/obs-deps/obs-deps/CI_BUILD/obsdeps/include/
}


build_f95090b3-c2c3-4754-8236-c8c57a9fcf61() {
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
    cmake -DCMAKE_INSTALL_PREFIX="/tmp/obsdeps" -DUSE_SHARED_MBEDTLS_LIBRARY=ON -DCMAKE_FIND_FRAMEWORK=LAST -DENABLE_PROGRAMS=OFF ..
    make -j${PARALLELISM}
}


build_d53bdd3e-6327-4314-be0f-5588f6e217d1() {
    step "Install dependency libmbedtls"
    trap "caught_error 'Install dependency libmbedtls'" ERR
    ensure_dir /home/runner/work/obs-deps/obs-deps/CI_BUILD/mbedtls-2.16.5/build

    make install
    find /tmp/obsdeps/lib -name libmbed\*.dylib -exec cp \{\} /home/runner/work/obs-deps/obs-deps/CI_BUILD/obsdeps/bin/ \;
    install_name_tool -id /tmp/obsdeps/bin/libmbedtls.12.dylib /home/runner/work/obs-deps/obs-deps/CI_BUILD/obsdeps/bin/libmbedtls.12.dylib
    install_name_tool -id /tmp/obsdeps/bin/libmbedcrypto.3.dylib /home/runner/work/obs-deps/obs-deps/CI_BUILD/obsdeps/bin/libmbedcrypto.3.dylib
    install_name_tool -id /tmp/obsdeps/bin/libmbedx509.0.dylib /home/runner/work/obs-deps/obs-deps/CI_BUILD/obsdeps/bin/libmbedx509.0.dylib
    install_name_tool -change libmbedtls.12.dylib /tmp/obsdeps/bin/libmbedtls.12.dylib /home/runner/work/obs-deps/obs-deps/CI_BUILD/obsdeps/bin/libmbedcrypto.3.dylib
    install_name_tool -change libmbedx509.0.dylib /tmp/obsdeps/bin/libmbedx509.0.dylib /home/runner/work/obs-deps/obs-deps/CI_BUILD/obsdeps/bin/libmbedx509.0.dylib
    install_name_tool -change libmbedcrypto.3.dylib /tmp/obsdeps/bin/libmbedcrypto.3.dylib /home/runner/work/obs-deps/obs-deps/CI_BUILD/obsdeps/bin/libmbedx509.0.dylib
    install_name_tool -change libmbedtls.12.dylib /tmp/obsdeps/bin/libmbedtls.12.dylib /home/runner/work/obs-deps/obs-deps/CI_BUILD/obsdeps/bin/libmbedtls.12.dylib
    install_name_tool -change libmbedx509.0.dylib /tmp/obsdeps/bin/libmbedx509.0.dylib /home/runner/work/obs-deps/obs-deps/CI_BUILD/obsdeps/bin/libmbedtls.12.dylib
    install_name_tool -change libmbedcrypto.3.dylib /tmp/obsdeps/bin/libmbedcrypto.3.dylib /home/runner/work/obs-deps/obs-deps/CI_BUILD/obsdeps/bin/libmbedtls.12.dylib
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


build_850a66bf-6484-4d88-b220-f735374b0404() {
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


build_c710525f-039f-42f3-a102-c6368f2f1608() {
    step "Install dependency libsrt"
    trap "caught_error 'Install dependency libsrt'" ERR
    ensure_dir /home/runner/work/obs-deps/obs-deps/CI_BUILD/srt-1.4.1/build

    make install
}


build_1a69c0df-b98b-4fce-8645-379031a7b01d() {
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


build_99bf9165-8e63-49d9-a261-1c40d0879719() {
    step "Install dependency ffmpeg"
    trap "caught_error 'Install dependency ffmpeg'" ERR
    ensure_dir /home/runner/work/obs-deps/obs-deps/CI_BUILD/FFmpeg-n4.2.2/build

    find . -name \*.dylib -exec cp \{\} /home/runner/work/obs-deps/obs-deps/CI_BUILD/obsdeps/bin/ \;
    rsync -avh --include="*/" --include="*.h" --exclude="*" ../* /home/runner/work/obs-deps/obs-deps/CI_BUILD/obsdeps/include/
    rsync -avh --include="*/" --include="*.h" --exclude="*" ./* /home/runner/work/obs-deps/obs-deps/CI_BUILD/obsdeps/include/
    install_name_tool -change libmbedcrypto.3.dylib /tmp/obsdeps/bin/libmbedcrypto.3.dylib /home/runner/work/obs-deps/obs-deps/CI_BUILD/obsdeps/bin/libavfilter.7.dylib
    install_name_tool -change libmbedcrypto.3.dylib /tmp/obsdeps/bin/libmbedcrypto.3.dylib /home/runner/work/obs-deps/obs-deps/CI_BUILD/obsdeps/bin/libavdevice.58.dylib
    install_name_tool -change libmbedcrypto.3.dylib /tmp/obsdeps/bin/libmbedcrypto.3.dylib /home/runner/work/obs-deps/obs-deps/CI_BUILD/obsdeps/bin/libavformat.58.dylib
    install_name_tool -change libmbedx509.0.dylib /tmp/obsdeps/bin/libmbedx509.0.dylib /home/runner/work/obs-deps/obs-deps/CI_BUILD/obsdeps/bin/libavfilter.7.dylib
    install_name_tool -change libmbedx509.0.dylib /tmp/obsdeps/bin/libmbedx509.0.dylib /home/runner/work/obs-deps/obs-deps/CI_BUILD/obsdeps/bin/libavdevice.58.dylib
    install_name_tool -change libmbedx509.0.dylib /tmp/obsdeps/bin/libmbedx509.0.dylib /home/runner/work/obs-deps/obs-deps/CI_BUILD/obsdeps/bin/libavformat.58.dylib
    install_name_tool -change libmbedtls.12.dylib /tmp/obsdeps/bin/libmbedtls.12.dylib /home/runner/work/obs-deps/obs-deps/CI_BUILD/obsdeps/bin/libavfilter.7.dylib
    install_name_tool -change libmbedtls.12.dylib /tmp/obsdeps/bin/libmbedtls.12.dylib /home/runner/work/obs-deps/obs-deps/CI_BUILD/obsdeps/bin/libavdevice.58.dylib
    install_name_tool -change libmbedtls.12.dylib /tmp/obsdeps/bin/libmbedtls.12.dylib /home/runner/work/obs-deps/obs-deps/CI_BUILD/obsdeps/bin/libavformat.58.dylib
}


build_3998d899-d1a5-49ad-b553-945aead582cb() {
    step "Build dependency libluajit"
    trap "caught_error 'Build dependency libluajit'" ERR
    ensure_dir /home/runner/work/obs-deps/obs-deps/CI_BUILD

    curl --retry 5 -L -C - -O https://luajit.org/download/LuaJIT-${LIBLUAJIT_VERSION}.tar.gz
    tar -xf LuaJIT-${LIBLUAJIT_VERSION}.tar.gz
    cd LuaJIT-${LIBLUAJIT_VERSION}
    mkdir build
    make PREFIX=/home/runner/work/obs-deps/obs-deps/CI_BUILD/LuaJIT-${LIBLUAJIT_VERSION}/build -j${PARALLELISM}
}


build_db082519-2a2e-4b6e-8d29-9e1fb9025a8e() {
    step "Install dependency libluajit"
    trap "caught_error 'Install dependency libluajit'" ERR
    ensure_dir /home/runner/work/obs-deps/obs-deps/CI_BUILD/LuaJIT-2.1.0-beta3

    make PREFIX=/home/runner/work/obs-deps/obs-deps/CI_BUILD/LuaJIT-${LIBLUAJIT_VERSION}/build install
    find ./build/lib -name libluajit\*.dylib -exec cp \{\} /home/runner/work/obs-deps/obs-deps/CI_BUILD/obsdeps/lib/ \;
    rsync -avh --include="*/" --include="*.h" --exclude="*" src/* /home/runner/work/obs-deps/obs-deps/CI_BUILD/obsdeps/include/
}


build_78f87b41-66fa-4a25-b563-7a5a91501b0f() {
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


build_66422ee7-931a-4d32-a5a4-165d22ceca2e() {
    step "Install dependency libfreetype"
    trap "caught_error 'Install dependency libfreetype'" ERR
    ensure_dir /home/runner/work/obs-deps/obs-deps/CI_BUILD/freetype-2.10.1/build

    make install
    find /tmp/obsdeps/lib -name libfreetype\*.dylib -exec cp \{\} /home/runner/work/obs-deps/obs-deps/CI_BUILD/obsdeps/lib/ \;
    rsync -avh --include="*/" --include="*.h" --exclude="*" ../include/* /home/runner/work/obs-deps/obs-deps/CI_BUILD/obsdeps/include/
    unset CFLAGS
}


build_e78bc660-4a1d-4be4-89b7-a36686ebce58() {
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

    build_b96545c3-fd65-4a2c-8033-5a8341d0f827
    build_c8ebcfb8-bf1f-4d9b-bbaa-52e191ba3269
    build_412dc87a-fb95-4b11-8ce0-1a0edd003834
    build_de21b3b3-8765-4148-ab13-5299df6b6082
    build_a1e48a03-667b-4bfd-95ba-08f8ec0f587a
    build_e61ca4f2-a119-4e3d-aee0-00fc047d6cbe
    build_06e7c257-51cd-4510-a294-c00def3a621d
    build_c6068e37-b1d4-41f3-b450-f8d4163cc7dc
    build_2d9e27c3-8c31-45b5-86d5-f8ad2f816dcf
    build_9b7b1cd0-7897-47cb-b875-5bf579dba029
    build_0a50357d-cad4-495f-8be6-4bdeae313244
    build_3f19fe04-fbae-46d4-8d36-4be912870f8e
    build_1a884933-24c0-4d2b-977b-22d946293634
    build_0a874bdd-8456-4f69-aac9-ebe738c641a7
    build_153a8285-7213-43b1-a7da-3e6ec66c64e5
    build_69c1cccd-879f-44ce-a45c-fe5fe7218dde
    build_950fece5-dddd-4ee6-80f5-f77979e6cc58
    build_729cd2ea-8fcd-47ee-ac56-b725825c93bd
    build_3fd08d0c-b966-4942-bd0a-73bbad7a2f83
    build_6f4b0bcd-ec34-4a08-a8d9-7ff0a988433d
    build_b8b7d727-7f1e-405b-925b-c33ad91243fb
    build_f95090b3-c2c3-4754-8236-c8c57a9fcf61
    build_d53bdd3e-6327-4314-be0f-5588f6e217d1
    build_850a66bf-6484-4d88-b220-f735374b0404
    build_c710525f-039f-42f3-a102-c6368f2f1608
    build_1a69c0df-b98b-4fce-8645-379031a7b01d
    build_99bf9165-8e63-49d9-a261-1c40d0879719
    build_3998d899-d1a5-49ad-b553-945aead582cb
    build_db082519-2a2e-4b6e-8d29-9e1fb9025a8e
    build_78f87b41-66fa-4a25-b563-7a5a91501b0f
    build_66422ee7-931a-4d32-a5a4-165d22ceca2e
    build_e78bc660-4a1d-4be4-89b7-a36686ebce58

    hr "All Done"
}

obs-deps-build-main $*