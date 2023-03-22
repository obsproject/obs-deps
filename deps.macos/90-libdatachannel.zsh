autoload -Uz log_debug log_error log_info log_status log_output

## Dependency Information
local name='libdatachannel'
local version='0.18.3'
local url='https://github.com/Sean-Der/libdatachannel.git'
local hash='bffcbeec9db0ba3f1493e0cf1398aa153b8a6682'

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

  args=(
    ${cmake_flags}
    -DUSE_MBEDTLS=1
    -DNO_WEBSOCKET=1
    -DNO_TESTS=1
    -DNO_EXAMPLES=1
    -DUSE_SYSTEM_MBEDTLS=1
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
