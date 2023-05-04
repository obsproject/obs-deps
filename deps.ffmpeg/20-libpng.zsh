autoload -Uz log_debug log_error log_info log_status log_output

## Dependency Information
local name='libpng'
local version='1.6.38'
local url='https://downloads.sourceforge.net/project/libpng/libpng16/1.6.39/libpng-1.6.39.tar.xz'
local hash="${0:a:h}/checksums/libpng-1.6.39.tar.xz.sha256"
local -a patches=(
  "macos ${0:a:h}/patches/libpng/0001-enable-ARM-NEON-optimisations.patch \
  f9ce2b5f8b63ef6caa9ab0195d27c52563652da56ab53956ffa51b34ff90ad4d"
)

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

patch() {
  autoload -Uz apply_patch

  log_info "Patch (%F{3}${target}%f)"
  cd ${dir}

  local patch
  local _target
  local _url
  local _hash
  for patch (${patches}) {
    read _target _url _hash <<< "${patch}"

    if [[ ${_target} == ${target%%-*} ]] apply_patch ${_url} ${_hash}
  }
}

config() {
  autoload -Uz mkcd progress

  local _onoff=(OFF ON)

  args=(
    ${cmake_flags}
    -DPNG_TESTS=OFF
    -DPNG_STATIC=ON
    -DPNG_SHARED="${_onoff[(( shared_libs + 1 ))]}"
  )

  if [[ ${config} == Debug ]] {
    args+=(-DPNG_DEBUG=ON)
  } else {
    args+=(-DPNG_DEBUG=OFF)
  }

  case ${target} {
    macos-arm64 | macos-universal)
      args+=(
        -DCMAKE_ASM_FLAGS="-DPNG_ARM_NEON_IMPLEMENTATION=1"
        -DPNG_ARM_NEON=on
      )

      mkdir -p ${dir}/build_${arch}/arm64
      ;;
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

  if (( _loglevel > 1 )) args+=(--verbose)

  cd ${dir}
  progress cmake ${args}
}

fixup() {
  cd ${dir}

  log_info "Fixup (%F{3}${target}%f)"

  local strip_tool
  local -a strip_files

  case ${target} {
    macos*)
      if (( shared_libs )) {
        local -a dylib_files=(${target_config[output_dir]}/lib/libpng*.dylib(.))

        autoload -Uz fix_rpaths && fix_rpaths ${dylib_files}
        if [[ ${config} == Release ]] dsymutil ${dylib_files}
        strip_tool=strip
        strip_files=(${dylib_files})
      } else {
        rm -rf -- ${target_config[output_dir]}/lib/libpng*.(dylib|dSYM)(N)
      }
      ;;
    linux-*)
      if (( shared_libs )) {
        strip_tool=strip
        strip_files=("${target_config[output_dir]}"/lib/libpng.so.*(.))
      } else {
        rm -rf -- ${target_config[output_dir]}/lib/libpng.so.*(N)
      }
      ;;
    windows-x*)
      if (( shared_libs )) {
        autoload -Uz create_importlibs
        create_importlibs ${target_config[output_dir]}/bin/libpng*.dll(:a)
        strip_tool=${target_config[cross_prefix]}-w64-mingw32-strip
        strip_files=("${target_config[output_dir]}"/bin/bin/libpng*.dll(.))
      } else {
        rm -rf -- ${target_config[output_dir]}/lib/libpng*.dll(N)
      }
      ;;
  }

  rm ${target_config[output_dir]}/bin/(libpng*-config|png*fix*)(N)

  if (( #strip_files )) && [[ ${config} == (Release|MinSizeRel) ]] ${strip_tool} -x ${strip_files}
}
