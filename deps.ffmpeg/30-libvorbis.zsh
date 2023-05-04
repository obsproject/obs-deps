autoload -Uz log_debug log_error log_info log_status log_output

## Dependency Information
local name='libvorbis'
local -A versions=(
  macos 1.3.7
  linux 1.3.7
  windows 1.3.7
)
local -A urls=(
  macos https://github.com/xiph/vorbis/releases/download/v1.3.7/libvorbis-1.3.7.tar.xz
  linux https://github.com/xiph/vorbis.git
  windows https://github.com/xiph/vorbis.git
)
local -A hashes=(
  macos "${0:a:h}/checksums/libvorbis-1.3.7.tar.xz.sha256"
  linux 84c023699cdf023a32fa4ded32019f194afcdad0
  windows 84c023699cdf023a32fa4ded32019f194afcdad0
)
local -a patches=(
  "windows ${0:a:h}/patches/libvorbis/0001-fix-outdated-windows-import-library-definition.patch \
  61509491d9f4dd596502b0c5b1272de276c0f5a2f03ff44b43c90cfd7e62ead8"
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
    -DBUILD_SHARED_LIBS="${_onoff[(( shared_libs + 1 ))]}"
    -DBUILD_TESTING=OFF
  )

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
        local -a dylib_files=(${target_config[output_dir]}/lib/libvorbis*.dylib(.))

        autoload -Uz fix_rpaths && fix_rpaths ${dylib_files}

        if [[ ${config} == Release ]] dsymutil ${dylib_files}
        strip_tool=strip
        strip_files=(${dylib_files})
      } else {
        rm -rf -- ${target_config[output_dir]}/lib/libvorbis*.(dylib|dSYM)(N)
      }
      ;;
    linux-*)
      if (( shared_libs )) {
        strip_tool=strip
        strip_files=(${target_config[output_dir]}/lib/libvorbis.so.*(.))
      } else {
        rm -rf -- ${target_config[output_dir]}/lib/libvorbis.so.*(N)
      }
      ;;
    windows-*)
      if (( shared_libs )) {
        autoload -Uz create_importlibs
        create_importlibs ${target_config[output_dir]}/bin/libvorbis*.dll(:a)
        autoload -Uz restore_dlls && restore_dlls

        strip_tool=${target_config[cross_prefix]}-w64-mingw32-strip
        strip_files=(${target_config[output_dir]}/bin/bin/libvorbis*.dll(.))
      }
      ;;
  }

  rm -rf ${target_config[output_dir]}/lib/cmake/Vorbis
  if (( #strip_files )) && [[ ${config} == (Release|MinSizeRel) ]] ${strip_tool} -x ${strip_files}
}
