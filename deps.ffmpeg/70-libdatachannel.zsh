autoload -Uz log_debug log_error log_info log_status log_output

## Dependency Information
local name='libdatachannel'
local version='v0.21.0'
local url='https://github.com/paullouisageneau/libdatachannel.git'
local hash='9d5c46b8f506943727104d766e5dad0693c5a223'

## Dependency Overrides
local -i shared_libs=1
local dir="${name}-${version}"
local targets=('macos-*' 'linux-*')

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
    -DENABLE_SHARED="${_onoff[(( shared_libs + 1 ))]}"
    -DUSE_MBEDTLS=1
    -DNO_WEBSOCKET=1
    -DNO_TESTS=1
    -DNO_EXAMPLES=1
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
  cd ${dir}

  log_info "Fixup (%F{3}${target}%f)"

  local strip_tool
  local -a strip_files

  case ${target} {
    macos*)
      if (( shared_libs )) {
        local -a dylib_files=(${target_config[output_dir]}/lib/libdatachannel*.dylib(.))

        autoload -Uz fix_rpaths && fix_rpaths ${dylib_files}

        if [[ ${config} == Release ]] dsymutil ${dylib_files}

        for dylib_file (${dylib_files}) {
          sed -i '' -E -e "s/${dylib_file:t}/libdatachannel.dylib/g" ${target_config[output_dir]}/lib/cmake/LibDataChannel/LibDataChannelTargets-${(L)config}.cmake
        }

        strip_tool=strip
        strip_files=(${dylib_files})
      } else {
        rm -rf -- ${target_config[output_dir]}/lib/libdatachannel*.(dylib|dSYM)(N)
      }
      ;;
    linux*)
      if (( shared_libs )) {
        strip_tool=strip
        strip_files=(${target_config[output_dir]}/lib/libdatachannel.so*(.))
      } else {
        rm -rf -- ${target_config[output_dir]}/lib/libdatachannel.so*(N)
      }
      ;;
    windows-x*)
      if (( shared_libs )) {
        autoload -Uz create_importlibs
        create_importlibs ${target_config[output_dir]}/bin/libdatachannel*.dll(.)

        strip_tool=${target_config[cross_prefix]}-w64-mingw32-strip
        strip_files=(${target_config[output_dir]}/bin/libdatachannel*.dll(.))
      } else {
        rm -rf -- ${target_config[output_dir]}/bin/libdatachannel*.dll(N)
      }

      autoload -Uz restore_dlls && restore_dlls
      ;;
  }

  if (( #strip_files )) && [[ ${config} == (Release|MinSizeRel) ]] ${strip_tool} -x ${strip_files}
}
