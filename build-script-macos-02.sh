#!/usr/bin/env bash

set -eE

PRODUCT_NAME="OBS Pre-Built Dependencies"
BASE_DIR="$(git rev-parse --show-toplevel)"

export COLOR_RED=$(tput setaf 1)
export COLOR_GREEN=$(tput setaf 2)
export COLOR_BLUE=$(tput setaf 4)
export COLOR_ORANGE=$(tput setaf 3)
export COLOR_RESET=$(tput sgr0)

export MAC_QT_VERSION="5.15.2"
export MAC_QT_HASH="3a530d1b243b5dec00bc54937455471aaa3e56849d2593edb8ded07228202240"
export LIBLAME_VERSION="3.100"
export LIBLAME_HASH="ddfe36cab873794038ae2c1210557ad34857a4b6bdc515785d1da9e175b1da1e"
export LIBPNG_VERSION="1.6.37"
export LIBPNG_HASH="505e70834d35383537b6491e7ae8641f1a4bed1876dbfe361201fc80868d88ca"
export LIBOPUS_VERSION="2021-05-12"
export LIBOPUS_HASH="dfd6c88aaa54a03a61434c413e30c217eb98f1d5"
export LIBOGG_VERSION="1.3.4"
export LIBOGG_HASH="fe5670640bd49e828d64d2879c31cb4dde9758681bb664f9bdbf159a01b0c76e"
export LIBRNNOISE_VERSION="2020-07-28"
export LIBRNNOISE_HASH="90ec41ef659fd82cfec2103e9bb7fc235e9ea66c"
export LIBVORBIS_VERSION="1.3.7"
export LIBVORBIS_HASH="b33cc4934322bcbf6efcbacf49e3ca01aadbea4114ec9589d1b1e9d20f72954b"
export LIBVPX_VERSION="1.10.0"
export LIBVPX_HASH="85803ccbdbdd7a3b03d930187cb055f1353596969c1f92ebec2db839fa4f834a"
export LIBJANSSON_VERSION="2.13.1"
export LIBJANSSON_HASH="f4f377da17b10201a60c1108613e78ee15df6b12016b116b6de42209f47a474f"
export LIBX264_VERSION="2021-05-05"
export LIBX264_HASH="b684ebe04a6f80f8207a57940a1fa00e25274f81"
export LIBMBEDTLS_VERSION="2.24.0"
export LIBMEDTLS_HASH="b5a779b5f36d5fc4cba55faa410685f89128702423ad07b36c5665441a06a5f3"
export LIBSRT_VERSION="1.4.3"
export LIBSRT_HASH="c06e05664c71d635c37207a2b5a444f2c4a95950a3548402b3e0c524f735b33d"
export LIBTHEORA_VERSION="1.1.1"
export LIBTHEORA_HASH="b6ae1ee2fa3d42ac489287d3ec34c5885730b1296f0801ae577a35193d3affbc"
export FFMPEG_VERSION="4.4"
export FFMPEG_HASH="06b10a183ce5371f915c6bb15b7b1fffbe046e8275099c96affc29e17645d909"
export LIBLUAJIT_VERSION="2.1"
export LIBLUAJIT_HASH="aa7ac6606872e4e21f92400d8491564ace10f259"
export LIBFREETYPE_VERSION="2.10.4"
export LIBFREETYPE_HASH="86a854d8905b19698bbc8f23b860bc104246ce4854dcea8e3b0fb21284f75784"
export SPEEXDSP_VERSION="1.2.0"
export SPEEXDSP_HASH="d7032f607e8913c019b190c2bccc36ea73fc36718ee38b5cdfc4e4c0a04ce9a4"
export PCRE_VERSION="8.44"
export PCRE_HASH="19108658b23b3ec5058edc9f66ac545ea19f9537234be1ec62b714c84399366d"
export SWIG_VERSION="4.0.2"
export SWIG_HASH="d53be9730d8d58a16bf0cbd1f8ac0c0c3e1090573168bfa151b01eb47fa906fc"
export MACOSX_DEPLOYMENT_TARGET="10.13"
export FFMPEG_REVISION="06"
export PKG_CONFIG_PATH="$PKG_CONFIG_PATH:/tmp/obsdeps/lib/pkgconfig"
export PATH="/usr/local/opt/ccache/libexec:${PATH}"
export CURRENT_DATE="$(date +"%Y-%m-%d")"
export CURRENT_ARCH="$(uname -m)"
export PARALLELISM="$(sysctl -n hw.ncpu)"
export FFMPEG_DEP_HASH="$FFMPEG_DEP_HASH"
export SDKROOT="$(xcrun --sdk macosx --show-sdk-path)"

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
    [[ -n "${1}" ]] && /bin/mkdir -p "${1}" && builtin cd "${1}"
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
    cleanup ${BASE_DIR}
    exit 1
}

