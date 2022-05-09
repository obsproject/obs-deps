autoload -Uz log_debug log_error log_info log_status log_output

## Dependency Information
local name='ntv2'
local version='16.2'
local url='https://github.com/aja-video/ntv2.git'
local hash='0acbac70a0b5e6509cca78cfbf69974c73c10db9'

## Dependency Overrides
local -i force_static=1

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

config() {
  autoload -Uz mkcd progress

  log_info "Config (%F{3}${target}%f)"

  if (( shared_libs )) {
    local shared=$(( shared_libs - force_static ))
  } else {
    local shared=0
  }
  local _onoff=(OFF ON)

  args=(
    ${cmake_flags}
    -DAJA_BUILD_OPENSOURCE=ON
    -DAJA_BUILD_APPS=OFF
    -DAJA_INSTALL_SOURCES=OFF
    -DAJA_INSTALL_HEADERS=ON
    -DAJA_BUILD_SHARED="${_onoff[(( shared + 1 ))]}"
  )

  cd "${dir}"
  log_debug "CMake configure options: ${args}"
  progress cmake -S . -B "build_${arch}" -G Ninja ${args}
}

build() {
  autoload -Uz mkcd

  log_info "Build (%F{3}${target}%f)"

  cd "${dir}"
  cmake --build "build_${arch}" --config "${config}"
}

install() {
  autoload -Uz progress

  log_info "Install (%F{3}${target}%f)"

  args=(
    --install "build_${arch}"
    --config "${config}"
  )

  if [[ "${config}" =~ "Release|MinSizeRel" ]] args+=(--strip)

  cd "${dir}"
  progress cmake ${args}
}
