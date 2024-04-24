autoload -Uz log_debug log_error log_info log_status log_output dep_checkout

## Dependency Information
local name='amf'
local version='1.4.33'
local url='https://github.com/GPUOpen-LibrariesAndSDKs/AMF.git'
local hash='e8c7cd7c10d4e05c1913aa8dfd2be9f9dbdb03d6'

## Dependency Overrides
local targets=('windows-x*')

## Build Steps
setup() {
  log_info "Setup (%F{3}${target}%f)"
  mkcd ${dir}
  dep_checkout ${url} ${hash} --sparse -- set amf/public/include
}

install() {
  autoload -Uz progress

  log_info "Install (%F{3}${target}%f)"

  cd ${dir}
  rsync -a amf/public/include/ ${target_config[output_dir]}/include/AMF
}
