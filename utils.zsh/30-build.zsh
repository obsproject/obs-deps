setup_target() {
  autoload -Uz log_error log_output log_debug
  local -A config_data

  if (( # < 1 )) {
    log_error "Called without enough arguments"
    return 2
  }

  config_data=(
    [cmake_arch]=x86_64
    [target_os]=${1%%-*}
    [arch]=${1##*-}
    [output_dir]="${project_root}/${1}/obs-${PACKAGE_NAME}-${1##*-}"
  )

  case ${1} {
    macos-x86_64)
      config_data+=(
        [deployment_target]=10.13
        [darwin_target]=17
      )
      ;;
    macos-arm64)
      config_data+=(
        [cmake_arch]=arm64
        [deployment_target]=11.0
        [darwin_target]=20
      )
      ;;
    macos-universal)
      config_data+=(
        [cmake_arch]="x86_64;arm64"
        [deployment_target]=10.13
        [darwin_target]=17
      )
      ;;
    linux-x86_64)
      ;;
    windows-x86)
      config_data+=(
        [cmake_arch]='x86'
        [cross_prefix]='i686'
        [mval]='i386'
        [gcc_target]='x86-win32-gcc'
        [toolchain]="${funcsourcetrace[1]:A:h}/toolchain/windows-cross-toolchain.cmake"
      )
      ;;
    windows-x64)
      config_data+=(
        [cmake_arch]='x86_64'
        [cross_prefix]='x86_64'
        [mval]='i386:x86-64'
        [gcc_target]='x86_64-win64-gcc'
        [toolchain]="${funcsourcetrace[1]:A:h}/toolchain/windows-cross-toolchain.cmake"
      )
      ;;
    *) log_error "Invalid target specified: %F{1}${1}%f"; exit 2 ;;
  }

  typeset -g -A target_config=(${(kv)config_data})
  log_debug "
Architecture     : ${config_data[arch]}
CMake archs      : ${config_data[cmake_arch]}
CMake toolchain  : ${config_data[toolchain]:--}
Target           : ${config_data[target_os]}
output_dir       : ${config_data[output_dir]}
macOS target     : ${config_data[deployment_target]:--}
Darwin target    : ${config_data[darwin_target]:--}
Windows prefix   : ${config_data[cross_prefix]:--}
Windows mval     : ${config_data[mval]:--}"
}

