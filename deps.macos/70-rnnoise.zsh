autoload -Uz log_debug log_error log_info log_status log_output

## Dependency Information
local name='rnnoise'
local version='2020-07-28'
local url='https://github.com/xiph/rnnoise.git'
local hash='085d8f484af6141b1b88281a4043fb9215cead01'

## Build Steps
setup() {
  log_info "Setup (%F{3}${target}%f)"
  setup_dep ${url} ${hash}
}

clean() {
  cd "${dir}"

  if [[ ${clean_build} -gt 0 && -f "build_${arch}/Makefile" ]] {
    log_info "Clean build directory (%F{3}${target}%f)"

    rm -rf "build_${arch}"
  }
}

config() {
  autoload -Uz mkcd progress

  case ${target} in
    macos-universal)
      autoload -Uz universal_config && universal_config
      return
      ;;
    macos-*)
      args+=(--host="${arch}-apple-darwin${target_config[darwin_target]}")
      ;;
  esac

  log_info "Config (%F{3}${target}%f)"

  cd "${dir}"

  case "${target}" in
    macos-*)
      args+=(--host="${arch}-apple-darwin${target_config[darwin_target]}")
      ;;
  esac

  local _onoff=(disable enable)
  args+=(
    "--${_onoff[(( shared_libs + 1 ))]}-shared"
    -C
    --disable-dependency-tracking
    --prefix="${target_config[output_dir]}"
  )

  progress ./autogen.sh

  mkcd "build_${arch}"

  log_debug "Configure options: ${args}"
  CFLAGS="${c_flags}" \
  LDFLAGS="${ld_flags}" \
  PKG_CONFIG_PATH="${target_config[output_dir]}/lib/pkgconfig" \
  PATH="${(j.:.)cc_path}" \
  progress ../configure ${args}
}

build() {
  autoload -Uz mkcd progress

  case "${target}" in
    macos-universal)
      autoload -Uz universal_build && universal_build
      return
      ;;
  esac

  log_info "Build (%F{3}${target}%f)"

  cd "${dir}/build_${arch}"

  log_debug "Running 'make -j ${num_procs}'"
  PATH="${(j.:.)cc_path}" progress make -j "${num_procs}"
}

install() {
  autoload -Uz progress

  log_info "Install (%F{3}${target}%f)"

  cd "${dir}/build_${arch}"

  PATH="${(j.:.)cc_path}" progress make install

  if [[ "${config}" =~ "Release|MinSizeRel" && ${shared_libs} -eq 1 ]] {
    case ${target} {
      macos-*)
        local file
        for file ("${target_config[output_dir]}"/lib/librnnoise*.dylib) {
          if [[ ! -e "${file}" || -h "${file}" ]] continue
          strip -x "${file}"
          log_status "Stripped ${file#"${target_config[output_dir]}"}"
        }
        ;;
    }
  }
}

fixup() {
  autoload -Uz fix_rpaths

  cd "${dir}"

  case ${target} {
    macos*)
      if (( shared_libs )) {
        log_info "Fixup (%F{3}${target}%f)"
        fix_rpaths "${target_config[output_dir]}"/lib/librnnoise*.dylib
      }
      ;;
  }
}
