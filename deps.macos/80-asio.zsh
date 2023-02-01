autoload -Uz log_debug log_error log_info log_status log_output

## Dependency Information
local name='asio'
local version='1.12.1'
local url='https://github.com/chriskohlhoff/asio.git'
local hash='b73dc1d2c0ecb9452a87c26544d7f71e24342df6'

## Build Steps
setup() {
  log_info "Setup (%F{3}${target}%f)"
  setup_dep ${url} ${hash}
}

install() {
  autoload -Uz progress

  log_info "Install (%F{3}${target}%f)"
  cd "${dir}/asio"

  mkdir -p ${target_config[output_dir]}/include

  log_debug "Copying headers to ${target_config[output_dir]}/include"
  cp -R include/(asio|asio.hpp) "${target_config[output_dir]}/include"
  log_status "Copied headers to ${target_config[output_dir]}/include"
}
