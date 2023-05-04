autoload -Uz log_debug log_error log_info log_status log_output

## Dependency Information
local name='nv-codec-headers'
local version='12.0.16'
local url='https://github.com/ffmpeg/nv-codec-headers.git'
local hash='c5e4af74850a616c42d39ed45b9b8568b71bf8bf'

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
