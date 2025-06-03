autoload -Uz log_debug log_error log_info log_status log_output

# Dependency Information
local name='simde'
local version='0.8.2'
local url='https://github.com/simd-everywhere/simde.git'
local hash='71fd833d9666141edcd1d3c109a80e228303d8d7'

## Build Steps
setup() {
  log_info "Setup (%F{3}${target}%f)"
  setup_dep ${url} ${hash}
}

clean() {
  cd ${dir}

  if [[ ${clean_build} -gt 0 && -d build_${arch} ]] {
    log_info "Clean build directory (%F{3}${target}%f)"

    rm -rf build_${arch}
  }
}

config() {
  autoload -Uz mkcd progress

  local build_type

  case ${config} {
    Debug) build_type='debug' ;;
    RelWithDebInfo) build_type='debugoptimized' ;;
    Release) build_type='release' ;;
    MinSizeRel) build_type='minsize' ;;
  }

  log_info "Config (%F{3}${target}%f)"

  args=(
    --buildtype "${build_type}"
    --prefix "${target_config[output_dir]}"
    -Dtests=false
    -Dpkg_config_path="${target_config[output_dir]}/lib/pkgconfig"
  )

  cd ${dir}
  log_debug "Meson configure options: ${args}"
  progress meson setup build_${arch} ${args}
}

build() {
  autoload -Uz mkcd

  log_info "Build (%F{3}${target}%f)"
  cd ${dir}

  log_debug "Running meson compile -C build_${arch}"
  meson compile -C build_${arch}
}

install() {
  autoload -Uz progress

  log_info "Install (%F{3}${target}%f)"

  cd "${dir}"
  meson install -C build_${arch}
}
