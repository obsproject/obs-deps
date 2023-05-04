autoload -Uz log_debug log_error log_info log_status log_output

## Dependency Information
local name='opus'
local version='1.3.1'
local url='https://github.com/xiph/opus.git'
local -A hashes=(
  macos 8cf872a186b96085b1bb3a547afd598354ebeb87
  linux 8cf872a186b96085b1bb3a547afd598354ebeb87
  windows 8cf872a186b96085b1bb3a547afd598354ebeb87
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

config() {
  autoload -Uz mkcd progress

  local _onoff=(OFF ON)

  args=(
    ${cmake_flags}
    -DBUILD_TESTING=OFF
    -DOPUS_BUILD_PROGRAMS=OFF
    -DBUILD_SHARED_LIBS="${_onoff[(( shared_libs + 1 ))]}"
  )

  case ${target} {
    macos-x86_64 | linux-*)
      args+=(-DOPUS_STACK_PROTECTOR=ON)
      ;;
    macos-arm64 | macos-universal)
      args+=(
        -DCMAKE_ASM_FLAGS="-DPNG_ARM_NEON_IMPLEMENTATION=1"
        -DPNG_ARM_NEON=on
        -DOPUS_STACK_PROTECTOR=ON
      )

      mkdir -p ${dir}/build_${arch}/arm64
      ;;
    windows-x*)
      args+=(
        -DOPUS_STACK_PROTECTOR=OFF
        -DOPUS_FORTIFY_SOURCE=OFF
      )
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
        local -a dylib_files=("${target_config[output_dir]}"/lib/libopus*.dylib(.))

        autoload -Uz fix_rpaths && fix_rpaths ${dylib_files}

        if [[ ${config} == Release ]] dsymutil ${dylib_files}
        strip_tool=strip
        strip_files=(${dylib_files})
      } else {
        rm -rf -- ${target_config[output_dir]}/lib/libopus*.(dylib|dSYM)(N)
      }
      ;;
    linux-*)
      if (( shared_libs )) {
        strip_tool=strip
        strip_files=("${target_config[output_dir]}"/lib/libopus.so.*(.))
      } else {
        rm -rf -- ${target_config[output_dir]}/lib/libopus.so.*(N)
      }
      ;;
    windows-*)
      if (( shared_libs )) {
        autoload -Uz create_importlibs
        create_importlibs ${target_config[output_dir]}/bin/libopus*.dll(:a)
        autoload -Uz restore_dlls && restore_dlls

        strip_tool=${target_config[cross_prefix]}-w64-mingw32-strip
        strip_files=(${target_config[output_dir]}/bin/bin/libopus*.dll(.))
      } else {
        rm -rf -- ${target_config[output_dir]}/lib/libopus*.dll(N)
      }
      ;;
  }

  rm -rf ${target_config[output_dir]}/lib/cmake/Opus
  if (( #strip_files )) && [[ ${config} == (Release|MinSizeRel) ]] ${strip_tool} -x ${strip_files}
}
