autoload -Uz log_debug log_error log_info log_status log_output

## Dependency Information
local name='luajit'
local version='2.1'
local url='https://github.com/LuaJIT/LuaJIT.git'
local hash='7a0cf5fd4c6c841d0455a51271af4fd4390c7884'
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
  case "${target}" {
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

  case ${target} {
    macos-universal)
      autoload -Uz universal_config && universal_config
      return
      ;;
  }

  log_info "Config (%F{3}${target}%f)"
  cd "${dir}"

  mkcd "build_${arch}"
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

  cd "${dir}/build_${arch}"

  case ${target} {
    macos-*)
      args+=(
        XCFLAGS=-DLUAJIT_ENABLE_GC64
        PREFIX="${target_config[output_dir]}"
        CC=clang
        CXX=clang
        TARGET_CFLAGS="${c_flags}"
        TARGET_LDFLAGS="${ld_flags}"
        TARGET_SHLDFLAGS="${ld_flags}"
      )
      ;;
  }

  log_debug "Build options: ${args}"
  PATH="${(j.:.)cc_path}" progress make amalg ${args} -j "${num_procs}" -f ../Makefile
}

install() {
  autoload -Uz progress

  log_info "Install (%F{3}${target}%f)"

  cd "${dir}/build_${arch}"

  PATH="${(j.:.)cc_path}" progress make install PREFIX="${target_config[output_dir]}" -f ../Makefile

  if [[ "${config}" =~ "Release|MinSizeRel" && ${shared_libs} -eq 1 ]] {
    case "${target}" {
      macos-*)
        local file
        for file ("${target_config[output_dir]}"/lib/libluajit*.dylib) {
          if [[ ! -e "${file}" || -h "${file}" ]] continue
          strip -x "${file}"
          log_status "Stripped ${file#"${target_config[output_dir]}"}"
        }
        ;;
    }
  }
}

fixup() {
  autoload -Uz fix_rpaths

  cd "${dir}"

  case ${target} {
    macos*)
      if (( shared_libs )) {
        log_info "Fixup (%F{3}${target}%f)"
        for file ("${target_config[output_dir]}"/lib/libluajit-5.1*.dylib(.)) {
          install_name_tool -id "@rpath/libluajit-5.1.dylib" "${file}"
          log_status "Fixed id of ${file##*/}"
        }
      } else {
        rm "${target_config[output_dir]}"/lib/libluajit-5.1*.dylib(N)
      }
      ;;
  }
}
