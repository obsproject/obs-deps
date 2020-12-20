#!/usr/bin/env bash

set -eE

PRODUCT_NAME="OBS Pre-Built Dependencies"
BASE_DIR="$(git rev-parse --show-toplevel)"

export COLOR_RED=$(tput setaf 1)
export COLOR_GREEN=$(tput setaf 2)
export COLOR_BLUE=$(tput setaf 4)
export COLOR_ORANGE=$(tput setaf 3)
export COLOR_RESET=$(tput sgr0)

{environment}

hr() {{
     echo -e "${{COLOR_BLUE}}[${{PRODUCT_NAME}}] ${{1}}${{COLOR_RESET}}"
}}

step() {{
    echo -e "${{COLOR_GREEN}}  + ${{1}}${{COLOR_RESET}}"
}}

info() {{
    echo -e "${{COLOR_ORANGE}}  + ${{1}}${{COLOR_RESET}}"
}}

error() {{
     echo -e "${{COLOR_RED}}  + ${{1}}${{COLOR_RESET}}"
}}

exists() {{
    command -v "${{1}}" >/dev/null 2>&1
}}

ensure_dir() {{
    [[ -n ${{1}} ]] && /bin/mkdir -p ${{1}} && builtin cd ${{1}}
}}

cleanup() {{
    restore_brews
}}

mkdir() {{
    /bin/mkdir -p $*
}}

trap cleanup EXIT

caught_error() {{
    error "ERROR during build step: ${{1}}"
    cleanup ${workspace}
    exit 1
}}

restore_brews() {{
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
}}

{build_steps}

obs-deps-build-main() {{
    ensure_dir {workspace}

{call_build_steps}

    restore_brews

    hr "All Done"
}}

obs-deps-build-main $*