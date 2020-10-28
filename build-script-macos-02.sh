#!/usr/bin/env bash

set -eE

PRODUCT_NAME="OBS Pre-Built Dependencies"
BASE_DIR="$(git rev-parse --show-toplevel)"

export COLOR_RED=$(tput setaf 1)
export COLOR_GREEN=$(tput setaf 2)
export COLOR_BLUE=$(tput setaf 4)
export COLOR_ORANGE=$(tput setaf 3)
export COLOR_RESET=$(tput sgr0)

export MAC_QT_VERSION="5.14.1"
export MAC_QT_HASH="6f17f488f512b39c2feb57d83a5e0a13dcef32999bea2e2a8f832f54a29badb8"
export LIBPNG_VERSION="1.6.37"
export LIBPNG_HASH="505e70834d35383537b6491e7ae8641f1a4bed1876dbfe361201fc80868d88ca"
export LIBOPUS_VERSION="1.3.1"
export LIBOPUS_HASH="65b58e1e25b2a114157014736a3d9dfeaad8d41be1c8179866f144a2fb44ff9d"
export LIBOGG_VERSION="1.3.4"
export LIBOGG_HASH="fe5670640bd49e828d64d2879c31cb4dde9758681bb664f9bdbf159a01b0c76e"
export LIBRNNOISE_VERSION="2020-07-28"
export LIBRNNOISE_HASH="90ec41ef659fd82cfec2103e9bb7fc235e9ea66c"
export LIBVORBIS_VERSION="1.3.7"
export LIBVORBIS_HASH="b33cc4934322bcbf6efcbacf49e3ca01aadbea4114ec9589d1b1e9d20f72954b"
export LIBVPX_VERSION="1.9.0"
export LIBVPX_HASH="d279c10e4b9316bf11a570ba16c3d55791e1ad6faa4404c67422eb631782c80a"
export LIBJANSSON_VERSION="2.13.1"
export LIBJANSSON_HASH="f4f377da17b10201a60c1108613e78ee15df6b12016b116b6de42209f47a474f"
export LIBX264_VERSION="r3018"
export LIBX264_HASH="db0d417728460c647ed4a847222a535b00d3dbcb"
export LIBMBEDTLS_VERSION="2.24.0"
export LIBMEDTLS_HASH="b5a779b5f36d5fc4cba55faa410685f89128702423ad07b36c5665441a06a5f3"
export LIBSRT_VERSION="1.4.2"
export LIBSRT_HASH="28a308e72dcbb50eb2f61b50cc4c393c413300333788f3a8159643536684a0c4"
export LIBTHEORA_VERSION="1.1.1"
export LIBTHEORA_HASH="b6ae1ee2fa3d42ac489287d3ec34c5885730b1296f0801ae577a35193d3affbc"
export FFMPEG_VERSION="4.3.1"
export FFMPEG_HASH="ad009240d46e307b4e03a213a0f49c11b650e445b1f8be0dda2a9212b34d2ffb"
export LIBLUAJIT_VERSION="2.1.0-beta3"
export LIBLUAJIT_HASH="1ad2e34b111c802f9d0cdf019e986909123237a28c746b21295b63c9e785d9c3"
export LIBFREETYPE_VERSION="2.10.4"
export LIBFREETYPE_HASH="86a854d8905b19698bbc8f23b860bc104246ce4854dcea8e3b0fb21284f75784"
export PCRE_VERSION="8.44"
export PCRE_HASH="19108658b23b3ec5058edc9f66ac545ea19f9537234be1ec62b714c84399366d"
export SWIG_VERSION="4.0.2"
export SWIG_HASH="d53be9730d8d58a16bf0cbd1f8ac0c0c3e1090573168bfa151b01eb47fa906fc"
export MACOSX_DEPLOYMENT_TARGET="10.13"
export PATH="/usr/local/opt/ccache/libexec:${PATH}"
export CURRENT_DATE="$(date +"%Y-%m-%d")"
export PKG_CONFIG_PATH="$PKG_CONFIG_PATH:/tmp/obsdeps/lib/pkgconfig"
export PARALLELISM="$(sysctl -n hw.ncpu)"
export FFMPEG_CHECKSUM="$FFMPEG_CHECKSUM"

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
    restore_brews
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

