autoload -Uz log_debug log_error log_info log_status log_output

## Dependency Information
local name='aom'
local version='3.13.1'
local url='https://aomedia.googlesource.com/aom.git'
local hash='d772e334cc724105040382a977ebb10dfd393293'
local -a patches=(
  "windows ${0:a:h}/patches/aom/0001-force-threading-shim-usage.patch \
  6fa9ca74001c5fa3a6521a2b4944be2a8b4350d31c0234aede9a7052a8f1890b"
  "macos ${0:a:h}/patches/aom/0002-fix-cmake-nasm-detection.patch \
  47d926731a31990b432f188e7e16628bd2ca334f5b71fe55241d7b845884a35d"
)

## Dependency Overrides
local targets=(windows-x64 'macos-*' 'linux-*')

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

  if [[ ${target} == macos-universal ]] {
      autoload -Uz universal_config && universal_config
      return
  }

  local _onoff=(OFF ON)

  args=(
    ${cmake_flags}
    -DBUILD_SHARED_LIBS="${_onoff[(( shared_libs + 1 ))]}"
    -DENABLE_DOCS=OFF
    -DENABLE_EXAMPLES=OFF
    -DENABLE_TESTDATA=OFF
    -DENABLE_TESTS=OFF
    -DENABLE_TOOLS=OFF
    -DENABLE_NASM=ON
  )

  case ${target} {
    macos-*) args+=(-DCMAKE_TOOLCHAIN_FILE="build/cmake/toolchains/${target_config[cmake_arch]}-macos.cmake") ;;
    windows-x*) args+=(-DCMAKE_TOOLCHAIN_FILE="build/cmake/toolchains/${target_config[cmake_arch]}-mingw-gcc.cmake")
  }

  log_info "Config (%F{3}${target}%f)"
  cd ${dir}
  log_debug "CMake configuration options: ${args}'"
  progress cmake -S . -B build_${arch} -G Ninja ${args}
}

build() {
  autoload -Uz mkcd progress

  if [[ ${target} == macos-universal ]] {
      autoload -Uz universal_build && universal_build
      return
  }

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

  if [[ ${target} == macos-universal ]] {
    pushd build_universal
    if [[ -f CMakeFiles/InstallScripts.json ]] sed -i '' -E -e 's/build_x86_64/build_universal/g' CMakeFiles/InstallScripts.json
    sed -i '' -E -e 's/build_x86_64/build_universal/g' cmake_install.cmake
    args=(${args//build_x86_64/build_universal})
    popd
  }

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
        local -a dylib_files=(${target_config[output_dir]}/lib/libaom*.dylib(.))

        autoload -Uz fix_rpaths && fix_rpaths ${dylib_files}

        if [[ ${config} == Release ]] dsymutil ${dylib_files}
        strip_tool=strip
        strip_files=(${dylib_files})
      } else {
        rm -rf -- ${target_config[output_dir]}/lib/libaom*.(dylib|dSYM)(N)
      }
      ;;
    linux-*)
      if (( shared_libs )) {
        strip_tool=strip
        strip_files=(${target_config[output_dir]}/lib/libaom.so.*(.))
      } else {
        rm -rf -- ${target_config[output_dir]}/lib/libaom.so.*(N)
      }
      ;;
    windows-x*)
      if (( shared_libs )) {
        autoload -Uz create_importlibs
        create_importlibs ${target_config[output_dir]}/bin/libaom*.dll(.)

        strip_tool=${target_config[cross_prefix]}-w64-mingw32-strip
        strip_files=(${target_config[output_dir]}/bin/libaom*.dll(.))
      } else {
        rm -rf ${target_config[output_dir]}/bin/libaom*.dll(N)
      }
      ;;
  }

  if (( #strip_files )) && [[ ${config} == (Release|MinSizeRel) ]] ${strip_tool} -x ${strip_files}
}