restore_brews() {
    if [ -d /usr/local/opt/xz ] && [ ! -f /usr/local/lib/liblzma.dylib ]; then
      brew link xz
    fi

    if [ -d /usr/local/opt/sdl2 ] && ! [ -f /usr/local/lib/libSDL2.dylib ]; then
      brew link sdl2
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

build_03_install_homebrew_dependencies() {
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


build_04_get_current_date() {
    step "Get Current Date"
    trap "caught_error 'Get Current Date'" ERR
    ensure_dir ${BASE_DIR}


}


build_05_get_current_arch() {
    step "Get Current Arch"
    trap "caught_error 'Get Current Arch'" ERR
    ensure_dir ${BASE_DIR}


}


build_06_build_environment_setup() {
    step "Build environment setup"
    trap "caught_error 'Build environment setup'" ERR
    ensure_dir ${BASE_DIR}

    mkdir -p CI_BUILD/obsdeps/bin
    mkdir -p CI_BUILD/obsdeps/include
    mkdir -p CI_BUILD/obsdeps/lib
    
    
}


build_08_build_dependency_qt() {
    step "Build dependency Qt"
    trap "caught_error 'Build dependency Qt'" ERR
    ensure_dir ${BASE_DIR}/CI_BUILD

    if [ ! -f qt-everywhere-src-${MAC_QT_VERSION}.tar.xz ]; then
      ${BASE_DIR}/utils/safe_fetch "https://download.qt.io/official_releases/qt/$(echo "${MAC_QT_VERSION}" | cut -d "." -f -2)/${MAC_QT_VERSION}/single/qt-everywhere-src-${MAC_QT_VERSION}.tar.xz" "${MAC_QT_HASH}"
    fi
    tar -xf qt-everywhere-src-${MAC_QT_VERSION}.tar.xz
    if [ -d /usr/local/opt/zstd ]; then
      brew unlink zstd
    fi
    
    if [ -d /usr/local/opt/libtiff ]; then
      brew unlink libtiff
    fi
    
    if [ -d /usr/local/opt/webp ]; then
      brew unlink webp
    fi
    if [ "${MAC_QT_VERSION}" = "5.14.1" ]; then
        cd qt-everywhere-src-${MAC_QT_VERSION}/qtbase
        ${BASE_DIR}/utils/apply_patch "https://github.com/qt/qtbase/commit/8e5d6b422136dcca51f2c18fddcf28016f5ab99a.patch?full_index=1" "943e5e69160a39bcda0e88289b27c95732db1a195f0cf211601f10f1a067e608"
        cd ..
    else
        cd qt-everywhere-src-${MAC_QT_VERSION}/qtbase
        ${BASE_DIR}/utils/apply_patch "https://gist.githubusercontent.com/PatTheMav/e296886af7485d8cc85857ea4e99706b/raw/efa9f697c3b6332eeb58ce49aaccec2bb4a1674b/obs-issue-3799-qt.patch" "234ee6b21a008a233382c872ac097707ce83e401d3bcd5f1b244c09c0817f3aa"
        cd ..
    fi
    
    # This ideally would just be a `QMAKE_APPLE_DEVICE_ARCHS="x86_64 arm64"` build
    # but 5.15.2 falls over some AVX guards trying to build that way.
    # Instead we do the following:
    #   - build x86_64 and arm64 seperately
    #   - build some tools universal to allow cross compiling to work
    #   - lipo everything together
    
    rm -rf /tmp/qt_arm64 /tmp/qt_x86_64 /tmp/qt_universal
    
    mkdir build_x86_64
    cd build_x86_64
    ../configure --prefix="/tmp/qt_x86_64" -release -opensource -confirm-license -system-zlib \
      -qt-libpng -qt-libjpeg -qt-freetype -qt-pcre -nomake examples -nomake tests -no-rpath -no-glib -pkg-config -dbus-runtime \
      -skip qt3d -skip qtactiveqt -skip qtandroidextras -skip qtcharts -skip qtconnectivity -skip qtdatavis3d \
      -skip qtdeclarative -skip qtdoc -skip qtgamepad -skip qtgraphicaleffects -skip qtlocation \
      -skip qtlottie -skip qtmultimedia -skip qtnetworkauth -skip qtpurchasing -skip qtquick3d \
      -skip qtquickcontrols -skip qtquickcontrols2 -skip qtquicktimeline -skip qtremoteobjects \
      -skip qtscript -skip qtscxml -skip qtsensors -skip qtserialbus -skip qtspeech \
      -skip qttranslations -skip qtwayland -skip qtwebchannel -skip qtwebengine -skip qtwebglplugin \
      -skip qtwebsockets -skip qtwebview -skip qtwinextras -skip qtx11extras -skip qtxmlpatterns \
      QMAKE_APPLE_DEVICE_ARCHS="x86_64"
    make -j${PARALLELISM}
    make -j${PARALLELISM} install
    cd ..
    
    mkdir build_arm64
    cd build_arm64
    ../configure --prefix="/tmp/qt_arm64" -release -opensource -confirm-license -system-zlib \
      -qt-libpng -qt-libjpeg -qt-freetype -qt-pcre -nomake examples -nomake tests -no-rpath -no-glib -pkg-config -dbus-runtime \
      -skip qt3d -skip qtactiveqt -skip qtandroidextras -skip qtcharts -skip qtconnectivity -skip qtdatavis3d \
      -skip qtdeclarative -skip qtdoc -skip qtgamepad -skip qtgraphicaleffects -skip qtlocation \
      -skip qtlottie -skip qtmultimedia -skip qtnetworkauth -skip qtpurchasing -skip qtquick3d \
      -skip qtquickcontrols -skip qtquickcontrols2 -skip qtquicktimeline -skip qtremoteobjects \
      -skip qtscript -skip qtscxml -skip qtsensors -skip qtserialbus -skip qtspeech \
      -skip qttranslations -skip qtwayland -skip qtwebchannel -skip qtwebengine -skip qtwebglplugin \
      -skip qtwebsockets -skip qtwebview -skip qtwinextras -skip qtx11extras -skip qtxmlpatterns \
      QMAKE_APPLE_DEVICE_ARCHS="arm64"
    
    # qmake is built thin by the configure script and we couldn't see a clean way to get it to build universal
    # so we'll build it again universal
    rm qtbase/bin/qmake
    cd qtbase/qmake
    rm *.o
    # Modify Makefile so we can pass in arch to compiler and linker
    sed -i '.orig' -e "s/EXTRA_CXXFLAGS =/EXTRA_CXXFLAGS +=/" -e "s/EXTRA_LFLAGS =/EXTRA_LFLAGS +=/" Makefile
    EXTRA_LFLAGS="-arch x86_64 -arch arm64" EXTRA_CXXFLAGS="-arch x86_64 -arch arm64" make -j${PARALLELISM} qmake
    
    # we need to build some tools universal so we can cross compile on x86 host
    cd ../..
    make -j${PARALLELISM} module-qtbase-qmake_all
    cd qtbase/src/
    # Modify Makefiles so we can specify ARCHS
    sed -i '.orig' "s/EXPORT_VALID_ARCHS =/EXPORT_VALID_ARCHS +=/" Makefile ./tools/bootstrap/Makefile ./tools/moc/Makefile ./tools/qvkgen/Makefile ./tools/rcc/Makefile ./tools/uic/Makefile
    ARCHS="arm64 x86_64" EXPORT_VALID_ARCHS="arm64 x86_64" make -j${PARALLELISM} sub-moc-all
    # QtCore sadly does not build universal so we build it arm64 and then lipo it then continue building all of the other tools we need
    make sub-corelib
    lipo -create  ../../../build_x86_64/qtbase/lib/QtCore.framework/QtCore ../lib/QtCore.framework/QtCore -output ../lib/QtCore.framework/QtCore
    ARCHS="arm64 x86_64" EXPORT_VALID_ARCHS="arm64 x86_64" make -j${PARALLELISM} sub-qvkgen-all sub-rcc sub-uic
    
    cd ../..
    make -j${PARALLELISM}
    make -j${PARALLELISM} install
    
    # now its time to assemble universal
    cd ..
    WD=`pwd`
    cd /tmp/
    cp -R qt_arm64 qt_universal
    cd qt_universal
    # We find all the binary files that we need to lipo by using a perl one liner to read the first four bytes of each non-zero file and match the magic header for arm64 thin (cffaedfe)
    # Somehow qmake still ends up thin in the install step, so I give up and just copy in the universal one we made earlier
    find . -type f ! -size 0 | perl -ne '$test=`xxd -ps -l 4 $_`; $test =~ s/^\s+|\s+$//g; print $_ if ($test eq "cffaedfe")' | grep -v '.bin/qmake$' | xargs -I{} lipo -create "../qt_x86_64/{}" "../qt_arm64/{}" -output "{}"
    cp $WD/build_arm64/qtbase/bin/qmake ./bin/qmake
    
    # now copy the universal version into obsdeps
    cp -R . /tmp/obsdeps
    
    mv /tmp/obsdeps ${BASE_DIR}/CI_BUILD/obsdeps
    
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


build_09_package_dependencies() {
    step "Package dependencies"
    trap "caught_error 'Package dependencies'" ERR
    ensure_dir ${BASE_DIR}/CI_BUILD/obsdeps

    tar -czf macos-qt-${MAC_QT_VERSION}-universal-${CURRENT_DATE}.tar.gz obsdeps
    if [ ! -d "${BASE_DIR}/macos" ]; then
      mkdir ${BASE_DIR}/macos
    fi
    mv macos-qt-${MAC_QT_VERSION}-universal-${CURRENT_DATE}.tar.gz ${BASE_DIR}/macos
}


obs-deps-build-main() {
    ensure_dir ${BASE_DIR}

    build_03_install_homebrew_dependencies
    build_04_get_current_date
    build_05_get_current_arch
    build_06_build_environment_setup
    build_08_build_dependency_qt
    build_09_package_dependencies

    restore_brews

    hr "All Done"
}

obs-deps-build-main $*