#!/bin/bash

##############################################################################
# macOS Qt build script
##############################################################################
#
# This script file can be included in build scripts for macOS or run directly
#
##############################################################################

# Halt on errors
set -eE

_patch_product() {
    cd "${PRODUCT_FOLDER}"

    if [ -z "${SKIP_UNPACK}" ]; then
        step "Apply patches..."
        apply_patch "${CHECKOUT_DIR}/CI/patches/QTBUG-74606.patch" "6ba73e94301505214b85e6014db23b042ae908f2439f0c18214e92644a356638"
        apply_patch "${CHECKOUT_DIR}/CI/macos/patches/QTBUG-97855.patch" "d8620262ad3f689fdfe6b6e277ddfdd3594db3de9dbc65810a871f142faa9966"
        apply_patch "${CHECKOUT_DIR}/CI/macos/patches/QTBUG-90370.patch" "277b16f02f113e60579b07ad93c35154d7738a296e3bf3452182692b53d29b85"
        find . -type f -name "*.pro" -print0 | xargs -0 -I{} sh -c "echo '\n\nCONFIG += sdk_no_version_check' >> {}"
    fi
}

_build_product() {
    cd "${PRODUCT_FOLDER}"

    step "Hide undesired libraries from qt..."
    if [ -d /usr/local/opt/zstd ]; then
        brew unlink zstd
    fi

    if [ -d /usr/local/opt/libtiff ]; then
        brew unlink libtiff
    fi

    if [ -d /usr/local/opt/webp ]; then
        brew unlink webp
    fi

    BASE_DIR="$(pwd)"

    # This ideally would just be a `QMAKE_APPLE_DEVICE_ARCHS="x86_64 arm64"` build
    # but 5.15.2 falls over some AVX guards trying to build that way.
    # Instead we do the following:
    #   - build x86_64 and arm64 seperately
    #   - build some tools universal to allow cross compiling to work
    #   - lipo everything together

    if [ "${CURRENT_ARCH}" = "x86_64" ]; then
        OTHER_ARCH="arm64"
    else
        OTHER_ARCH="x86_64"
    fi

    BUILDER_HOST="_build_qt_${CURRENT_ARCH}"
    CONFIGURE_HOST="_configure_qt_${CURRENT_ARCH}"
    BUILDER_OTHER="_build_qt_${OTHER_ARCH}"
    CONFIGURE_OTHER="_configure_qt_${OTHER_ARCH}"

    if [ "${ARCH}" = "universal" ]; then
        ${CONFIGURE_HOST}
        ${BUILDER_HOST}

        ${CONFIGURE_OTHER}
        _prepare_cross_compile
        ${BUILDER_OTHER}
    elif [ "${ARCH}" != "${CURRENT_ARCH}" ]; then
        ${CONFIGURE_OTHER}
        _prepare_cross_compile
        ${BUILDER_OTHER}
    else
        ${CONFIGURE_HOST}
        ${BUILDER_HOST}
    fi

    step "Restore hidden libraries..."
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

_build_qt_x86_64() {
    cd "${BASE_DIR}/build_x86_64"

    step "Compile (x86_64)..."
    make -j${PARALLELISM}
}

_configure_qt_x86_64() {
    mkdir -p "${BASE_DIR}/build_x86_64"
    cd "${BASE_DIR}/build_x86_64"

    step "Configure (x86_64)..."
    ../configure ${CMAKE_CCACHE_OPTIONS:+-ccache} ${QMAKE_QUIET:+-silent}  \
        -release -opensource -confirm-license -system-zlib \
        -qt-libpng -qt-libjpeg -qt-freetype -qt-pcre \
        -nomake examples -nomake tests -no-glib \
        -skip qt3d -skip qtactiveqt -skip qtandroidextras -skip qtcharts -skip qtconnectivity -skip qtdatavis3d \
        -skip qtdeclarative -skip qtdoc -skip qtgamepad -skip qtgraphicaleffects -skip qtlocation \
        -skip qtscript -skip qtscxml -skip qtsensors -skip qtserialbus -skip qtspeech \
        -skip qttranslations -skip qtwayland -skip qtwebchannel -skip qtwebengine -skip qtwebglplugin \
        -skip qtwebsockets -skip qtwebview -skip qtwinextras -skip qtx11extras -skip qtxmlpatterns \
        --prefix="${BUILD_DIR}" -pkg-config -dbus-runtime QMAKE_APPLE_DEVICE_ARCHS="x86_64"
}

_build_qt_arm64() {
    cd "${BASE_DIR}/build_arm64"

    step "Compile (arm64)..."
    make -j${PARALLELISM}
}

_configure_qt_arm64() {
    mkdir -p "${BASE_DIR}/build_arm64"
    cd "${BASE_DIR}/build_arm64"

    step "Configure (arm64)..."
    ../configure ${CMAKE_CCACHE_OPTIONS:+-ccache} ${QMAKE_QUIET:+-silent} \
        -release -opensource -confirm-license -system-zlib \
        -qt-libpng -qt-libjpeg -qt-freetype -qt-pcre \
        -nomake examples -nomake tests -no-glib \
        -skip qt3d -skip qtactiveqt -skip qtandroidextras -skip qtcharts -skip qtconnectivity -skip qtdatavis3d \
        -skip qtdeclarative -skip qtdoc -skip qtgamepad -skip qtgraphicaleffects -skip qtlocation \
        -skip qtscript -skip qtscxml -skip qtsensors -skip qtserialbus -skip qtspeech \
        -skip qttranslations -skip qtwayland -skip qtwebchannel -skip qtwebengine -skip qtwebglplugin \
        -skip qtwebsockets -skip qtwebview -skip qtwinextras -skip qtx11extras -skip qtxmlpatterns \
        --prefix="${BUILD_DIR}" -pkg-config -dbus-runtime QMAKE_APPLE_DEVICE_ARCHS="arm64"
}

_prepare_cross_compile() {
    if [ ! -f "${BASE_DIR}/build_${CURRENT_ARCH}/qtbase/lib/QtCore.framework/Versions/5/QtCore" ]; then
        step "Build QtCore framework (${CURRENT_ARCH})..."

        CONFIGURATOR="_configure_qt_${CURRENT_ARCH}"
        ${CONFIGURATOR}

        cd "${BASE_DIR}/build_${CURRENT_ARCH}"
        make -j${PARALLELISM} module-qtbase-qmake_all

        cd "${BASE_DIR}/build_${CURRENT_ARCH}/qtbase/src/"
        make -j${PARALLELISM} sub-moc-all
        make -j${PARALLELISM} sub-corelib
    fi

    cd "${BASE_DIR}/build_${OTHER_ARCH}"

    # qmake is built thin by the configure script and we couldn't see a clean way to get it to build universal
    # so we'll build it again universal
    status "Fix up Qmake to enable building ${OTHER_ARCH} on ${CURRENT_ARCH} host"

    # Modify Makefile so we can pass in arch to compiler and linker
    step "Apply patches..."
    apply_patch "${CHECKOUT_DIR}/CI/macos/patches/qmake.patch" "4840e9104c2049228c307056d86e2d9f2464dedc761c02eb4494b602a3896ab6"

    step "Remove thin Qmake..."
    rm "${BASE_DIR}/build_${OTHER_ARCH}/qtbase/bin/qmake"
    cd "${BASE_DIR}/build_${OTHER_ARCH}/qtbase/qmake"
    rm *.o

    step "Build Qmake..."
    EXTRA_LFLAGS="-arch x86_64 -arch arm64" EXTRA_CXXFLAGS="-arch x86_64 -arch arm64" make -j${PARALLELISM} qmake

    # we need to build some tools universal so we can cross compile on x86 host
    cd "${BASE_DIR}/build_${OTHER_ARCH}"
    step "Built Qt build tools..."
    make -j${PARALLELISM} module-qtbase-qmake_all

    # Modify Makefiles so we can specify ARCHS
    step "Apply patches..."
    sed -i '.orig' "s/EXPORT_VALID_ARCHS =/EXPORT_VALID_ARCHS +=/" \
        ./qtbase/src/Makefile \
        ./qtbase/src/tools/bootstrap/Makefile \
        ./qtbase/src/tools/moc/Makefile \
        ./qtbase/src/tools/qvkgen/Makefile \
        ./qtbase/src/tools/rcc/Makefile \
        ./qtbase/src/tools/uic/Makefile \
        ./qtbase/src/tools/qlalr/Makefile

    step "Build Qt tools (part 1)..."
    cd "${BASE_DIR}/build_${OTHER_ARCH}/qtbase/src/"
    ARCHS="arm64 x86_64" EXPORT_VALID_ARCHS="arm64 x86_64" make -j${PARALLELISM} sub-moc-all

    # QtCore sadly does not build universal so we build it OTHER_ARCH and then lipo it then continue building all of the other tools we need
    step "Build QtCore framework..."
    make -j${PARALLELISM} sub-corelib

    step "Create universal QtCore framework..."
    if lipo -archs ../lib/QtCore.framework/Versions/5/QtCore | grep ${CURRENT_ARCH}; then
        lipo -remove ${CURRENT_ARCH} ../lib/QtCore.framework/Versions/5/QtCore -output ../lib/QtCore.framework/Versions/5/QtCore
    fi

    lipo -create "${BASE_DIR}/build_${CURRENT_ARCH}/qtbase/lib/QtCore.framework/Versions/5/QtCore" ../lib/QtCore.framework/Versions/5/QtCore -output ../lib/QtCore.framework/Versions/5/QtCore

    step "Build Qt tools (part 2)"
    ARCHS="arm64 x86_64" EXPORT_VALID_ARCHS="arm64 x86_64" make -j${PARALLELISM} sub-qvkgen-all sub-rcc sub-uic sub-qlalr
}

_install_product() {
    cd "${PRODUCT_FOLDER}/build_${ARCH}"

    step "Install (${ARCH})..."
    make install

    if [ "${ARCH}" = "universal" -o "${OTHER_ARCH}" = "${ARCH}" ]; then
        cp ../build_${OTHER_ARCH}/qtbase/bin/qmake "${BUILD_DIR}/bin/"
    fi
}

print_usage() {
    echo -e "Usage: ${0}\n" \
            "-h, --help                     : Print this help\n" \
            "-q, --quiet                    : Suppress most build process output\n" \
            "-v, --verbose                  : Enable more verbose build process output\n" \
            "-a, --architecture             : Specify build architecture (default: universal, alternative: x86_64 or arm64)\n" \
            "-s, --skip-dependency-checks   : Skip Homebrew dependency checks (default: off)\n" \
            "--skip-unpack                  : Skip unpacking of Qt archive (default: off)\n"
}

build-qt-main() {
    PRODUCT_NAME="${PRODUCT_NAME:-qt}"

    if [ -z "${_RUN_OBS_BUILD_SCRIPT}" ]; then
        CHECKOUT_DIR="$(/usr/bin/git rev-parse --show-toplevel)"
        source "${CHECKOUT_DIR}/CI/include/build_support.sh"
        source "${CHECKOUT_DIR}/CI/include/build_support_macos.sh"

        QMAKE_QUIET=TRUE
        while true; do
            case "${1}" in
                -h | --help ) print_usage; exit 0 ;;
                -q | --quiet ) export QUIET=TRUE; shift ;;
                -v | --verbose ) export VERBOSE=TRUE; unset QMAKE_QUIET; shift ;;
                -a | --architecture ) ARCH="${2}"; shift 2 ;;
                -s | --skip-dependency-checks ) SKIP_DEP_CHECKS=TRUE; shift ;;
                --skip-unpack ) SKIP_UNPACK=TRUE; shift ;;
                -- ) shift; break ;;
                * ) break ;;
            esac
        done

        _build_checks
    fi

    BUILD_DIR="${BUILD_DIR/dependencies-/dependencies-qt-}"

    PRODUCT_URL="https://download.qt.io/official_releases/qt/$(echo "${PRODUCT_VERSION:-${CI_PRODUCT_VERSION}}" | cut -d "." -f -2)/${PRODUCT_VERSION:-${CI_PRODUCT_VERSION}}/single/qt-everywhere-src-${PRODUCT_VERSION:-${CI_PRODUCT_VERSION}}.tar.xz"
    PRODUCT_FILENAME="$(basename "${PRODUCT_URL}")"
    PRODUCT_FOLDER="${PRODUCT_FILENAME%.*.*}"

    _build_setup
    _build
}

build-qt-main $*
