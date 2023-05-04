autoload -Uz log_debug log_error log_info log_status log_output

## Dependency Information
local name='freetype'
local version='2.13.0'
local url='https://downloads.sourceforge.net/project/freetype/freetype2/2.13.0/freetype-2.13.0.tar.xz'
local hash="${0:a:h}/checksums/freetype-2.13.0.tar.xz.sha256"

local -i shared_libs=1

## Build Steps
setup() {
  log_info "Setup (%F{3}${target}%f)"
  setup_dep ${url} ${hash}
}

clean() {
  cd ${dir}

  if [[ ${clean_build} -gt 0 && -f build_${arch}/Makefile ]] {
    log_info "Clean build directory (%F{3}${target}%f)"

    rm -rf build_${arch}
  }
}

config() {
  autoload -Uz mkcd progress

  case ${target} {
    macos-universal)
      autoload -Uz universal_config && universal_config
      return
      ;;
    macos-*)
      args+=(--host="${arch}-apple-darwin${target_config[darwin_target]}")
      ;;
  }

  log_info "Config (%F{3}${target}%f)"
  cd ${dir}

  local _onoff=(disable enable)
  args+=(
    "--${_onoff[(( shared_libs + 1 ))]}-shared"
    --without-harfbuzz
    --without-brotli
    -C
    --prefix="${target_config[output_dir]}"
  )

  mkcd build_${arch}

  log_debug "Configure args: ${args}"
  CFLAGS="${c_flags}" \
  LDFLAGS="${ld_flags}" \
  PKG_CONFIG_PATH="${target_config[output_dir]}/lib/pkgconfig" \
  PATH="${(j.:.)cc_path}" \
  progress ../configure ${args}
}

build() {
  autoload -Uz mkcd progress

  case ${target} {
    macos-universal)
      autoload -Uz universal_build && universal_build
      return
      ;;
  }

  log_info "Build (%F{3}${target}%f)"

  cd ${dir}/build_${arch}

  log_debug "Running 'make -j ${num_procs}'"
  PATH="${(j.:.)cc_path}" progress make -j ${num_procs}
}

install() {
  autoload -Uz progress

  if [[ ! -d ${dir}/build_${arch} ]] {
    log_warning "No binaries for architecture ${arch} found, skipping installation"
    return
  }

  log_info "Install (%F{3}${target}%f)"

  cd ${dir}/build_${arch}

  PATH="${(j.:.)cc_path}" progress make install
}

fixup() {
  cd ${dir}

  if (( shared_libs )) {
    local -a dylib_files=(${target_config[output_dir]}/lib/libfreetype*.dylib(.))

    log_info "Fixup (%F{3}${target}%f)"
    autoload -Uz fix_rpaths && fix_rpaths ${dylib_files}

    if [[ ${config} == (Release|MinSizeRel) ]] {
      dsymutil ${dylib_files}
      strip -x ${dylib_files}
    }
  } else {
    rm ${target_config[output_dir]}/lib/libfreetype*.dylib(N)
  }
}
