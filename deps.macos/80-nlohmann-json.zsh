autoload -Uz log_debug log_error log_info log_status log_output

## Dependency Information
local name='nlohmann-json'
local version='3.11.2'
local url='https://github.com/nlohmann/json.git'
local hash='bc889afb4c5bf1c0d8ee29ef35eaaf4c8bef8a5d'

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

  args=(
    ${cmake_flags}
    -DJSON_BuildTests=OFF
  )

  cd ${dir}
  log_debug "CMake configure options: ${args}"
  progress cmake -S . -B build_${arch} -G Ninja ${args}
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

  cd "${dir}"
  progress cmake ${args}
}
