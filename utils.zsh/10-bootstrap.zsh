autoload -Uz is-at-least && if ! is-at-least 5.2; then
  print -u2 -PR "%F{1}${funcstack[1]##*/}:%f Running on Zsh version %B${ZSH_VERSION}%b, but Zsh %B5.2%b is the minimum supported version. Upgrade Zsh to fix this issue."
  return 1
fi

_trap_error() {
  print -u2 -PR '%F{1}    ✖︎ script execution error%f'
  print -PR -e "
    Callstack:
    ${(j:\n     :)funcfiletrace}
  "
  exit 2
}

_trap_exit() {
  if (( ${+functions[cleanup]} )) cleanup
}

bootstrap() {
  if (( ! ${+SCRIPT_HOME} )) typeset -g SCRIPT_HOME="${funcfiletrace[1]:A:h}"

  local module
  for module (${SCRIPT_HOME}/utils.zsh/(*~${0:r}).zsh) {
    source "${module}"
  }

  fpath=("${SCRIPT_HOME}/utils.zsh/functions" ${fpath})

  autoload -Uz log_output log_error log_info log_debug set_loglevel log_warning

  typeset -g stage_name
  typeset -g target="${host_os}-${CPUTYPE}"
  typeset -g config="Release"
  typeset -g -a deps=()
  typeset -g -a skips=()
  typeset -g -i shared_libs=0
  typeset -g -i clean_build=0
  typeset -g -r current_date=$(date +"%Y-%m-%d")

  local -i _verbosity=1

  local -r _version='0.0.1'
  local -r -a _valid_targets=(
    macos-x86_64
    macos-arm64
    macos-universal
    windows-x64
    windows-x86
    linux-x86_64
  )
  local -r -a _valid_configs=(Debug RelWithDebInfo Release MinSizeRel)
  local -r _usage="
Usage: %B${functrace[1]%:*}%b <option> [<options>]

%BOptions%b:

%F{yellow} Build configuration options%f
 -----------------------------------------------------------------------------
  %B-t | --target%b                     Specify target - default: %B%F{green}${host_os}-${CPUTYPE}%f%b
  %B-c | --config%b                     Build configuration - default: %B%F{green}Release%f%b
  %B-s | --shared%b                     Build dynamic library variant (if available)

%F{yellow} Output options%f
 -----------------------------------------------------------------------------
  %B-q | --quiet%b                      Quiet (error output only)
  %B-v | --verbose%b                    Verbose (more detailed output)

%F{yellow} Script options%f
 -----------------------------------------------------------------------------
  %B--clean%b                           Clean existing build folders
  %B--skip-[all|build|deps|unpack]%b    Skip installation of build dependencies
  %B--debug%b                           Debug (very detailed and added output)

%F{yellow} General options%f
 -----------------------------------------------------------------------------
  %B-h | --help%b                       Print this usage help
  %B-V | --version%b                    Print script version information"

  local -a args
  while (( # )) {
    case ${1} {
      -t|--target|-c|--config)
        if (( # == 1 )) || [[ ${2:0:1} == "-" ]] {
          log_error "Missing value for option %B${1}%b"
          log_output ${_usage}
          exit 2
        }
        ;;
    }
    case ${1} {
      --)
        shift
        args+=($@)
        break
        ;;
      -t|--target)
        if (( ! ${_valid_targets[(Ie)${2}]} )) {
          log_error "Invalid value %B${2}%b for option %B${1}%b"
          log_output ${_usage}
          exit 2
        }
        target=${2}
        shift 2
        ;;
      -c|--config)
        if (( ! ${_valid_configs[(Ie)${2}]} )) {
          log_error "Invalid value %B${2}%b for option %B${1}%b"
          log_output ${_usage}
          exit 2
        }
        config=${2}
        shift 2
        ;;
      -s|--shared) shared_libs=1; shift ;;
      -q|--quiet) (( _verbosity -= 1 )) || true; shift ;;
      -v|--verbose) (( _verbosity += 1 )); shift ;;
      --clean) clean_build=1; shift ;;
      --skip-*)
        local _skip="${${(s:-:)1}[-1]}"
        local _check=(all deps unpack build)
        (( ${_check[(Ie)${_skip}]} )) || log_warning "Invalid skip mode %B${_skip}%b supplied"
        skips+=(${_skip})
        shift
        ;;
      --debug) _verbosity=3; shift ;;
      -h|--help) log_output ${_usage}; exit 0 ;;
      -V|--version) log_output ${_version}; exit 0 ;;
      -*) log_error "Unknown option: %B${1}%b"; log_output ${_usage}; exit 2 ;;
      *) deps+=(${1}); shift ;;
    }
  }

  set -- ${(@)args}

  set_loglevel ${_verbosity}

  local _yesno=('%F{1}No%f' '%F{2}Yes%f')
  if (( #deps )) {
    local _deplist="%BDependencies:%b ${(j:,:)deps}"
  } else {
    local _deplist=""
  }

  log_output "
  ---------------------------------------------------------------------------------------------------
  %B[OBS-DEPS]%b - configuration %F{2}${config}%f, target %F{2}${target}%f, shared libraries: ${_yesno[(( shared_libs +1 ))]}
  ${_deplist}
  ---------------------------------------------------------------------------------------------------
  "

  function _trap_exit() {
    typeset -g _padding=0

    if (( ! #1 )) set -- "All"

    log_output "
  ---------------------------------------------------------------------------------------------------
  %B[OBS-DEPS]%b %F{2}All done%f
  %BBuilt dependencies:%b ${1}
  ---------------------------------------------------------------------------------------------------
    "
  }

  setup_host
  setup_target ${target}
  setup_build_parameters ${target} ${config}
}
