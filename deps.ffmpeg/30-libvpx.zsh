autoload -Uz log_debug log_error log_info log_status log_output

## Dependency Information
local name='libvpx'
local -A versions=(
  macos 1.13.1
  linux 1.13.1
  windows 1.13.1
)
local -A urls=(
  macos https://github.com/webmproject/libvpx/archive/v1.13.1.tar.gz
  linux https://github.com/webmproject/libvpx/archive/v1.13.1.tar.gz
  windows https://github.com/webmproject/libvpx/archive/v1.13.1.tar.gz
)
local -A hashes=(
  macos "${0:a:h}/checksums/v1.13.1.tar.gz.sha256"
  linux "${0:a:h}/checksums/v1.13.1.tar.gz.sha256"
  windows "${0:a:h}/checksums/v1.13.1.tar.gz.sha256"
)
local -a patches=(
  "windows ${0:a:h}/patches/libvpx/0001-libvpx-crosscompile-win-dll.patch \
  9553b8186feac616d4421188d7c6ca75fbce900265e688cafdf1ed3333ad376a"
  "windows ${0:a:h}/patches/libvpx/0002-force-pthread-shim.patch \
  f1c823f10320205494e80e9995722045831c6982fe8463a81fdebb69ca385c94"
)

## Dependency Overrides
local dir="${name}-${versions[${target%%-*}]}"

## Build Steps
setup() {
  log_info "Setup (%F{3}${target}%f)"
  setup_dep ${url} ${hash}
}

clean() {
  cd ${dir}

  if [[ ${clean_build} -gt 0 && -f build_${arch}/Makefile ]] {
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

    if [[ ${_target} == "${target%%-*}" ]] apply_patch ${_url} ${_hash}
  }
}

config() {
  autoload -Uz mkcd progress

  local cross_prefix
  case ${target} {
    macos-universal)
      autoload -Uz universal_config && universal_config
      return
      ;;
    macos-*)
      if [[ ${arch} == x86_64 ]] {
        args+=(
          --enable-runtime-cpu-detect
          --target="${arch}-darwin${target_config[darwin_target]}-gcc"
        )
      } else {
        args+=(--target="${arch}-darwin20-gcc")
      }
      ;;
    windows-x*)
      cross_prefix="${target_config[cross_prefix]}-w64-mingw32-"
      args+=(--enable-runtime-cpu-detect --target="${target_config[gcc_target]}")
      ;;
  }

  log_info "Config (%F{3}${target}%f)"
  cd ${dir}

  mkcd build_${arch}

  local _onoff=(disable enable)
  args+=(
    --prefix="${target_config[output_dir]}"
    --enable-vp8
    --enable-vp9
    --enable-vp9-highbitdepth
    --enable-static
    --enable-multithread
    --enable-pic
    --enable-realtime-only
    --disable-docs
    --disable-examples
    --disable-install-bins
    --disable-install-docs
    --disable-unit-tests
    "--${_onoff[(( shared_libs + 1 ))]}-shared"
    ${${commands[ccache]}:+--enable-ccache}
  )

  if [[ ${config} == Debug ]] args+=(--enable-debug)

  log_debug "Configure option: ${args}"
  CROSS="${cross_prefix}" \
  CFLAGS="${c_flags}" \
  LDFLAGS="${ld_flags}" \
  PKG_CONFIG_LIBDIR="${target_config[output_dir]}/lib/pkgconfig" \
  progress ../configure ${args}
}

build() {
  autoload -Uz mkcd progress

  case ${target} {
    macos-universal)
      autoload -Uz universal_build && universal_build
      return
      ;;
  }

  log_info "Build (%F{3}${target}%f)"
  cd ${dir}/build_${arch}

  log_debug "Running make -j ${num_procs}"
  progress make -j ${num_procs}
}

install() {
  autoload -Uz progress

  log_info "Install (%F{3}${target}%f)"

  cd ${dir}/build_${arch}

  progress make install
}

fixup() {
  cd ${dir}

  log_info "Fixup (%F{3}${target}%f)"

  local strip_tool
  local -a strip_files

  case ${target} {
    macos*)
      if (( shared_libs )) {
        local -a dylib_files=(${target_config[output_dir]}/lib/libvpx*.dylib(.))

        autoload -Uz fix_rpaths && fix_rpaths ${dylib_files}

        if [[ ${config} == Release ]] dsymutil ${dylib_files}

        strip_tool=strip
        strip_files=(${dylib_files})
      } else {
        rm -rf -- ${target_config[output_dir]}/lib/libvpx*.(dylib|dSYM)(N)
      }
      ;;
    linux-*)
      if (( shared_libs )) {
        strip_tool=strip
        strip_files(${target_config[output_dir]}/lib/libvpx.so.*(.))
      } else {
        rm -rf -- ${target_config[output_dir]}/lib/libvpx.so.*(N)
      }
      ;;
    windows-x*)
      if (( shared_libs )) {
        autoload -Uz create_importlibs
        create_importlibs "${target_config[output_dir]}"/bin/libvpx*.dll(:a)

        strip_tool=${target_config[cross_prefix]}-w64-mingw32-strip
        strip_files=(${target_config[output_dir]}/bin/libvpx*.dll(:a))
      } else {
        rm -rf -- ${target_config[output_dir]}/bin/libvpx*.dll(N)
      }
      ;;
  }

  if (( #strip_files )) && [[ ${config} == (Release|MinSizeRel) ]] ${strip_tool} -x ${strip_files}
}