setup_build_parameters() {
  autoload -Uz log_error log_output log_debug

  if (( # < 2 )) {
    log_error "Called without enough arguments"
    return 2
  }

  typeset -g -i num_procs=1
  typeset -g -a c_flags=(-w -pipe)
  typeset -g -a cxx_flags=(-w -pipe)
  typeset -g -a ld_flags=()
  typeset -g -a as_flags=()

  typeset -g -a cmake_flags=(
    -DCMAKE_INSTALL_PREFIX=${target_config[output_dir]}
    -DCMAKE_PREFIX_PATH=${target_config[output_dir]}
    -DCMAKE_BUILD_TYPE=${2}
    --no-warn-unused-cli
  )

  if (( _loglevel == 0 )) cmake_flags+=(-Wno_deprecated -Wno-dev --log-level=ERROR)

  case "${1}" in
    macos*)
      export MACOSX_DEPLOYMENT_TARGET=${target_config[deployment_target]}
      export SDKROOT=$(xcrun --sdk macosx --show-sdk-path)
      local defaults=(
        -mmacosx-version-min=${target_config[deployment_target]}
        -arch ${target_config[arch]}
      )

      cmake_flags+=(
        -DCMAKE_OSX_ARCHITECTURES=${target_config[cmake_arch]}
        -DCMAKE_MACOSX_RPATH=ON
        -DCMAKE_C_FLAGS="${c_flags}"
        -DCMAKE_CXX_FLAGS="${cxx_flags} -std=c++11 -stdlib=libc++"
      )

      as_flags+=(${defaults})
      c_flags+=(${defaults})
      cxx_flags+=(-stc=c++11 -stdlib=libc++ ${defaults})
      ld_flags+=(${defaults})

      if (( ${+commands[clang]} )) {
        export CC='clang'
        export CXX='clang++'
      }
      ;;
    linux*)
      cmake_flags+=(
        -DCMAKE_SYSTEM_PROCESSOR=${target_config[cmake_arch]}
        -DCMAKE_C_FLAGS="${c_flags} -fPIC"
        -DCMAKE_CXX_FLAGS="${cxx_flags} -fPIC"
      )

      c_flags+=(-fPIC)
      cxx_flags+=(-fPIC)

      if (( ${+commands[clang]} )) {
        export CC='clang'
        export CXX='clang++'
      }
      ;;
    windows*)
      cmake_flags+=(
        -DCMAKE_SYSTEM_PROCESSOR=${target_config[cmake_arch]}
        -DCMAKE_TOOLCHAIN_FILE=${target_config[toolchain]}
        -DCMAKE_C_FLAGS="${c_flags} -fno-semantic-interposition"
        -DCMAKE_CXX_FLAGS="${cxx_flags} -fno-semantic-interposition"
        -DCMAKE_SHARED_LINKER_FLAGS="-static-libgcc"
      )

      c_flags+=(-fno-semantic-interposition)
      cxx_flags+=(-fno-semantic-interposition)
      ld_flags+=(-static-libgcc)
      ;;
    *) log_error "Invalid target specified: %F{1}${1}%f"; return 2 ;;
  esac

  case "${2}" in
    Debug)
      c_flags+=(-g)
      cxx_flags+=(-g)
      ;;
    RelWithDebInfo)
      c_flags+=(-O2 -g -DNDEBUG)
      cxx_flags+=(-O2 -g -DNDEBUG)
      ;;
    Release)
      c_flags+=(-O3 -DNDEBUG)
      cxx_flags+=(-O3 -DNDEBUG)
      ;;
    MinSizeRel)
      c_flags+=(-Os -DNDEBUG)
      cxx_flags+=(-Os -DNDEBUG)
      ;;
  esac

  local -a compilers=()
  local -a ccache_path
  case "${host_os}" in
    macos)
      num_procs=$(( $(sysctl -n hw.ncpu) + 1 ))
      ccache_path=(
        "${HOMEBREW_PREFIX}/opt/ccache/libexec"
        ${path}
      )
      compilers+=(cc c++ gcc g++ clang clang++)
      ;;
    linux)
      num_procs=$(( $(nproc) + 1 ))
      ccache_path=(
        /usr/lib/ccache
        ${path}
      )
      compilers+=(cc c++ gcc g++)

      if [[ ${target} == "windows"* ]] compilers+=(
        "${target_config[cross_prefix]}-w64-mingw32-c++"
        "${target_config[cross_prefix]}-w64-mingw32-cpp"
        "${target_config[cross_prefix]}-w64-mingw32-gcc"
        "${target_config[cross_prefix]}-w64-mingw32-g++"
        "${target_config[cross_prefix]}-w64-mingw32-gcc"
      )
      ;;
  esac

  if (( ${+commands[ccache]} )) {
    cmake_flags+=(
      -DCMAKE_CXX_COMPILER_LAUNCHER=ccache
      -DCMAKE_C_COMPILER_LAUNCHER=ccache
    )

    log_info "Compiler status"
    local -a compiler_paths=(${ccache_path[1]}/(${~${(j:|:)compilers}}))

    local c
    for c (${compiler_paths}) {
      log_status "%B${c##*/}%b found (${c})"
    }

    typeset -g -a cc_path=(${ccache_path})
  } else {
    typeset -g -a cc_path=(${path})
  }

  log_debug "
C flags        : ${c_flags}
C++ flags      : ${cxx_flags}
LD flags       : ${ld_flags}
ASM flags      : ${as_flags}
CMake options  : ${cmake_flags}
C compiler     : ${CC:-}
C++ compiler   : ${CXX:-}
Multi-process  : ${num_procs}"
}
