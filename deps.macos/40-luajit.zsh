autoload -Uz log_debug log_error log_info log_status log_output

## Dependency Information
local name='luajit'
local version='2.1'
local url='https://github.com/LuaJIT/LuaJIT.git'
local hash='505e2c03de35e2718eef0d2d3660712e06dadf1f'
local branch='v2.1'
local patches=(
  "${0:a:h}/patches/libluajit/0001-change-hardcoded-compiler-name.patch \
  c12139bba780eff890ca0b308f10492e237a3c66140b061616599c0eb25f2341"
)

## Build Steps
setup() {
  log_info "Setup (%F{3}${target}%f)"
  setup_dep ${url} ${hash} ${branch}
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
  local _url
  local _hash
  for patch (${patches}) {
    read _url _hash <<< "${patch}"
    apply_patch ${_url} ${_hash}
  }
}

config() {
  autoload -Uz mkcd progress

  case ${target} {
    macos-universal)
      autoload -Uz universal_config && universal_config
      return
      ;;
  }

  log_info "Config (%F{3}${target}%f)"
  cd ${dir}

  mkcd build_${arch}
  rsync -ah ../etc ../src ../dynasm ../doc .
}

build() {
  autoload -Uz mkcd progress

  case ${target} {
    macos-universal)
      autoload -Uz universal_build && universal_build
      return
      ;;
    macos-arm64)
      args+=(TARGET_ASFLAGS="${as_flags}")
      ;;
  }

  log_info "Build (%F{3}${target}%f)"

  cd ${dir}/build_${arch}

  args+=(
    XCFLAGS=-DLUAJIT_ENABLE_GC64
    PREFIX="${target_config[output_dir]}"
    CC=clang
    CXX=clang
    TARGET_CFLAGS="${c_flags}"
    TARGET_LDFLAGS="${ld_flags}"
    TARGET_SHLDFLAGS="${ld_flags}"
  )

  if [[ ${config} != 'MinSizeRel' ]] args+=(CCDEBUG=-g)

  log_debug "Build options: ${args}"
  PATH="${(j.:.)cc_path}" progress make amalg ${args} -j ${num_procs} -f ../Makefile
}

install() {
  autoload -Uz progress

  log_info "Install (%F{3}${target}%f)"

  cd ${dir}/build_${arch}

  PATH="${(j.:.)cc_path}" progress make install PREFIX="${target_config[output_dir]}" -f ../Makefile
}

fixup() {
  cd ${dir}

  if (( shared_libs )) {
    local -a dylib_files=(${target_config[output_dir]}/lib/libluajit-5.1*.dylib(.))

    log_info "Fixup (%F{3}${target}%f)"

    for file (${dylib_files}) {
      install_name_tool -id "@rpath/libluajit-5.1.dylib" "${file}"
      log_status "Fixed id of ${file##*/}"
    }

    if [[ ${config} == 'Release' ]] {
      dsymutil ${dylib_files}
      strip -x ${dylib_files}
    }
  } else {
    rm -rf -- ${target_config[output_dir]}/lib/libluajit-5.1*.(dylib|dSYM)(N)
  }
}
