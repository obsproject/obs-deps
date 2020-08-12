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

build_731f3204-e7ea-4206-8378-9794efe4029b() {
    step "Install Homebrew dependencies"
    trap "caught_error 'Install Homebrew dependencies'" ERR
    ensure_dir ${BASE_DIR}

    brew update --preinstall
    brew bundle
}


build_7d848e22-0591-451e-bac4-e0b75ef3473d() {
    step "Get Current Date"
    trap "caught_error 'Get Current Date'" ERR
    ensure_dir ${BASE_DIR}


}


build_cf6816b8-3768-4076-8ee9-8dd072e4f6c8() {
    step "Build environment setup"
    trap "caught_error 'Build environment setup'" ERR
    ensure_dir ${BASE_DIR}

    mkdir -p CI_BUILD/obsdeps/bin
    mkdir -p CI_BUILD/obsdeps/include
    mkdir -p CI_BUILD/obsdeps/lib
    
    
}


build_43e9bba1-21ed-42f3-8e8a-3a6b701b1434() {
    step "Build dependency Qt"
    trap "caught_error 'Build dependency Qt'" ERR
    ensure_dir ${BASE_DIR}/CI_BUILD

    if [ -d /usr/local/opt/zstd ]; then
      brew unlink zstd
    fi
    
    if [ -d /usr/local/opt/libtiff ]; then
      brew unlink libtiff
    fi
    
    if [ -d /usr/local/opt/webp ]; then
      brew unlink webp
    fi
    
    curl --retry 5 -L -C - -O "https://download.qt.io/official_releases/qt/$(echo "${MAC_QT_VERSION}" | cut -d "." -f -2)/${MAC_QT_VERSION}/single/qt-everywhere-src-${MAC_QT_VERSION}.tar.xz"
    tar -xf qt-everywhere-src-${MAC_QT_VERSION}.tar.xz
    if [ "${MAC_QT_VERSION}" = "5.14.1" ]; then
        cd qt-everywhere-src-${MAC_QT_VERSION}/qtbase
        git apply ${BASE_DIR}/patch/qt/qtbase.patch
        cd ..
    fi
    mkdir build
    cd build
    if [ ! -n "${CI}" ]; then
      WITH_CCACHE=" -ccache"
    fi
    ../configure ${WITH_CCACHE} --prefix="/tmp/obsdeps" -release -opensource -confirm-license -system-zlib \
      -qt-libpng -qt-libjpeg -qt-freetype -qt-pcre -nomake examples -nomake tests -no-rpath -no-glib -pkg-config -dbus-runtime \
      -skip qt3d -skip qtactiveqt -skip qtandroidextras -skip qtcharts -skip qtconnectivity -skip qtdatavis3d \
      -skip qtdeclarative -skip qtdoc -skip qtgamepad -skip qtgraphicaleffects -skip qtlocation \
      -skip qtlottie -skip qtmultimedia -skip qtnetworkauth -skip qtpurchasing -skip qtquick3d \
      -skip qtquickcontrols -skip qtquickcontrols2 -skip qtquicktimeline -skip qtremoteobjects \
      -skip qtscript -skip qtscxml -skip qtsensors -skip qtserialbus -skip qtspeech \
      -skip qttranslations -skip qtwayland -skip qtwebchannel -skip qtwebengine -skip qtwebglplugin \
      -skip qtwebsockets -skip qtwebview -skip qtwinextras -skip qtx11extras -skip qtxmlpatterns
    make -j${PARALLELISM}
    make install
}


build_9a308b2f-5ecf-4808-aae5-3a9d110268cd() {
    step "Package dependencies"
    trap "caught_error 'Package dependencies'" ERR
    ensure_dir /tmp

    tar -czf macos-qt-${MAC_QT_VERSION}-${CURRENT_DATE}.tar.gz obsdeps
    if [ ! -d "${BASE_DIR}/macos" ]; then
      mkdir ${BASE_DIR}/macos
    fi
    mv macos-qt-${MAC_QT_VERSION}-${CURRENT_DATE}.tar.gz ${BASE_DIR}/macos
}


obs-deps-build-main() {
    ensure_dir ${BASE_DIR}

    build_731f3204-e7ea-4206-8378-9794efe4029b
    build_7d848e22-0591-451e-bac4-e0b75ef3473d
    build_cf6816b8-3768-4076-8ee9-8dd072e4f6c8
    build_43e9bba1-21ed-42f3-8e8a-3a6b701b1434
    build_9a308b2f-5ecf-4808-aae5-3a9d110268cd

    hr "All Done"
}

obs-deps-build-main $*