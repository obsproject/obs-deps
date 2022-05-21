autoload -Uz log_debug log_error log_info log_status log_output

## Dependency Information
local name='srt'
local -A versions=(
  macos 1.4.1
  linux 1.4.4
  windows 1.4.2
)
local -A urls=(
  macos https://github.com/Haivision/srt/archive/v1.4.4.tar.gz
  linux https://github.com/Haivision/srt/archive/v1.4.4.tar.gz
  windows https://github.com/Haivision/srt.git
)
local -A hashes=(
  macos "${0:a:h}/checksums/v1.4.1.tar.gz.sha256"
  linux "${0:a:h}/checksums/v1.4.4.tar.gz.sha256"
  windows 50b7af06f3a0a456c172b4cb3aceafa8a5cc0036
)
local -a patches=(
  "* ${0:a:h}/patches/srt/0001-enable-proper-cmake-build-types.patch \
    c032f2a23f11c8d6f3cd5c0217b2862fc8bdfad0e4002d1ff0731adede523586"
)

## Dependency Overrides
local -i shared_libs=1
local dir="${name}-${version}"

## Build Steps
setup() {
  log_info "Setup (%F{3}${target}%f)"
  setup_dep ${url} ${hash}
}

clean() {
  cd "${dir}"

  if [[ ${clean_build} -gt 0 && -d "build_${arch}" ]] {
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

  local _onoff=(OFF ON)

  args=(
    ${cmake_flags}
    -DENABLE_SHARED="${_onoff[(( shared_libs + 1 ))]}"
    -DENABLE_STATIC=ON
    -DENABLE_APPS=OFF
    -DUSE_ENCLIB="mbedtls"
  )

  case ${target} {
    windows-x*)
      args+=(
        -DUSE_OPENSSL_PC=OFF
        -DCMAKE_CXX_FLAGS="-static-libgcc -static-libstdc++ -w -pipe -fno-semantic-interposition"
        -DCMAKE_C_FLAGS="-static-libgcc -w -pipe -fno-semantic-interposition"
        -DCMAKE_SHARED_LINKER_FLAGS="-static-libgcc -static-libstdc++ -L${target_config[output_dir]}/lib"
        -DSSL_LIBRARY_DIRS="${target_config[output_dir]}/lib"
        -DSSL_INCLUDE_DIRS="${target_config[output_dir]}/include"
      )

      autoload -Uz hide_dlls && hide_dlls
      ;;
  }

  log_info "Config (%F{3}${target}%f)"
  cd "${dir}"
  log_debug "CMake configuration options: ${args}'"
  progress cmake -S . -B "build_${arch}" -G Ninja ${args}
}

build() {
  autoload -Uz mkcd progress

  log_info "Build (%F{3}${target}%f)"

  cd "${dir}"

  args=(
    --build "build_${arch}"
    --config "${config}"
  )

  if (( _loglevel > 1 )) args+=(--verbose)

  cmake ${args}
}

install() {
  autoload -Uz progress

  log_info "Install (%F{3}${target}%f)"

  args=(
    --install "build_${arch}"
    --config "${config}"
  )

  if [[ "${config}" =~ "Release|MinSizeRel" ]] args+=(--strip)
  if (( _loglevel > 1 )) args+=(--verbose)

  cd "${dir}"
  progress cmake ${args}
}

fixup() {
  cd "${dir}"

  rm ${target_config[output_dir]}/bin/(srt-ffp*)(N)

  if [[ ${target} == "windows-x"* ]] {
    log_info "Fixup (%F{3}${target}%f)"
    if (( shared_libs )) {
      autoload -Uz create_importlibs
      create_importlibs ${target_config[output_dir]}/bin/libsrt*.dll
    }

    autoload -Uz restore_dlls && restore_dlls
  }
}
