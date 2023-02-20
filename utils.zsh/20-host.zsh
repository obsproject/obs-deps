_setup_macos() {
  autoload -Uz check_macos check_homebrew check_git check_cmake

  check_macos
  check_homebrew
  check_git
  check_cmake

  local -i _capture_error=0
  typeset -g project_root=$(git rev-parse --show-toplevel 2>/dev/null) || _capture_error=1

  if (( _capture_error > 0 )) {
    log_warning "Not running in a git repository, interpreting project root instead"
    project_root="${funcfiletrace[1]:A:h}"
  }

  typeset -g work_root="${project_root}/${target%%-*}_build_temp"
  log_debug "work_root set to ${work_root}"

  if (( ! (${skips[(Ie)all]} + ${skips[(Ie)deps]}) )) {
    log_debug "Running brew bundle to install build dependencies"
    local -a _brew_params=(
      bundle --file "${project_root}"/.Brewfile
    )

    if (( _loglevel == 0 )) _brew_params+='--quiet'

    log_status "Installing required build dependencies..."
    brew ${_brew_params}
    rehash
  }

  function cleanup {
    unset CC
    unset CXX
    unset MACOSX_DEPLOYMENT_TARGET
    unset SDKROOT

    local -a restore_libs=(
      'xz lzma'
      zstd
      'libtiff tiff'
      webp
    )

    local lib lib_name lib_file
    for lib (${restore_libs}) {
      read -r lib_name lib_file <<< "${lib}"

      if ! [[ -d "${HOMEBREW_PREFIX}/opt/${lib_name}" && -h "${HOMEBREW_PREFIX}/lib/lib${lib_file:-${lib_name}}.dylib" ]] {
        brew link "${lib_name}"
      }
    }
  }
}

_setup_linux() {
  autoload -Uz is-at-least check_deps check_git check_nasm check_cross

  check_git

  local -i _capture_error=0
  typeset -g project_root=$(git rev-parse --show-toplevel 2>/dev/null) || _capture_error=1

  if (( _capture_error > 0 )) {
    log_warning "Not running in a git repository, interpreting project root instead"
    project_root="${funcfiletrace[1]:A:h}"
  }

  typeset -g work_root="${project_root}/${target%%-*}_build_temp"
  log_debug "work_root set to ${work_root}"

  if (( ! (${skips[(Ie)all]} + ${skips[(Ie)deps]}) )) {
    check_deps
    check_nasm

    if [[ ${target} == "windows-x"* ]] check_cross
    rehash
  }

  function cleanup {
    unset CC
    unset CXX

    if [[ ${target} =~ "windows-x*" ]] { autoload -Uz restore_dlls && restore_dlls }
  }
}

setup_host() {
  autoload -Uz log_status log_info log_warning log_debug
  case ${host_os} {
    macos) _setup_macos "$@" ;;
    linux) _setup_linux "$@" ;;
  }

  log_info "Checking for ccache..."

  if (( ${+commands[ccache]} )) {
    log_status "Ccache found"
    log_debug "Found ccache at ${commands[ccache]}"

    if (( ${+CI} )) {
      ccache --set-config=cache_dir="${GITHUB_WORKSPACE:-${HOME}}/.ccache"
      ccache --set-config=max_size="${CCACHE_SIZE:-500M}"
      ccache --set-config=compression=true
      ccache -z > /dev/null
    }
  } else {
    log_warning "No ccache found on the system"
  }
}

typeset -g host_os=${${(L)$(uname -s)}//darwin/macos}
