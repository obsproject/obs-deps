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
export LIBVORBIS_VERSION="1.3.6"
export LIBVPX_VERSION="1.8.2"
export LIBJANSSON_VERSION="2.12"
export LIBX264_VERSION="origin/stable"
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

build_0a4989a8-6796-488f-8160-a2dcdad193e4() {
    step "Install Homebrew dependencies"
    trap "caught_error 'Install Homebrew dependencies'" ERR
    ensure_dir ${BASE_DIR}

    if [ -d /usr/local/opt/xz ]; then
      brew unlink xz
    fi
    brew update --preinstall
    brew bundle
}


build_40d02984-d6b8-4940-b579-eb67284ec652() {
    step "Get Current Date"
    trap "caught_error 'Get Current Date'" ERR
    ensure_dir ${BASE_DIR}


}


build_ad7b0dda-839b-4288-818a-aae0712c8461() {
    step "Build environment setup"
    trap "caught_error 'Build environment setup'" ERR
    ensure_dir ${BASE_DIR}

    mkdir -p CI_BUILD/obsdeps/bin
    mkdir -p CI_BUILD/obsdeps/include
    mkdir -p CI_BUILD/obsdeps/lib
    mkdir -p CI_BUILD/obsdeps/share
    
    
}


build_2979233c-d8fd-4d61-976a-c29ce8e01280() {
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


build_826608a7-e039-4bf1-99ef-389f00eff759() {
    step "Install dependency swig"
    trap "caught_error 'Install dependency swig'" ERR
    ensure_dir ${BASE_DIR}/CI_BUILD/swig-3.0.12/build

    cp swig ${BASE_DIR}/CI_BUILD/obsdeps/bin/
    mkdir -p ${BASE_DIR}/CI_BUILD/obsdeps/share/swig/${SWIG_VERSION}
    rsync -avh --include="*.i" --include="*.swg" --include="python" --include="lua" --include="typemaps" --exclude="*" ../Lib/* ${BASE_DIR}/CI_BUILD/obsdeps/share/swig/${SWIG_VERSION}
}


build_c17b3979-eb8e-45cd-87a4-4505c7273378() {
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


build_910a2944-968d-4003-b52a-81bb59e34484() {
    step "Install dependency libpng"
    trap "caught_error 'Install dependency libpng'" ERR
    ensure_dir ${BASE_DIR}/CI_BUILD/libpng-1.6.37/build

    make install
}


build_33c2488b-5c2e-4130-a94c-d904a406c29d() {
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


build_f3870bb6-d8f1-44a7-add6-522827f6e20d() {
    step "Install dependency libopus"
    trap "caught_error 'Install dependency libopus'" ERR
    ensure_dir ${BASE_DIR}/CI_BUILD/opus-1.3.1/build

    make install
}


build_ba40f7de-983e-4465-8320-6d28e0885e36() {
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


build_e46f556a-7203-48ac-858e-126722c9285c() {
    step "Install dependency libogg"
    trap "caught_error 'Install dependency libogg'" ERR
    ensure_dir ${BASE_DIR}/CI_BUILD/ogg-68ca3841567247ac1f7850801a164f58738d8df9/build

    make install
}


build_57cc997c-cf82-48b8-ab58-49aa1fb2ceb4() {
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


build_17c7ba90-1e31-467a-9845-a0ddc93c59e3() {
    step "Install dependency libvorbis"
    trap "caught_error 'Install dependency libvorbis'" ERR
    ensure_dir ${BASE_DIR}/CI_BUILD/libvorbis-1.3.6/build

    make install
}


build_da465091-a929-4d8d-b698-db58a262b121() {
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


build_94fbe109-e953-4ecb-91c0-bab281b47866() {
    step "Install dependency libvpx"
    trap "caught_error 'Install dependency libvpx'" ERR
    ensure_dir ${BASE_DIR}/CI_BUILD/libvpx-v1.8.2/build

    make install
}


build_359623d5-df1b-4d20-b430-84c6ee7c0b13() {
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


build_718c060e-4d57-4b82-86a9-394660c08673() {
    step "Install dependency libjansson"
    trap "caught_error 'Install dependency libjansson'" ERR
    ensure_dir ${BASE_DIR}/CI_BUILD/jansson-2.12/build

    find . -name \*.dylib -exec cp -PR \{\} ${BASE_DIR}/CI_BUILD/obsdeps/bin/ \;
    rsync -avh --include="*/" --include="*.h" --exclude="*" ../src/* ${BASE_DIR}/CI_BUILD/obsdeps/include/
    rsync -avh --include="*/" --include="*.h" --exclude="*" ./src/* ${BASE_DIR}/CI_BUILD/obsdeps/include/
    cp ./*.h ${BASE_DIR}/CI_BUILD/obsdeps/include/
}


build_90af06ab-992b-4463-bc0a-542a1462ea2e() {
    step "Build dependency libx264"
    trap "caught_error 'Build dependency libx264'" ERR
    ensure_dir ${BASE_DIR}/CI_BUILD

    if [ ! -d ./x264 ]; then git clone https://code.videolan.org/videolan/x264.git; fi
    cd ./x264
    git checkout ${LIBX264_VERSION}
    mkdir build
    cd ./build
    ../configure --extra-ldflags="-mmacosx-version-min=${MACOSX_DEPLOYMENT_TARGET}" --enable-static --prefix="/tmp/obsdeps"
    make -j${PARALLELISM}
}


build_0ea26975-bd91-46bc-b65f-d52b2e4fabc9() {
    step "Install dependency libx264"
    trap "caught_error 'Install dependency libx264'" ERR
    ensure_dir ${BASE_DIR}/CI_BUILD/x264/build

    make install
}


build_bb3c5a28-2608-486f-b0fd-979768412075() {
    step "Build dependency libx264 (dylib)"
    trap "caught_error 'Build dependency libx264 (dylib)'" ERR
    ensure_dir ${BASE_DIR}/CI_BUILD/x264/build

    ../configure --extra-ldflags="-mmacosx-version-min=${MACOSX_DEPLOYMENT_TARGET}" --enable-shared --libdir="/tmp/obsdeps/bin" --prefix="/tmp/obsdeps"
    make -j${PARALLELISM}
}


build_c2c6bb05-4a44-4237-9dee-e5cc20d312c9() {
    step "Install dependency libx264 (dylib)"
    trap "caught_error 'Install dependency libx264 (dylib)'" ERR
    ensure_dir ${BASE_DIR}/CI_BUILD/x264/build

    ln -f -s libx264.*.dylib libx264.dylib
    find . -name \*.dylib -exec cp -PR \{\} ${BASE_DIR}/CI_BUILD/obsdeps/bin/ \;
    rsync -avh --include="*/" --include="*.h" --exclude="*" ../* ${BASE_DIR}/CI_BUILD/obsdeps/include/
    rsync -avh --include="*/" --include="*.h" --exclude="*" ./* ${BASE_DIR}/CI_BUILD/obsdeps/include/
}


build_a40d9e7e-9378-41c4-892e-5f25b74abc25() {
    step "Build dependency libmbedtls"
    trap "caught_error 'Build dependency libmbedtls'" ERR
    ensure_dir ${BASE_DIR}/CI_BUILD

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


build_9cbfe050-4a62-485b-b342-3cb5a9b1bd40() {
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


build_2907c66a-43a0-4929-8958-bc61b0106f36() {
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


build_6421bc92-e46a-487b-a853-37e82206727e() {
    step "Install dependency libsrt"
    trap "caught_error 'Install dependency libsrt'" ERR
    ensure_dir ${BASE_DIR}/CI_BUILD/srt-1.4.1/build

    make install
}


build_c69e640a-d17c-46ef-b6aa-214100a6b239() {
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


build_da459f49-1e3e-49d4-b12e-ca14f5d61784() {
    step "Install dependency ffmpeg"
    trap "caught_error 'Install dependency ffmpeg'" ERR
    ensure_dir ${BASE_DIR}/CI_BUILD/FFmpeg-n4.2.2/build

    find . -name \*.dylib -exec cp -PR \{\} ${BASE_DIR}/CI_BUILD/obsdeps/bin/ \;
    rsync -avh --include="*/" --include="*.h" --exclude="*" ../* ${BASE_DIR}/CI_BUILD/obsdeps/include/
    rsync -avh --include="*/" --include="*.h" --exclude="*" ./* ${BASE_DIR}/CI_BUILD/obsdeps/include/
}


build_c79faf51-c188-4683-8077-e2eae8a9b068() {
    step "Build dependency libluajit"
    trap "caught_error 'Build dependency libluajit'" ERR
    ensure_dir ${BASE_DIR}/CI_BUILD

    curl --retry 5 -L -C - -O https://LuaJIT.org/download/LuaJIT-${LIBLUAJIT_VERSION}.tar.gz
    tar -xf LuaJIT-${LIBLUAJIT_VERSION}.tar.gz
    cd LuaJIT-${LIBLUAJIT_VERSION}
    make PREFIX="/tmp/obsdeps" -j${PARALLELISM}
}


build_dc332f90-c6a3-47e9-9f6d-d022c905a50c() {
    step "Install dependency libluajit"
    trap "caught_error 'Install dependency libluajit'" ERR
    ensure_dir ${BASE_DIR}/CI_BUILD/LuaJIT-2.1.0-beta3

    make PREFIX="/tmp/obsdeps" install
    find /tmp/obsdeps/lib -name libluajit\*.dylib -exec cp -PR \{\} ${BASE_DIR}/CI_BUILD/obsdeps/lib/ \;
    rsync -avh --include="*/" --include="*.h" --exclude="*" src/* ${BASE_DIR}/CI_BUILD/obsdeps/include/
    make PREFIX="/tmp/obsdeps" uninstall
}


build_980d57da-94be-4774-9090-416f86cdb0f7() {
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


build_24787232-b5c2-46f4-b3f3-24ac1fdd06e8() {
    step "Install dependency libfreetype"
    trap "caught_error 'Install dependency libfreetype'" ERR
    ensure_dir ${BASE_DIR}/CI_BUILD/freetype-2.10.1/build

    make install
    find /tmp/obsdeps/lib -name libfreetype\*.dylib -exec cp -PR \{\} ${BASE_DIR}/CI_BUILD/obsdeps/lib/ \;
    rsync -avh --include="*/" --include="*.h" --exclude="*" ../include/* ${BASE_DIR}/CI_BUILD/obsdeps/include/
    unset CFLAGS
}


build_a1445186-ff98-4925-acf8-5b6b6fa525bb() {
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

    build_0a4989a8-6796-488f-8160-a2dcdad193e4
    build_40d02984-d6b8-4940-b579-eb67284ec652
    build_ad7b0dda-839b-4288-818a-aae0712c8461
    build_2979233c-d8fd-4d61-976a-c29ce8e01280
    build_826608a7-e039-4bf1-99ef-389f00eff759
    build_c17b3979-eb8e-45cd-87a4-4505c7273378
    build_910a2944-968d-4003-b52a-81bb59e34484
    build_33c2488b-5c2e-4130-a94c-d904a406c29d
    build_f3870bb6-d8f1-44a7-add6-522827f6e20d
    build_ba40f7de-983e-4465-8320-6d28e0885e36
    build_e46f556a-7203-48ac-858e-126722c9285c
    build_57cc997c-cf82-48b8-ab58-49aa1fb2ceb4
    build_17c7ba90-1e31-467a-9845-a0ddc93c59e3
    build_da465091-a929-4d8d-b698-db58a262b121
    build_94fbe109-e953-4ecb-91c0-bab281b47866
    build_359623d5-df1b-4d20-b430-84c6ee7c0b13
    build_718c060e-4d57-4b82-86a9-394660c08673
    build_90af06ab-992b-4463-bc0a-542a1462ea2e
    build_0ea26975-bd91-46bc-b65f-d52b2e4fabc9
    build_bb3c5a28-2608-486f-b0fd-979768412075
    build_c2c6bb05-4a44-4237-9dee-e5cc20d312c9
    build_a40d9e7e-9378-41c4-892e-5f25b74abc25
    build_9cbfe050-4a62-485b-b342-3cb5a9b1bd40
    build_2907c66a-43a0-4929-8958-bc61b0106f36
    build_6421bc92-e46a-487b-a853-37e82206727e
    build_c69e640a-d17c-46ef-b6aa-214100a6b239
    build_da459f49-1e3e-49d4-b12e-ca14f5d61784
    build_c79faf51-c188-4683-8077-e2eae8a9b068
    build_dc332f90-c6a3-47e9-9f6d-d022c905a50c
    build_980d57da-94be-4774-9090-416f86cdb0f7
    build_24787232-b5c2-46f4-b3f3-24ac1fdd06e8
    build_a1445186-ff98-4925-acf8-5b6b6fa525bb

    hr "All Done"
}

obs-deps-build-main $*