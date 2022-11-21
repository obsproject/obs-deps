autoload -Uz log_debug log_error log_info log_status log_output

## Dependency Information
local name='x264'
local -A versions=(
  macos r3101
  linux r3101
  windows r3101
)
local url='https://github.com/mirror/x264.git'
local -A hashes=(
  macos b093bbe7d9bc642c8f24067cbdcc73bb43562eab
  linux b093bbe7d9bc642c8f24067cbdcc73bb43562eab
  windows b093bbe7d9bc642c8f24067cbdcc73bb43562eab
)

## Dependency Overrides
local script_order=${${(s:-:)0:t:r}[1]}

if (( script_order < 99 )) {
  if [[ ${target} =~ 'windows'* ]] {
    local -i shared_libs=0
  } else {
    local -i shared_libs=1
  }
} else {
  local -a targets=('windows-x*')
  local -i shared_libs=1
  suffix="-shared"
}

## Build Steps
setup() {
  log_info "Setup (%F{3}${target}%f)"
  setup_dep ${url} ${hash}
}

clean() {
  cd "${dir}"

  if [[ ${clean_build} -gt 0 && -f "build_${arch}${suffix:-}/Makefile" ]] {
    log_info "Clean build directory (%F{3}${target}%f)"

    rm -rf "build_${arch}${suffix:-}${suffix:-}"
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
}

config() {
  autoload -Uz mkcd progress

  local cross_prefix
  case "${target}" {
    macos-universal)
      autoload -Uz universal_config && universal_config
      return
      ;;
    macos-arm64) args+=(--host="aarch64-apple-darwin${target_config[darwin_target]}") ;;
    macos-x86_64) args+=(--host="x86_64-apple-darwin${target_config[darwin_target]}") ;;
    windows-x*)
      args+=(
        --host="${target_config[cross_prefix]}-pc-mingw32"
        --cross-prefix="${target_config[cross_prefix]}-w64-mingw32-"
      )
      ;;
  }

  log_info "Config (%F{3}${target}%f)"
  cd "${dir}"

  mkcd "build_${arch}${suffix:-}"

  args+=(
    --prefix="${target_config[output_dir]}"
    --enable-static
    --enable-pic
    --disable-lsmash
    --disable-ffms
    --disable-avs
    --disable-gpac
    --disable-interlaced
    --disable-lavf
  )

  if (( shared_libs )) args+=(--enable-shared)
  if [[ ${config} == "Debug" ]] args+=(--enable-debug)

  log_debug "Configure options: ${args}"
  AS_FLAGS="$(if [[ ${target} == "macos-arm64" ]] print -- "${as_flags}")" \
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
  cd "${dir}/build_${arch}${suffix:-}"

  log_debug "Running make -j ${num_procs}"
  PATH="${(j.:.)cc_path}" progress make -j "${num_procs}"
}

install() {
  autoload -Uz progress

  log_info "Install (%F{3}${target}%f)"

  cd "${dir}/build_${arch}${suffix:-}"
  progress make install
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
        fix_rpaths "${target_config[output_dir]}"/lib/libx264*.dylib(.)

        strip_tool=strip
        strip_files=("${target_config[output_dir]}"/lib/libx264*.dylib(.))
        ;;
      linux-*)
        strip_tool=strip
        strip_files=("${target_config[output_dir]}"/lib/libx264.so.*(.))
        ;;
      windows-x*)
        autoload -Uz create_importlibs
        create_importlibs "${target_config[output_dir]}"/bin/libx264-*.dll(.)

        rm "${target_config[output_dir]}"/bin/x264.exe
        strip_tool=${target_config[cross_prefix]}-w64-mingw32-strip
        strip_files=("${target_config[output_dir]}"/bin/libx264-*.dll(.))
        mv "${target_config[output_dir]}"/lib/libx264-*.lib(.) "${target_config[output_dir]}"/lib/libx264.lib
        ;;
    }

    if [[ "${config}" == (Release|MinSizeRel) ]] {
      local file
      for file (${strip_files}(N)) {
        ${strip_tool} -x "${file}"
        log_status "Stripped ${file#"${target_config[output_dir]}"}"
      }
    }
  }
}
