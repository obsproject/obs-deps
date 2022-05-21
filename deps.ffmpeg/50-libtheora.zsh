autoload -Uz log_debug log_error log_info log_status log_output

## Dependency Information
local name='libtheora'
local -A versions=(
  macos 1.1.1
  linux 1.1.1
  windows 1.1.1
)
local -A urls=(
  macos https://ftp.osuosl.org/pub/xiph/releases/theora/libtheora-1.1.1.tar.xz
  linux https://ftp.osuosl.org/pub/xiph/releases/theora/libtheora-1.1.1.tar.xz
  windows https://github.com/xiph/theora.git
)
local -A hashes=(
  macos "${0:a:h}/checksums/libtheora-1.1.1.tar.xz.sha256"
  linux "${0:a:h}/checksums/libtheora-1.1.1.tar.xz.sha256"
  windows 7180717276af1ebc7da15c83162d6c5d6203aabf
)
local -a patches=(
  "macos ${0:a:h}/patches/libtheora/0001-fix-flat-namespace-on-big-sur.patch \
    83af02f2aa2b746bb7225872cab29a253264be49db0ecebb12f841562d9a2923"
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

    if [[ ${_target} == "${target%%-*}" ]] apply_patch "${_url}" "${_hash}"
  }

  if [[ ${target} = "windows-x"* ]] {
    sed -i -e 's/\r$//' win32/xmingw32/libtheoraenc-all.def
    sed -i -e 's/\r$//' win32/xmingw32/libtheoradec-all.def
  }
}

config() {
  autoload -Uz mkcd progress

  local cross_prefix
  case "${target}" {
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

  if [[ ${target} == "windows-x"* ]] progress ./autogen.sh

  mkcd "build_${arch}"

  local _onoff=(disable enable)
  args+=(
    -C
    --disable-dependency-tracking
    --prefix="${target_config[output_dir]}"
    --enable-static
    --with-pic
    --disable-oggtest
    --disable-vorbistest
    --disable-examples
    --disable-spec
    "--${_onoff[(( shared_libs + 1 ))]}-shared"
  )

  if [[ ${config} == "Debug" ]] args+=(--enable-debug)

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
        fix_rpaths "${target_config[output_dir]}"/lib/libtheora*.dylib(.)
        ;;
      windows-x*)
        autoload -Uz create_importlibs
        create_importlibs "${target_config[output_dir]}"/bin/libtheora*.dll(.)
        ;;
    }
  }
}
