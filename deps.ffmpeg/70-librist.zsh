autoload -Uz log_debug log_error log_info log_status log_output

## Dependency Information
local name='librist'
local version='0.2.7'
local url='https://code.videolan.org/rist/librist.git'
local hash='809390b3b75a259a704079d0fb4d8f1b5f7fa956'
local -a patches=(
  "macos ${0:a:h}/patches/librist/0001-generate-cross-compile-files-macos.patch \
    f185682aba370288585dda020d259311486056b228169cdfa5559dd7a03e2473"
  "windows ${0:a:h}/patches/librist/0001-generate-cross-compile-files-windows.patch \
    c7b8459642281a82a85c23acf7939c7a2c8345fc23b89773b8d1e9d8152dca2e"
)

## Dependency Overrides
local -i shared_libs=1

## Build Steps
setup() {
  log_info "Setup (%F{3}${target}%f)"
  setup_dep ${url} ${hash}
}

clean() {
  cd ${dir}

  if [[ ${clean_build} -gt 0 && -f build_${arch}/build.ninja ]] {
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

  local build_type

  case ${config} {
    Debug) build_type='debug' ;;
    RelWithDebInfo) build_type='debugoptimized' ;;
    Release) build_type='release' ;;
    MinSizeRel) build_type='minsize' ;;
  }

  if (( shared_libs )) {
    args+=(--default-library both)
  } else {
    args+=(--default-library static)
  }

  case "${target}" {
    macos-universal)
      autoload -Uz universal_config && universal_config
      return
      ;;
    macos-*) args+=(--cross-file "cross_compile_${arch}.txt") ;;
    windows-x*)
      args+=(--cross-file "cross_mingw_${target_config[cmake_arch]}.txt")

      autoload -Uz hide_dlls && hide_dlls
      ;;
  }

  log_info "Config (%F{3}${target}%f)"
  cd ${dir}

  args+=(
    --buildtype "${build_type}"
    --prefix "${target_config[output_dir]}"
    -Dhave_mingw_pthreads=true
    -Duse_mbedtls=true
    -Dbuiltin_cjson=true
    -Dtest=false
    -Dbuilt_tools=false
    -Dpkg_config_path="${target_config[output_dir]}/lib/pkgconfig"
  )

  if [[ ${config} == Release ]] args+=(--buildtype custom -Doptimization=3 -Ddebug=true)

  log_debug "Meson configure options: ${args}"
  meson setup build_${arch} ${args}
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
  cd ${dir}

  log_debug "Running meson compile -C build_${arch}"
  meson compile -C build_${arch}
}

install() {
  autoload -Uz progress

  log_info "Install (%F{3}${target}%f)"

  cd ${dir}

  meson install -C build_${arch}
}

fixup() {
  cd ${dir}

  log_info "Fixup (%F{3}${target}%f)"

  local strip_tool
  local -a strip_files

  case ${target} {
    macos*)
      if (( shared_libs )) {
        local -a dylib_files=(${target_config[output_dir]}/lib/librist*.dylib(.))

        autoload -Uz fix_rpaths && fix_rpaths ${dylib_files}

        if [[ ${config} == Release ]] dsymutil ${dylib_files}

        strip_tool=strip
        strip_files=(${dylib_files})
      } else {
        rm -rf -- ${target_config[output_dir]}/lib/librist*.(dylib|dSYM)(N)
      }
      ;;
    linux*)
      if (( shared_libs )) {
        strip_tool=strip
        strip_files=(${target_config[output_dir]}/lib/librist.so*(.))
      } else {
        rm -rf -- ${target_config[output_dir]}/lib/librist.so*(N)
      }
      ;;
    windows-x*)
      if (( shared_libs )) {
        autoload -Uz create_importlibs
        create_importlibs ${target_config[output_dir]}/bin/librist*.dll(.)

        strip_tool=${target_config[cross_prefix]}-w64-mingw32-strip
        strip_files=(${target_config[output_dir]}/bin/librist*.dll(.))
      } else {
        rm -rf -- ${target_config[output_dir]}/bin/librist*.dll(N)
      }

      autoload -Uz restore_dlls && restore_dlls
      ;;
  }

  if (( #strip_files )) && [[ ${config} == (Release|MinSizeRel) ]] ${strip_tool} -x ${strip_files}
}
