autoload -Uz log_debug log_error log_info log_status log_output

## Dependency Information
local name='libogg'
local -A versions=(
  macos 1.3.5
  linux 1.3.5
  windows 1.3.5
)
local -A urls=(
  macos https://github.com/xiph/ogg/releases/download/v1.3.5/libogg-1.3.5.tar.xz
  linux https://github.com/xiph/ogg/releases/download/v1.3.5/libogg-1.3.5.tar.xz
  windows https://github.com/xiph/ogg/releases/download/v1.3.5/libogg-1.3.5.tar.xz
)
local -A hashes=(
  macos "${0:a:h}/checksums/libogg-1.3.5.tar.xz.sha256"
  linux "${0:a:h}/checksums/libogg-1.3.5.tar.xz.sha256"
  windows "${0:a:h}/checksums/libogg-1.3.5.tar.xz.sha256"
)
local -a patches=(
  "windows ${0:a:h}/patches/libogg/0001-fix-library-output-name.patch \
    d03f003a186422247516022bd6d83fd7041c24bc8c0381ad9c43314b35c4c536"
)

## Build Steps
setup() {
  log_info "Setup (%F{3}${target}%f)"
  setup_dep ${url} ${hash}
}

clean() {
  cd "${dir}"

  if [[ ${clean_build} -gt 0 && -d "build_${arch}" ]] {
    log_info "Clean build directory (%F{3}${target}%f)"

    rm -rf "build_${arch}"
  }
}

patch() {
  autoload -Uz apply_patch

  log_info "Patch (%F{3}${target}%f)"

  cd "${dir}"

  local patch
  local _target
  local _url
  local _hash
  for patch (${patches}) {
    read _target _url _hash <<< "${patch}"

    if [[ ${_target} == "${target%%-*}" ]] apply_patch "${_url}" "${_hash}"
  }
}

config() {
  autoload -Uz mkcd progress

  local _onoff=(OFF ON)

  args=(
    ${cmake_flags}
    -DINSTALL_DOCS=OFF
    -DBUILD_TESTING=OFF
    -DBUILD_SHARED_LIBS="${_onoff[(( shared_libs + 1 ))]}"
  )

  log_info "Config (%F{3}${target}%f)"
  cd "${dir}"
  log_debug "CMake configuration options: ${args}'"
  progress cmake -S . -B "build_${arch}" -G Ninja ${args}
}

build() {
  autoload -Uz mkcd progress

  log_info "Build (%F{3}${target}%f)"

  cd "${dir}"

  args=(
    --build "build_${arch}"
    --config "${config}"
  )

  if (( _loglevel > 1 )) args+=(--verbose)

  cmake ${args}
}

install() {
  autoload -Uz progress

  log_info "Install (%F{3}${target}%f)"

  args=(
    --install "build_${arch}"
    --config "${config}"
  )

  if [[ "${config}" =~ "Release|MinSizeRel" ]] args+=(--strip)
  if (( _loglevel > 1 )) args+=(--verbose)

  cd "${dir}"
  progress cmake ${args}
}

fixup() {
  cd "${dir}"

  case ${target} {
    macos-*|linux-*) rm -rf "${target_config[output_dir]}"/lib/cmake/Ogg ;;
    windows-*)
      if (( shared_libs )) {
        log_info "Fixup (%F{3}${target}%f)"
        autoload -Uz create_importlibs
        create_importlibs ${target_config[output_dir]}/bin/libogg*.dll
      }
      ;;
  }
}
