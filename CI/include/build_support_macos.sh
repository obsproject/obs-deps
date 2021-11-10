#!/bin/bash

##############################################################################
# macOS support functions
##############################################################################
#
# This script file can be included in build scripts for macOS.
#
##############################################################################

# Setup build environment

# Get fallback macOS deployment target from default workflow
CI_MACOSX_DEPLOYMENT_TARGET_X86_64=$(/bin/cat "${CI_WORKFLOW}" | /usr/bin/sed -En "s/[ ]+MACOSX_DEPLOYMENT_TARGET_X86_64: '([0-9\.]+)'/\1/p" | head -1)
CI_MACOSX_DEPLOYMENT_TARGET_ARM64=$(/bin/cat "${CI_WORKFLOW}" | /usr/bin/sed -En "s/[ ]+MACOSX_DEPLOYMENT_TARGET_ARM64: '([0-9\.]+)'/\1/p" | head -1)

# Ensure using the most recent macOS SDK
export SDKROOT=$(xcrun --sdk macosx --show-sdk-path)
PARALLELISM="$(sysctl -n hw.ncpu)"

MACOS_VERSION="$(/usr/bin/sw_vers -productVersion)"
MACOS_MAJOR="$(echo ${MACOS_VERSION} | /usr/bin/cut -d '.' -f 1)"
MACOS_MINOR="$(echo ${MACOS_VERSION} | /usr/bin/cut -d '.' -f 2)"

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
check_macos_version() {
    ARCH="${ARCH:-${CURRENT_ARCH}}"
    if [ "${ARCH}" = "x86_64" -o "${ARCH}" = "universal" ]; then
        CI_MACOSX_DEPLOYMENT_TARGET="${CI_MACOSX_DEPLOYMENT_TARGET_X86_64}"
    elif [ "${ARCH}" = "arm64" ]; then
        CI_MACOSX_DEPLOYMENT_TARGET="${CI_MACOSX_DEPLOYMENT_TARGET_ARM64}"
    else
        caught_error "Unsupported architecture '${ARCH}' provided"
    fi

    export MACOSX_DEPLOYMENT_TARGET="${MACOSX_DEPLOYMENT_TARGET:-${CI_MACOSX_DEPLOYMENT_TARGET}}"

    # Set Darwin version identifier based on MACOSX_DEPLOYMENT_TARGET
    if [ $(echo "${MACOSX_DEPLOYMENT_TARGET}" | cut -d "." -f 1) -lt 11 ]; then
        DARWIN_TARGET="$(($(echo ${MACOSX_DEPLOYMENT_TARGET} | cut -d "." -f 2)+4))"
    else
        DARWIN_TARGET="$(($(echo ${MACOSX_DEPLOYMENT_TARGET} | cut -d "." -f 1)+9))"
    fi

    step "Check macOS version..."
    MIN_VERSION=${MACOSX_DEPLOYMENT_TARGET}
    MIN_MAJOR=$(echo ${MIN_VERSION} | /usr/bin/cut -d '.' -f 1)
    MIN_MINOR=$(echo ${MIN_VERSION} | /usr/bin/cut -d '.' -f 2)

    if [ "${MACOS_MAJOR}" -lt "11" -a "${MACOS_MINOR}" -lt "${MIN_MINOR}" ]; then
        error "ERROR: Minimum required macOS version is ${MIN_VERSION}, but running on ${MACOS_VERSION}"
    fi

    if [ "${MACOS_MAJOR}" -ge "11" ]; then
        export CODESIGN_LINKER="ON"
    fi
}

install_homebrew_deps() {
    if ! exists brew; then
        caught_error "Homebrew not found - please install Homebrew (https://brew.sh)"
    fi

    brew bundle --file "${CHECKOUT_DIR}/CI/include/Brewfile" ${QUIET:+--quiet}

    check_curl
}

check_curl() {
    if [ "${MACOS_MAJOR}" -lt "11" -a "${MACOS_MINOR}" -lt "15" ]; then
        if [ ! -d /usr/local/opt/curl ]; then
            step "Install Homebrew curl..."
            brew install curl
        fi

        CURLCMD="/usr/local/opt/curl/bin/curl"
    else
        CURLCMD="curl"
    fi

    if [ "${CI}" -o "${QUIET}" ]; then
        export CURLCMD="${CURLCMD} --silent --show-error --location -O"
    else
        export CURLCMD="${CURLCMD} --progress-bar --location --continue-at - -O"
    fi
}

