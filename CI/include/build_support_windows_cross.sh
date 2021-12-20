#!/bin/bash

##############################################################################
# Windows cross-compile support functions
##############################################################################
#
# This script file can be included in build scripts for Windows.
#
##############################################################################

# Setup build environment

PARALLELISM="$(nproc)"
CI_WORKFLOW="${CHECKOUT_DIR}/.github/workflows/windows_deps.yml"

if [ "${TERM-}" -a -z "${CI}" ]; then
    COLOR_RED=$(/usr/bin/tput setaf 1)
    COLOR_GREEN=$(/usr/bin/tput setaf 2)
    COLOR_BLUE=$(/usr/bin/tput setaf 4)
    COLOR_ORANGE=$(/usr/bin/tput setaf 3)
    COLOR_RESET=$(/usr/bin/tput sgr0)
else
    COLOR_RED=""
    COLOR_GREEN=""
    COLOR_BLUE=""
    COLOR_ORANGE=""
    COLOR_RESET=""
fi

## DEFINE UTILITIES ##
install_tools() {
    sudo apt ${QUIET:+--quiet} -y install automake cmake curl git libtool meson mingw-w64 mingw-w64-tools ninja-build pkg-config wget yasm
    check_and_fetch 'https://www.nasm.us/pub/nasm/releasebuilds/2.15.01/nasm-2.15.01.tar.xz' '28a50f80d2f4023e444b113e9ddc57fcec2b2f295a07ce158cf3f18740375831'

    tar -xf nasm-2.15.01.tar.xz
    cd ./nasm-2.15.01
    ./configure
    make
    sudo make install
}

check_curl() {
    CURLCMD="curl"

    if [ "${CI}" -o "${QUIET}" ]; then
        export CURLCMD="${CURLCMD} --silent --show-error --location -O"
    else
        export CURLCMD="${CURLCMD} --progress-bar --location --continue-at - -O"
    fi
}

check_archs() {
    step "Check Architecture..."
    ARCH="${ARCH:-${CURRENT_ARCH}}"
    if [ "${ARCH}" = "x86" ]; then
        CMAKE_ARCHS="x86"
        WIN_CROSS_ARCH_DIR="win32"
        WIN_CROSS_TOOL_PREFIX="i686"
        WIN_CROSS_MVAL="i386"
        WIN_CROSS_TARGET="x86"
        WIN_CROSS_GCC_TARGET="x86-win32-gcc"
    elif [ "${ARCH}" = "x86_64" ]; then
        CMAKE_ARCHS="x86_64"
        WIN_CROSS_ARCH_DIR="win64"
        WIN_CROSS_TOOL_PREFIX="x86_64"
        WIN_CROSS_MVAL="i386:x86-64"
        WIN_CROSS_TARGET="x86_64"
        WIN_CROSS_GCC_TARGET="x86_64-win64-gcc"
    else
        caught_error "Unsupported architecture '${ARCH}' provided"
    fi
}

cleanup() {
    unset LDFLAGS
    unset CFLAGS
    unset LD_LIBRARY_PATH
}

## DEFINE TEMPLATES ##
_add_ccache_to_path() {
    if [ "${CMAKE_CCACHE_OPTIONS}" ]; then
        PATH="/usr/bin/ccache:${PATH}"
        status "Compiler Info:"
        local IFS=$'\n'
        for COMPILER_INFO in $(type cc c++ gcc g++ clang clang++ || true); do
            info "${COMPILER_INFO}"
        done
    fi
}

_print_usage() {
    echo -e "Usage: ${0}\n" \
            "-h, --help                     : Print this help\n" \
            "-q, --quiet                    : Suppress most build process output\n" \
            "-v, --verbose                  : Enable more verbose build process output\n" \
            "-a, --architecture             : Specify build architecture (default: host arch, alternatives: x86, x86_64)\n" \
            "-s, --skip-dependency-checks   : Skip dependency checks (default: off)\n"

    if [ -z _RUN_OBS_BUILD_SCRIPT ]; then
        echo -e "-i, --install                  : Run installation (default: off)\n"
    fi
}

