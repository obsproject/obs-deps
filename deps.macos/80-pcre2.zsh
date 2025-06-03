autoload -Uz log_debug log_error log_info log_status log_output

## Dependency Information
local name='pcre2'
local version='10.40'
local url='https://github.com/PhilipHazel/pcre2/releases/download/pcre2-10.40/pcre2-10.40.tar.bz2'
local hash="${0:a:h}/checksums/pcre2-10.40.tar.bz2.sha256"
local patches=()

## Dependency Overrides
local -i shared_libs=0

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
  for patch (${patches}) {
    local _url
    local _hash
    read _url _hash <<< "${patch}"
    apply_patch ${_url} ${_hash}
  }
}

config() {
  autoload -Uz mkcd progress

  local _onoff=(OFF ON)

  args=(
    ${cmake_flags//ARCHITECTURES=${arch}/"ARCHITECTURES='x86_64;arm64'"}
    -DBUILD_SHARED_LIBS="${_onoff[(( shared_libs + 1 ))]}"
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

  if (( shared_libs )) {
    local -a dylib_files=(${target_config[output_dir]}/lib/libpcre2*.dylib(.))

    log_info "Fixup (%F{3}${target}%f)"
    autoload -Uz fix_rpaths && fix_rpaths ${dylib_files}

    if [[ ${config} == Release ]] dsymutil ${dylib_files}
    if [[ ${config} == (Release|MinSizeRel) ]] strip -x ${dylib_files}
  } else {
    rm -rf -- ${target_config[output_dir]}/lib/libpcre2*.(dylib|dSYM)(N)
  }
}
