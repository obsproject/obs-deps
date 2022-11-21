autoload -Uz log_debug log_error log_info log_status log_output

## Dependency Information
local name='aom'
local version='3.5.0'
local url='https://aomedia.googlesource.com/aom.git'
local hash='bcfe6fbfed315f83ee8a95465c654ee8078dbff9'
local -a patches=(
  "windows ${0:a:h}/patches/libaom/0001-force-threading-shim-usage.patch \
  6fa9ca74001c5fa3a6521a2b4944be2a8b4350d31c0234aede9a7052a8f1890b"
)

## Dependency Overrides
local targets=(windows-x64 'macos-*' 'linux-*')

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

patch() {
  autoload -Uz apply_patch

  log_info "Patch (%F{3}${target}%f)"

  cd "${dir}"

  local patch
  local _target
  local _url
  local _hash
  for patch (${patches}) {
    read _target _url _hash <<< "${patch}"

    if [[ ${_target} == "${target%%-*}" ]] apply_patch "${_url}" "${_hash}"
  }
}

config() {
  autoload -Uz mkcd progress

  local _onoff=(OFF ON)

  args=(
    ${cmake_flags}
    -DBUILD_SHARED_LIBS="${_onoff[(( shared_libs + 1 ))]}"
    -DAOM_TARGET_CPU="${arch}"
    -DENABLE_DOCS=OFF
    -DENABLE_EXAMPLES=OFF
    -DENABLE_TESTDATA=OFF
    -DENABLE_TESTS=OFF
    -DENABLE_TOOLS=OFF
    -DENABLE_NASM=ON
  )

  case ${target} {
    macos-arm64) args+=(-DCONFIG_RUNTIME_CPU_DETECT=0) ;;
    windows-x*) args+=(-DCMAKE_TOOLCHAIN_FILE="build/cmake/toolchains/${target_config[cmake_arch]}-mingw-gcc.cmake")
  }

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
    if (( shared_libs )) {
      log_info "Fixup (%F{3}${target}%f)"
      autoload -Uz create_importlibs
      create_importlibs ${target_config[output_dir]}/bin/libaom*.dll(.)
    }
  }
}
