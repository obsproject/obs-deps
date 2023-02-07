autoload -Uz log_debug log_error log_info log_status log_output

## Dependency Information
local name='speexdsp'
local version='1.2.1'
local url='https://github.com/xiph/speexdsp/archive/SpeexDSP-1.2.1.tar.gz'
local hash="${0:a:h}/checksums/SpeexDSP-1.2.1.tar.gz.sha256"
local patches=(
  "${0:a:h}/patches/SpeexDSP/0001-enable-macOS-deployment-target.patch \
  218dbd70fef2020a39f6f4bb62c40dd4519a494d2a13b77e6e5b958f5e6115d4"
)

## Dependency Overrides
local dir="speexdsp-${${url##*/}%.*.*}"

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

patch() {
  autoload -Uz apply_patch

  log_info "Patch (%F{3}${target}%f)"
  cd "${dir}"

  case ${target} {
    macos-*)
      local patch
      for patch (${patches}) {
        local _url
        local _hash
        read _url _hash <<< "${patch}"
        apply_patch "${_url}" "${_hash}"
      }
      ;;
  }
}

config() {
  autoload -Uz mkcd progress

  case "${target}" {
    macos-universal)
      autoload -Uz universal_config && universal_config
      return
      ;;
    macos-*)
      args+=(--host="${arch}-apple-darwin${target_config[darwin_target]}")
      ;;
  }

  log_info "Config (%F{3}${target}%f)"
  cd "${dir}"

  progress ./autogen.sh

  mkcd "build_${arch}"

  args+=(
    -C
    --disable-dependency-tracking
    --prefix="${target_config[output_dir]}"
  )

  log_debug "Configure options: ${args}"
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
  cd "${dir}/build_${arch}"

  log_debug "Running make -j ${num_procs}"
  PATH="${(j.:.)cc_path}" progress make -j "${num_procs}"
}

install() {
  autoload -Uz progress

  if [[ ! -d "${dir}/build_${arch}" ]] {
    log_warning "No binaries for architecture ${arch} found, skipping installation"
    return
  }

  log_info "Install (%F{3}${target}%f)"
  cd "${dir}/build_${arch}"

  if [[ ${config} =~ "Release|MinSizeRel" ]] {
    progress make install-strip
  } else {
    progress make install
  }
}

fixup() {
  autoload -Uz fix_rpaths

  cd "${dir}"

  case ${target} {
    macos*)
      if (( shared_libs )) {
        log_info "Fixup (%F{3}${target}%f)"
        fix_rpaths "${target_config[output_dir]}"/lib/libspeexdsp*.dylib
      } else {
        rm "${target_config[output_dir]}"/lib/libspeexdsp*.dylib(N)
      }
      ;;
  }
}
