autoload -Uz log_debug log_error log_info log_status log_output

## Dependency Information
local name='vlc'
local version='3.0.8'
local url='https://downloads.videolan.org/vlc/3.0.8/vlc-3.0.8.tar.xz'
local hash="${0:a:h}/checksums/vlc-3.0.8.tar.xz.sha256"

## Build Steps
setup() {
  log_info "Setup (%F{3}${target}%f)"
  setup_dep ${url} ${hash}
}

build() {
  autoload -Uz mkcd progress

  log_info "Build (%F{3}${target}%f)"

  cd "${dir}"

  local -a version_strings=(${(s:.:)version})

  sed -e "s/(@VERSION_MAJOR@)/(${version_strings[1]})/g" -e "s/(@VERSION_MINOR@)/(${version_strings[2]})/g" -e "s/(@VERSION_REVISION@)/(${version_strings[3]})/g" include/vlc/libvlc_version.h.in >! include/vlc/libvlc_version.h
}

install() {
  log_info "Install (%F{3}${target}%f)"

  cd "${dir}"
  cp -r include/vlc "${target_config[output_dir]}"/include
}
