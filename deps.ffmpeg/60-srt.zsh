autoload -Uz log_debug log_error log_info log_status log_output

## Dependency Information
local name='srt'
local version='1.5.4'
local url='https://github.com/Haivision/srt/archive/v1.5.4.tar.gz'
local hash="${0:a:h}/checksums/v1.5.4.tar.gz.sha256"
local -a patches=(
  "* ${0:a:h}/patches/srt/0001-enable-proper-cmake-build-types.patch \
    8d1dc116ebf605d423d33cc6a4a1660e5b3ea81eb147622f55fed2043c41f0d7"
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

    if [[ ${target%%-*} == ${~_target} ]] apply_patch ${_url} ${_hash}
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
        -DCMAKE_SHARED_LINKER_FLAGS="-static-libgcc -static-libstdc++ -L${target_config[output_dir]}/lib -Wl,--exclude-libs,ALL"
        -DSSL_LIBRARY_DIRS="${target_config[output_dir]}/lib"
        -DSSL_INCLUDE_DIRS="${target_config[output_dir]}/include"
      )

      autoload -Uz hide_dlls && hide_dlls
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

  cd "${dir}"
  progress cmake ${args}
}

fixup() {
  cd "${dir}"

  log_info "Fixup (%F{3}${target}%f)"
  local strip_tool
  local -a strip_files

  case ${target} {
    macos*)
      if (( shared_libs )) {
        pushd "${target_config[output_dir]}"/lib
        if [[ -h libsrt.dylib ]] {
          rm libsrt.dylib
          ln -s libsrt.*.dylib(.) libsrt.dylib
        }
        popd

        dylib_files=(${target_config[output_dir]}/lib/libsrt*.dylib(.))

        autoload -Uz fix_rpaths && fix_rpaths ${dylib_files}

        if [[ ${config} == Release ]] dsymutil ${dylib_files}

        strip_tool=strip
        strip_files=(${dylib_files})
      } else {
        rm -rf -- ${target_config[output_dir]}/lib/libsrt*.(dylib|dSYM)(N)
      }
      ;;
    linux-*)
        if (( shared_libs )) {
          strip_tool=strip
          strip_files=(${target_config[output_dir]}/lib/libsrt.so.*(.))
        } else {
          rm -rf -- ${target_config[output_dir]}/lib/libsrt.so.*(N)
        }
      ;;
    windows*)
      log_info "Fixup (%F{3}${target}%f)"
      if (( shared_libs )) {
        autoload -Uz create_importlibs
        create_importlibs ${target_config[output_dir]}/bin/libsrt*.dll

        strip_tool=${target_config[cross_prefix]}-w64-mingw32-strip
        strip_files=(${target_config[output_dir]}/bin/libsrt*.dll(.))
      } else {
        rm -rf -- ${target_config[output_dir]}/bin/libsrt*.dll(N)
      }

      autoload -Uz restore_dlls && restore_dlls
      ;;
  }

  rm ${target_config[output_dir]}/bin/(srt-ffp*)(N)
  if (( #strip_files )) && [[ ${config} == (Release|MinSizeRel) ]] ${strip_tool} -x ${strip_files}
}
