autoload -Uz log_debug log_error log_info log_status log_output

## Dependency Information
local name='Sparkle'
local version='2.3.2'
local url='https://github.com/sparkle-project/Sparkle/releases/download/2.3.2/Sparkle-2.3.2.tar.xz'
local hash="${0:a:h}/checksums/Sparkle-2.3.2.tar.xz.sha256"

## Build Steps
setup() {
  autoload -Uz dep_download extract mkcd

  log_info "Setup (%F{3}${target}%f)"
  log_info "Download ${url}"
  dep_download ${url} ${hash}

  if (( ! ${skips[(Ie)unpack]} )) {
    log_info "Extract ${url##*/}"
    mkcd ${dir}
    extract ../${url##*/}
  }
}

install() {
  log_info "Install (%F{3}${target}%f)"

  cd "${dir}"
  cp -Rp  Sparkle.framework "${target_config[output_dir]}"/lib
  cp -Rp  Symbols/Sparkle.framework.dSYM "${target_config[output_dir]}"/lib
}