_check_parameters() {
    while true; do
        case "${1}" in
            -h | --help ) _print_usage ; exit 0 ;;
            -q | --quiet ) export QUIET=TRUE; shift ;;
            -v | --verbose ) export VERBOSE=TRUE; shift ;;
            -a | --architecture ) ARCH="${2}"; shift 2 ;;
            -s | --skip-dependency-checks ) SKIP_DEP_CHECKS=TRUE; shift ;;
            -i | --install ) INSTALL=TRUE; shift ;;
            -- ) shift; break ;;
            * ) break ;;
        esac
    done
}

_build_checks() {
    PRODUCT_NAME_U="$(echo ${PRODUCT_NAME} | tr [a-z] [A-Z])"
    CI_PRODUCT_VERSION=$(/bin/cat "${CI_WORKFLOW}" | /bin/sed '/windows-deps-build-cross-compile/,/defaults:/!d' | /bin/sed -En "s/[ ]+${PRODUCT_NAME_U}_VERSION: '(.+)'/\1/p")
    CI_PRODUCT_HASH=$(/bin/cat "${CI_WORKFLOW}" | /bin/sed '/windows-deps-build-cross-compile/,/defaults:/!d' | /bin/sed -En "s/[ ]+${PRODUCT_NAME_U}_HASH: '([0-9a-f]+)'/\1/p")

    check_archs

    if [ -z "${INSTALL}" ]; then
        check_ccache
        check_curl

        if [ -z "${SKIP_DEP_CHECKS}" ]; then
            status "Installation of build dependencies"
            trap "caught_error 'install_dependencies'" ERR
            install_tools
        fi
    else
        ensure_dir "${CHECKOUT_DIR}/windows_cross_build_temp"
    fi

    BUILD_DIR="${CHECKOUT_DIR}/windows/obs-dependencies-${ARCH}"
    mkdir -p "${BUILD_DIR}/bin"
    mkdir -p "${BUILD_DIR}/include"
    mkdir -p "${BUILD_DIR}/lib"
    mkdir -p "${BUILD_DIR}/share"
}

_build_setup() {
    trap "caught_error 'build-${PRODUCT_NAME}'" ERR

    ensure_dir "${CHECKOUT_DIR}/windows_cross_build_temp"

    step "Download..."
    check_and_fetch "${PRODUCT_URL}" "${PRODUCT_HASH:-${CI_PRODUCT_HASH}}"

    if [ -z "${SKIP_UNPACK}" ]; then
        step "Unpack..."
        tar -xf ${PRODUCT_FILENAME}
    fi

    cd "${PRODUCT_FOLDER}"
}

_build_setup_git() {
    trap "caught_error 'build-${PRODUCT_NAME}'" ERR

    ensure_dir "${CHECKOUT_DIR}/windows_cross_build_temp"

    step "Git checkout..."
    mkdir -p "${PRODUCT_REPO}"
    cd "${PRODUCT_REPO}"
    github_fetch ${PRODUCT_PROJECT} ${PRODUCT_REPO} ${PRODUCT_HASH:-${CI_PRODUCT_HASH}} "$1"
}

_build() {
    status "Build ${PRODUCT_NAME} v${PRODUCT_VERSION:-${CI_PRODUCT_VERSION}}"

    if declare -f _patch_product $1 > /dev/null; then
        ensure_dir "${CHECKOUT_DIR}/windows_cross_build_temp"
        _patch_product
    fi

    if declare -f _build_product $1 > /dev/null; then
        ensure_dir "${CHECKOUT_DIR}/windows_cross_build_temp"
        _build_product
    fi

    if declare -f _install_product $1 > /dev/null; then
        ensure_dir "${CHECKOUT_DIR}/windows_cross_build_temp"
        _install_product
    fi
}
