autoload -Uz log_debug log_error log_info log_status log_output

## Dependency Information
local name='svt-av1'
local version='1.3.0'
local url='https://gitlab.com/AOMediaCodec/SVT-AV1.git'
local hash='91b94efb2809e83d9bf041d8575b32f234dfef27'

## Dependency Overrides
local targets=(windows-x64 'linux-*')

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

config() {
  autoload -Uz mkcd progress

  local _onoff=(OFF ON)

  args=(
    ${cmake_flags}
    -DBUILD_SHARED_LIBS="${_onoff[(( shared_libs + 1 ))]}"
    -DBUILD_APPS=OFF
    -DBUILD_DEC=ON
    -DBUILD_ENC=ON
    -DENABLE_NASM=ON
    -DBUILD_TESTING=OFF
  )

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

  if [[ ${target} == "windows-x"* ]] {
    if (( shared_libs )) {
      mv (#i)"${target_config[output_dir]}"/lib/libsvtav1*.dll "${target_config[output_dir]}"/bin/
      log_info "Fixup (%F{3}${target}%f)"
      autoload -Uz create_importlibs
      create_importlibs (#i)${target_config[output_dir]}/bin/libsvtav1*.dll
    }
  }
}
