autoload -Uz log_debug log_error log_info log_status log_output

## Dependency Information
local name='syphon'
local version='5.0'
local url='https://github.com/Syphon/Syphon-Framework.git'
local hash='fc4f4a2a71c0a8c7539a91093ad26c0c237602d6'

## Build Steps
setup() {
  log_info "Setup (%F{3}${target}%f)"
  setup_dep ${url} ${hash}
}

clean() {
  cd "${dir}"

  if [[ ${clean_build} -gt 0 && -d "build" ]] {
    log_info "Clean build directory (%F{3}${target}%f)"

    rm -rf "build"
  }
}

build() {
  autoload -Uz mkcd

  log_info "Build (%F{3}${target}%f)"

  cd "${dir}"
  xcodebuild -project Syphon.xcodeproj -target Syphon -configuration "${config}"
}

install() {
  log_info "Install (%F{3}${target}%f)"

  cd "${dir}"
  cp -Rp build/${config}/Syphon.framework "${target_config[output_dir]}"/lib
  cp -Rp build/${config}/Syphon.framework.dSYM "${target_config[output_dir]}"/lib
}