restore_brews() {
    if [ -d /usr/local/opt/xz ] && [ ! -f /usr/local/lib/liblzma.dylib ]; then
      brew link xz
    fi

    if [ -d /usr/local/opt/zstd ] && [ ! -f /usr/local/lib/libzstd.dylib ]; then
      brew link zstd
    fi

    if [ -d /usr/local/opt/libtiff ] && [ !  -f /usr/local/lib/libtiff.dylib ]; then
      brew link libtiff
    fi

    if [ -d /usr/local/opt/webp ] && [ ! -f /usr/local/lib/libwebp.dylib ]; then
      brew link webp
    fi
}

build_02_install_homebrew_dependencies() {
    step "Install Homebrew dependencies"
    trap "caught_error 'Install Homebrew dependencies'" ERR
    ensure_dir ${BASE_DIR}

    if [ -d /usr/local/opt/openssl@1.0.2t ]; then
        brew uninstall openssl@1.0.2t
        brew untap local/openssl
    fi
    
    if [ -d /usr/local/opt/python@2.7.17 ]; then
        brew uninstall python@2.7.17
        brew untap local/python2
    fi
    brew bundle
}


build_03_get_current_date() {
    step "Get Current Date"
    trap "caught_error 'Get Current Date'" ERR
    ensure_dir ${BASE_DIR}


}


build_04_build_environment_setup() {
    step "Build environment setup"
    trap "caught_error 'Build environment setup'" ERR
    ensure_dir ${BASE_DIR}

    mkdir -p CI_BUILD/obsdeps/bin
    mkdir -p CI_BUILD/obsdeps/include
    mkdir -p CI_BUILD/obsdeps/lib
    
    
}


build_06_build_dependency_qt() {
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
    
    ${BASE_DIR}/utils/safe_fetch "https://download.qt.io/official_releases/qt/$(echo "${MAC_QT_VERSION}" | cut -d "." -f -2)/${MAC_QT_VERSION}/single/qt-everywhere-src-${MAC_QT_VERSION}.tar.xz" "${MAC_QT_HASH}"
    tar -xf qt-everywhere-src-${MAC_QT_VERSION}.tar.xz
    if [ "${MAC_QT_VERSION}" = "5.14.1" ]; then
        cd qt-everywhere-src-${MAC_QT_VERSION}/qtbase
        ${BASE_DIR}/utils/apply_patch "https://github.com/qt/qtbase/commit/8e5d6b422136dcca51f2c18fddcf28016f5ab99a.patch?full_index=1" "943e5e69160a39bcda0e88289b27c95732db1a195f0cf211601f10f1a067e608"
        cd ..
    else
        cd qt-everywhere-src-${MAC_QT_VERSION}
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
    
    mv /tmp/obsdeps ${BASE_DIR}/CI_BUILD/obsdeps
    
    if [ -d /usr/local/opt/zstd ] && [ ! -f /usr/local/bin/zstd ]; then
      brew link zstd
    fi
}


build_07_package_dependencies() {
    step "Package dependencies"
    trap "caught_error 'Package dependencies'" ERR
    ensure_dir ${BASE_DIR}/CI_BUILD/obsdeps

    tar -czf macos-qt-${MAC_QT_VERSION}-${CURRENT_DATE}.tar.gz obsdeps
    if [ ! -d "${BASE_DIR}/macos" ]; then
      mkdir ${BASE_DIR}/macos
    fi
    mv macos-qt-${MAC_QT_VERSION}-${CURRENT_DATE}.tar.gz ${BASE_DIR}/macos
}


obs-deps-build-main() {
    ensure_dir ${BASE_DIR}

    build_02_install_homebrew_dependencies
    build_03_get_current_date
    build_04_build_environment_setup
    build_06_build_dependency_qt
    build_07_package_dependencies

    restore_brews

    hr "All Done"
}

obs-deps-build-main $*