check_archs() {
    step "Check Architecture..."
    ARCH="${ARCH:-${CURRENT_ARCH}}"
    if [ "${ARCH}" = "universal" ]; then
        CMAKE_ARCHS="x86_64;arm64"
    elif [ "${ARCH}" != "x86_64" -a "${ARCH}" != "arm64" ]; then
        caught_error "Unsupported architecture '${ARCH}' provided"
    else
        CMAKE_ARCHS="${ARCH}"
    fi
}

cleanup() {
    if [ -d /usr/local/opt/xz -a ! -f /usr/local/lib/liblzma.dylib ]; then
        brew link xz
    fi

    if [ -d /usr/local/opt/sdl2 -a ! -f /usr/local/lib/libSDL2.dylib ]; then
        brew link sdl2
    fi

    if [ -d /usr/local/opt/zstd -a ! -f /usr/local/lib/libzstd.dylib ]; then
        brew link zstd
    fi

    if [ -d /usr/local/opt/libtiff -a ! -f /usr/local/lib/libtiff.dylib ]; then
        brew link libtiff
    fi

    if [ -d /usr/local/opt/webp -a ! -f /usr/local/lib/libwebp.dylib ]; then
        brew link webp
    fi

    unset MACOSX_DEPLOYMENT_TARGET
    unset LDFLAGS
    unset CFLAGS
    unset LD_LIBRARY_PATH
    unset CODESIGN_LINKER
    unset SDKROOT
}

## DEFINE TEMPLATES ##
_add_ccache_to_path() {
    if [ "${CMAKE_CCACHE_OPTIONS}" ]; then
        if [ "${CURRENT_ARCH}" == "arm64" ]; then
            PATH="/opt/homebrew/opt/ccache/libexec:${PATH}"
        else
            PATH="/usr/local/opt/ccache/libexec:${PATH}"
        fi
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
            "-a, --architecture             : Specify build architecture (default: host arch, alternatives: universal,x86_64, arm64)\n" \
            "-s, --skip-dependency-checks   : Skip Homebrew dependency checks (default: off)\n"

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
    CI_PRODUCT_VERSION=$(/bin/cat "${CI_WORKFLOW}" | /usr/bin/sed -En "s/[ ]+${PRODUCT_NAME_U}_VERSION: '(.+)'/\1/p")
    CI_PRODUCT_HASH=$(/bin/cat "${CI_WORKFLOW}" | /usr/bin/sed -En "s/[ ]+${PRODUCT_NAME_U}_HASH: '([0-9a-f]+)'/\1/p")

    check_archs
    check_macos_version

    if [ -z "${INSTALL}" ]; then
        check_ccache
        check_curl

        if [ -z "${SKIP_DEP_CHECKS}" ]; then
            status "Installation of Homebrew dependencies"
            trap "caught_error 'install_dependencies'" ERR
            install_homebrew_deps
        fi
    else
        ensure_dir "${CHECKOUT_DIR}/macos_build_temp"
    fi

    BUILD_DIR="${CHECKOUT_DIR}/macos/obs-dependencies-${ARCH}"
}

_build_setup() {
    trap "caught_error 'build-${PRODUCT_NAME}'" ERR

    ensure_dir "${CHECKOUT_DIR}/macos_build_temp"

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

    ensure_dir "${CHECKOUT_DIR}/macos_build_temp"

    step "Git checkout..."
    mkdir -p "${PRODUCT_REPO}-${PRODUCT_VERSION:-${CI_PRODUCT_VERSION}}"
    cd "${PRODUCT_REPO}-${PRODUCT_VERSION:-${CI_PRODUCT_VERSION}}"
    github_fetch ${PRODUCT_PROJECT} ${PRODUCT_REPO} ${PRODUCT_HASH:-${CI_PRODUCT_HASH}}""
}

_build() {
    status "Build ${PRODUCT_NAME} v${PRODUCT_VERSION:-${CI_PRODUCT_VERSION}}"

    if declare -f _patch_product $1 > /dev/null; then
        ensure_dir "${CHECKOUT_DIR}/macos_build_temp"
        _patch_product
    fi

    if declare -f _build_product $1 > /dev/null; then
        ensure_dir "${CHECKOUT_DIR}/macos_build_temp"
        _build_product
    fi

    if declare -f _install_product $1 > /dev/null; then
        ensure_dir "${CHECKOUT_DIR}/macos_build_temp"
        _install_product
    fi
}
