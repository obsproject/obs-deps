autoload -Uz log_debug log_error log_info log_status log_output

## Dependency Information
local name='nv-codec-headers'
local version='12.1.14.0'
local url='https://github.com/ffmpeg/nv-codec-headers.git'
local hash='1889e62e2d35ff7aa9baca2bceb14f053785e6f1'

## Dependency Overrides
local targets=('windows-x*')

## Build Steps
setup() {
  log_info "Setup (%F{3}${target}%f)"
  setup_dep ${url} ${hash}
}

build() {
  autoload -Uz mkcd progress

  log_info "Build (%F{3}${target}%f)"
  cd ${dir}

  log_debug "Running make"
  make PREFIX="${target_config[output_dir]}"
}

install() {
  autoload -Uz progress

  log_info "Install (%F{3}${target}%f)"

  cd ${dir}

  make PREFIX="${target_config[output_dir]}" install
}
