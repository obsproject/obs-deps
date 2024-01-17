autoload -Uz log_debug log_error log_info log_status log_output

## Dependency Information
local name='zlib'
local version='1.3'
local url='https://github.com/madler/zlib.git'
local hash='09155eaa2f9270dc4ed1fa13e2b4b2613e6e4851'

## Dependency Overrides
local targets=('windows-x*')

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

  args=(
    ${cmake_flags}
    -DCMAKE_SHARED_LIBRARY_PREFIX=""
    -DCMAKE_SHARED_LIBRARY_PREFIX_C=""
  )
  if [[ ${target} == "windows-x"* ]] {
    args+=(
      -DZ_HAVE_UNISTD_H=OFF
    )
  }

  log_info "Config (%F{3}${target}%f)"
  cd ${dir}
  log_debug "CMake configuration options: ${args}'"
  progress cmake -S . -B build_${arch} -G Ninja ${args}
}

build() {
  autoload -Uz mkcd progress

  log_info "Build (%F{3}${target}%f)"

  cd ${dir}

  args=(
    --build build_${arch}
    --config ${config}
  )

  if (( _loglevel > 1 )) args+=(--verbose)

  cmake ${args}
}

install() {
  autoload -Uz progress

  log_info "Install (%F{3}${target}%f)"

  args=(
    --install build_${arch}
    --config ${config}
  )

  if [[ ${config} == (Release|MinSizeRel) ]] args+=(--strip)
  if (( _loglevel > 1 )) args+=(--verbose)

  cd ${dir}

  progress cmake ${args}
}

fixup() {
  cd "${dir}"

  log_info "Fixup (%F{3}${target}%f)"
  autoload -Uz create_importlibs
  create_importlibs ${target_config[output_dir]}/bin/zlib*.dll

  mkdir -p ${target_config[output_dir]}/lib/pkgconfig
  mv ${target_config[output_dir]}/share/pkgconfig/zlib.pc \
    ${target_config[output_dir]}/lib/pkgconfig/zlib.pc

  pushd ${target_config[output_dir]}
  mv lib/libzlib.dll.a lib/libz.dll.a
  mv lib/libzlibstatic.a lib/libz.a
  popd
}
