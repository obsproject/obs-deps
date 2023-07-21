autoload -Uz log_debug log_error log_info log_status log_output

## Dependency Information
local name='carla'
local version='2.6.0-alpha1'
local url='https://github.com/falkTX/Carla.git'
local hash='cb7f1a975790dda458481e88de0a29c433b706c9'

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

  log_info "Config (%F{3}${target}%f)"

  args=(
    ${cmake_flags}
    -DCARLA_BUILD_FRAMEWORKS:BOOL=ON
    -DCARLA_USE_JACK:BOOL=OFF
    -DCARLA_USE_OSC:BOOL=OFF
  )

  cd "${dir}"
  log_debug "CMake configure options: ${args}"
  progress cmake -S cmake -B "build_${arch}" -G Ninja ${args}
}

build() {
  autoload -Uz mkcd

  log_info "Build (%F{3}${target}%f)"

  cd "${dir}"
  cmake --build "build_${arch}" --config "${config}"
}

install() {
  autoload -Uz progress

  log_info "Install (%F{3}${target}%f)"

  args=(
    --install "build_${arch}"
    --config "${config}"
  )

  if [[ "${config}" =~ "Release|MinSizeRel" ]] args+=(--strip)

  cd "${dir}"
  progress cmake ${args}
}

fixup() {
  cd "${dir}"

  log_info "Fixup (%F{3}${target}%f)"
  case ${target} {
    macos*)
      rm -r "${target_config[output_dir]}"/include/carla
      rm -r "${target_config[output_dir]}"/lib/carla-native-plugin.framework
      rm -r "${target_config[output_dir]}"/lib/carla-standalone.framework
      ;;
  }
}
