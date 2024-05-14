autoload -Uz log_debug log_error log_info log_status log_output

## Dependency Information
local name='ntv2'
local version='17.0.1'
local url='https://github.com/aja-video/libajantv2.git'
local hash='b6acce6b135c3d9ae7a2bce966180b159ced619f'

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
    -DAJA_BUILD_SHARED="${_onoff[(( shared_libs + 1 ))]}"
    -DAJANTV2_DISABLE_DEMOS=ON
    -DAJANTV2_DISABLE_DRIVER=ON
    -DAJANTV2_DISABLE_TESTS=ON
    -DAJANTV2_DISABLE_TOOLS=ON
    -DAJANTV2_DISABLE_PLUGINS=ON
    -DAJA_INSTALL_SOURCES=OFF
    -DAJA_INSTALL_HEADERS=ON
    -DAJA_INSTALL_MISC=OFF
    -DAJA_INSTALL_CMAKE=OFF
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
