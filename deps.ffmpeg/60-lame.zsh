autoload -Uz log_debug log_error log_info log_status log_output

## Dependency Information
local name='lame'
local version='3.100'
local url='https://downloads.sourceforge.net/project/lame/lame/3.100/lame-3.100.tar.gz'
local hash="${0:a:h}/checksums/lame-3.100.tar.gz.sha256"
local -a patches=(
  "* ${0:a:h}/patches/lame/0001-remove-outdated-symbol.patch \
    d065b95e938652a6c219df7c9c057ba73e23e60fabb42cca633304ebed87a176"
  "windows ${0:a:h}/patches/lame/0002-enable-ldflags-support-for-shared-libs.patch \
    8beb0a98f15f8a0a935f9d68ad46aaa13cef9b24b2e34879201c81f39c72b5d8"
)

## Dependency Overrides
local targets=('macos-*' 'linux-*')

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

  local patch
  local _target
  local _url
  local _hash

  for patch (${patches}) {
    read _target _url _hash <<< "${patch}"

    if [[ "${target%%-*}" == ${~_target} ]] apply_patch "${_url}" "${_hash}"
  }
}

config() {
  autoload -Uz mkcd progress

  local cross_prefix
  case ${target} {
    macos-universal)
      autoload -Uz universal_config && universal_config
      return
      ;;
    macos-arm64) args+=(--host="arm-apple-darwin${target_config[darwin_target]}") ;;
    macos-x86_64) args+=(--host="x86_64-apple-darwin${target_config[darwin_target]}") ;;
    windows-x*) args+=(--host="${target_config[cross_prefix]}-w64-mingw32") ;;
  }

  log_info "Config (%F{3}${target}%f)"
  cd "${dir}"

  mkcd "build_${arch}"

  local _onoff=(disable enable)
  args+=(
    -C
    --disable-dependency-tracking
    --prefix="${target_config[output_dir]}"
    --enable-static
    --enable-nasm
    --disable-gtktest
    --disable-frontend
    "--${_onoff[(( shared_libs + 1 ))]}-shared"
  )

  case ${config} {
    Debug) args+=(--enable-debug=norm) ;;
    RelWithDebInfo) args+=(--disable-debug) ;;
    Release|MinSizeRel) args+=(--disable-debug) ;;
  }

  log_debug "Configure options: ${args}"
  CFLAGS="${c_flags}" \
  LDFLAGS="${ld_flags}" \
  PKG_CONFIG_LIBDIR="${target_config[output_dir]}/lib/pkgconfig" \
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

  log_info "Install (%F{3}${target}%f)"

  cd "${dir}/build_${arch}"

  if [[ "${config}" =~ "Release|MinSizeRel" ]] {
    progress make install-strip
  } else {
    progress make install
  }
}

fixup() {
  cd "${dir}"

  if (( shared_libs )) {
    local strip_tool
    local -a strip_files

    log_info "Fixup (%F{3}${target}%f)"
    case ${target} {
      macos*)
        autoload -Uz fix_rpaths
        fix_rpaths "${target_config[output_dir]}"/lib/libmp3lame*.dylib(.)
        ;;
      windows-x*)
        autoload -Uz create_importlibs
        create_importlibs "${target_config[output_dir]}"/bin/libmp3lame*.dll(.)
        ;;
    }
  }
}
