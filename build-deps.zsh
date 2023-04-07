#!/usr/bin/env zsh

builtin emulate -L zsh
setopt EXTENDED_GLOB
setopt PUSHD_SILENT
setopt ERR_EXIT
setopt ERR_RETURN
setopt NO_UNSET
setopt PIPE_FAIL
setopt NO_AUTO_PUSHD
setopt NO_PUSHD_IGNORE_DUPS
setopt FUNCTION_ARGZERO
#setopt WARN_CREATE_GLOBAL
#setopt WARN_NESTED_VAR
#setopt XTRACE

run_stages() {
  local -a stages=()
  local dependency

  if (( ${skips[(Ie)all]} + ${skips[(Ie)build]} )) {
    stages+=(install fixup)
  } else {
    stages=(setup)
    if (( clean_build )) stages+=(clean)
    stages+=(patch config build install fixup)
  }

  for dependency (${files}) {
    function {
      local version url hash dir
      local -A versions hashes urls
      local -a patches
      local -a args=()
      local arch="${target_config[arch]}"
      local targets=(${target})

      source "${SCRIPT_HOME}/${dependency}"

      if [[ ! ${target} =~ "${(j:|:)targets}" ]] continue

      : ${version:=${versions[${target%%-*}]}}
      : ${url:=${urls[${target%%-*}]}}
      : ${hash:=${hashes[${target%%-*}]}}
      : ${dir:=${${url##*/}%.*.*}}

      if [[ "${url##*.}" == "git" ]] dir="${name}-${version}"

      local stage_name="${name}"

      log_output "Initializing build"

      for stage (${stages}) {
        pushd ${PWD}
        if (( ${+functions[${stage}]} )) {
          ${stage}
          unset -f ${stage}
        }
        popd
      }

      if [[ -d ${SCRIPT_HOME}/licenses/${name} ]] {
        log_status "Install license files"
        mkdir -p ${target_config[output_dir]}/licenses/${name} && cp -pR ${SCRIPT_HOME}/licenses/${name} ${target_config[output_dir]}/licenses/
      }

      log_output "%F{2}DONE%f"
    }
  }
}

package() {
  autoload -Uz log_info log_status
  if [[ ${PACKAGE_NAME} == 'qt'* ]] {
    local filename="${target%%-*}-deps-${PACKAGE_NAME}-${current_date}-${target_config[arch]}.tar.xz"
  } else {
    local filename="${target%%-*}-${PACKAGE_NAME}-${current_date}-${target_config[arch]}.tar.xz"
  }

  pushd ${PWD}
  cd ${target_config[output_dir]}

  log_info "Package dependencies"

  if [[ ${PACKAGE_NAME} != 'qt'* ]] {
    log_status "Cleanup unnecessary files"

    rm -rf lib/^(*.dylib|libajantv*|*.a|*.so*|*.lib|*.framework|*.dSYM|cmake)(N)
    rm -rf lib/(libpcre*|libpng*)(N)
    rm -rf bin/^(*.exe|*.dll|*.pdb|swig)(N)

    if [[ -f bin/swig ]] {
      swig_lib=(share/swig/*(/))
      pushd ${swig_lib:h}
      ln -sf ${swig_lib:t} CURRENT
      popd
    }

    if [[ -d share ]] rm -rf share/^(swig|cmake)(N)
    if [[ -d cmake ]] rm -rf cmake
    if [[ -d man ]] rm -rf man

  }
  mkdir -p share/obs-deps
  echo "${current_date}" >! share/obs-deps/VERSION

  log_status "Create archive ${filename}"
  local -a _tarflags=()
  if (( _loglevel > 1 )) _tarflags+='-v'
  _tarflags+=(-cJf)

  XZ_OPT=-T0 tar ${_tarflags} ${filename} -- *

  mv -- ${filename} ${PWD:A:h}
}

build_dependencies() {
  autoload -Uz mkcd log_debug log_output

  if (( ! ${+SCRIPT_HOME} )) typeset -g SCRIPT_HOME=${0:A:h}

  if (( ! ${+PACKAGE_NAME} )) typeset -g PACKAGE_NAME=${${(s:-:)ZSH_ARGZERO:t:r}[2]}

  source "${SCRIPT_HOME}"/utils.zsh/10-bootstrap.zsh

  trap '_trap_exit ${deps}' EXIT
  trap '_trap_error' ZERR

  bootstrap "${@}"

  local subdir
  if [[ ${PACKAGE_NAME} == 'ffmpeg' ]] {
    subdir='deps.ffmpeg'
  } elif [[ ${PACKAGE_NAME} == 'qt'* ]] {
    subdir='deps.qt'
  } else {
    subdir="deps.${host_os}"
  }

  local -a files
  if (( #deps )) {
    files=(${subdir}/*-(${~${(j:|:)deps}}).zsh)
  } elif [[ ${PACKAGE_NAME} == 'qt'* ]] {
    files=(${subdir}/${PACKAGE_NAME}.zsh)
  } else {
    files=(${subdir}/*-*.zsh)
  }

  log_debug "Using found dependency scripts:\n + ${(j:\n + :)files}"

  pushd ${PWD}
  mkcd ${work_root}
  run_stages
  popd

  if (( ! #deps )) package
}

build_dependencies "${@}"
