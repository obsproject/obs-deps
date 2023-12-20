autoload -Uz log_debug log_error log_info log_status log_output

## Dependency Information
local name='libajantv2'
local version='17.0'
local url='https://github.com/aja-video/libajantv2.git'
local hash='08a5a3e7e5fce4abf7deb11567dfd795da4a4ba0'

## Dependency Overrides
local -i shared_libs=0

## Build Steps
setup() {
  log_info "Setup (%F{3}${target}%f)"
  setup_dep ${url} ${hash}
}

clean() {
  cd ${dir}

  if [[ ${clean_build} -gt 0 && -d build_${arch} ]] {
    log_info "Clean build directory (%F{3}${target}%f)"

    rm -rf build_${arch}
  }
}

config() {
  autoload -Uz mkcd progress

  log_info "Config (%F{3}${target}%f)"

  local _onoff=(OFF ON)

  args=(
    ${cmake_flags}
    -DAJANTV2_DISABLE_DEMOS:BOOL=ON
    -DAJANTV2_DISABLE_DRIVER:BOOL=ON
    -DAJANTV2_DISABLE_TESTS:BOOL=ON
    -DAJANTV2_DISABLE_TOOLS:BOOL=ON
    -DAJANTV2_DISABLE_PLUGINS:BOOL=ON
    -DAJA_INSTALL_SOURCES:BOOL=OFF
    -DAJA_INSTALL_HEADERS:BOOL=ON
    -DAJA_INSTALL_MISC:BOOL=OFF
    -DAJA_INSTALL_CMAKE:BOOL=OFF
    -DAJA_BUILD_SHARED:BOOL="${_onoff[(( shared_libs + 1 ))]}"
  )

  cd ${dir}
  log_debug "CMake configure options: ${args}"
  progress cmake -S . -B "build_${arch}" -G Ninja ${args}
}

build() {
  autoload -Uz mkcd

  log_info "Build (%F{3}${target}%f)"

  cd ${dir}
  cmake --build build_${arch} --config ${config}
}

install() {
  autoload -Uz progress

  log_info "Install (%F{3}${target}%f)"

  args=(
    --install build_${arch}
    --config ${config}
  )

  cd ${dir}
  progress cmake ${args}
}
