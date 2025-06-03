autoload -Uz log_debug log_error log_info log_status log_output

## Dependency Information
local name='uthash'
local version='2.3.0'
local url='https://github.com/troydhanson/uthash.git'
local hash='e493aa90a2833b4655927598f169c31cfcdf7861'

## Build Steps
setup() {
  log_info "Setup (%F{3}${target}%f)"
  setup_dep ${url} ${hash}
}

install() {
  autoload -Uz progress

  log_info "Install (%F{3}${target}%f)"
  cd ${dir}

  mkdir -p ${target_config[output_dir]}/include

  log_debug "Copying headers to ${target_config[output_dir]}/include"
  cp src/(utarray.h|uthash.h|utlist.h|utringbuffer.h|utstack.h|utstring.h) ${target_config[output_dir]}/include
  log_status "Copied headers to ${target_config[output_dir]}/include"
}
