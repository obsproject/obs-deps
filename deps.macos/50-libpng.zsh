autoload -Uz log_debug log_error log_info log_status log_output

## Dependency Information
local name='libpng'
local version='1.6.37'
local url='https://downloads.sourceforge.net/project/libpng/libpng16/1.6.37/libpng-1.6.37.tar.xz'
local hash="${0:a:h}/checksums/libpng-1.6.37.tar.xz.sha256"
local patches=(
  "${0:a:h}/patches/libpng/0001-enable-ARM-NEON-optimisations.patch \
  fb8a209b466e8b2d9eba4c11f776412657b43386ef5db846dd1cc1476556aaa9"
)

## Dependency Overrides
local -i force_static=1

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

  case ${target} {
    macos-*)
      local patch
      for patch (${patches}) {
        local _url
        local _hash
        read _url _hash <<< "${patch}"
        apply_patch "${_url}" "${_hash}"
      }
      ;;
  }
}

config() {
  autoload -Uz mkcd progress

  if (( shared_libs )) {
    local shared=$(( shared_libs - force_static ))
  } else {
    local shared=0
  }
  local _onoff=(OFF ON)

  args=(
    ${cmake_flags}
    -DPNG_TESTS=OFF
    -DPNG_STATIC=ON
    -DPNG_SHARED="${_onoff[(( shared + 1 ))]}"
  )

  if [[ "${config}" == "Debug" ]] {
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

      mkdir -p "${dir}/build_${arch}/arm64"
      ;;
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
