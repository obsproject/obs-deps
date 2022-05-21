autoload -Uz log_debug log_error log_info log_status log_output

## Dependency Information
local name='zlib'
local version='1.2.11'
local url='https://github.com/madler/zlib.git'
local hash='cacf7f1d4e3d44d871b605da3b647f07d718623f'

## Dependency Overrides
local targets=('windows-x*')

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

  args=(
    ${cmake_flags}
    -DCMAKE_SHARED_LIBRARY_PREFIX=""
    -DCMAKE_SHARED_LIBRARY_PREFIX_C=""
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
    log_info "Fixup (%F{3}${target}%f)"
    autoload -Uz create_importlibs
    create_importlibs ${target_config[output_dir]}/bin/zlib*.dll

    mkdir -p ${target_config[output_dir]}/lib/pkgconfig
    mv ${target_config[output_dir]}/share/pkgconfig/zlib.pc \
      ${target_config[output_dir]}/lib/pkgconfig/zlib.pc

    pushd ${PWD}
    cd ${target_config[output_dir]}

    autoload -Uz apply_patch
    apply_patch "${funcsourcetrace[1]:A:h}/patches/zlib/0001-disable-unistd-import.patch" \
      'e7534bbf425d4670757b329eebb7c997e4ab928030c7479bdd8fc872e3c6e728'

    mv lib/libzlib.dll.a lib/libz.dll.a
    mv lib/libzlibstatic.a lib/libz.a
    popd
  }
}
