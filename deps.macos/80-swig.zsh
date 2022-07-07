autoload -Uz log_debug log_error log_info log_status log_output

## Dependency Information
local name='swig'
local version='1.6.37'
local url='https://github.com/swig/swig.git'
local hash="4dd285fad736c014224ef2ad25b85e17f3dce1f9"
local patches=(
  "${0:a:h}/patches/swig/0001-add-Python-3-stable-abi.patch \
  08e41977a897d0b4d6832ea9acfcba510ae8317344620e039b0703a910ad23bf"
)

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

  args=(
    ${cmake_flags//ARCHITECTURES=${arch}/"ARCHITECTURES='x86_64;arm64'"}
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
