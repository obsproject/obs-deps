autoload -Uz log_debug log_error log_info log_status log_output

## Dependency Information
local name='qt6'
local version=6.8.2
local url='https://download.qt.io/archive/qt/6.8/6.8.2'
local hash="${0:a:h}/checksums"
local -a patches=(
  "macos ${0:a:h}/patches/Qt6/mac/0001-QTBUG-121351.patch \
    df46dc93e874c36b2ad0da746c43585528308a7fcde60930c1ffb5e841472e7b"
)

local -a qt_components=(
  'qtbase'
  'qtimageformats'
  'qtshadertools'
  'qtmultimedia'
  'qtserialport'
  'qtsvg'
  'qttools'
)

local dir='qt6'

## Build Steps
setup() {
  autoload -Uz dep_download log_info log_error

  local -a _tarflags=(--strip-components 1)
  if (( _loglevel > 1 )) _tarflags+=(-v)
  _tarflags+=('-xJf')

  local -r source_dir=${PWD}

  for component (${qt_components}) {
    log_info "Setup ${component} (%F{3}${target}%f)"

    local _url="${url}/submodules/${component}-everywhere-src-${version}.tar.xz"
    local _hash="${hash}/${component}-everywhere-src-${version}.tar.xz.sha256"

    log_info "Download ${_url}"
    dep_download ${_url} ${_hash}

    if (( ! ${skips[(Ie)unpack]} )) {
      log_info "Extract ${_url:t}"

      mkdir -p ${dir}/${component}
      pushd ${dir}/${component}
      tar ${_tarflags} ${source_dir}/${_url:t}
      popd
    }
  }
}

clean() {
  cd ${dir}

  if (( ${clean_build} )) {
    build_dirs=(**/build_${arch}(N))

    for _dir (${build_dirs}) {
      log_info "Clean build directory ${dir} (%F{3}${target}%f)"

      rm -rf ${_dir}
    }
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

    if [[ ${target%%-*} == ${~_target} ]] apply_patch ${_url} ${_hash}
  }
}

config() {
  autoload -Uz mkcd progress

  local _onoff=(OFF ON)
  local -a common_cmake_flags=(
    ${cmake_flags//-std=c17/}
    -DBUILD_SHARED_LIBS:BOOL="${_onoff[(( shared_libs + 1 ))]}"
    -DFEATURE_rpath:BOOL="${_onoff[(( shared_libs + 1 ))]}"
  )
  if (( ${+commands[ccache]} )) common_cmake_flags+=(-DQT_USE_CCACHE:BOOL=ON)

  if [[ ${CPUTYPE} != ${arch} && ${host_os} == macos ]] {
    unset VCPKG_ROOT
    if ! /usr/bin/pgrep -q oahd; then
      local -A other_arch=(arm64 x86_64 x86_64 arm64)
      common_cmake_flags+=(-DCMAKE_OSX_ARCHITECTURES:STRING="${CPUTYPE};${other_arch[${CPUTYPE}]}")
    fi
  }

  if (( shared_libs )) && [[ ${config} == Release ]] common_cmake_flags+=(-DQT_FEATURE_force_debug_info:BOOL=ON)
  if (( shared_libs )) && [[ ${config} == Debug ]] common_cmake_flags+=(-DCMAKE_PLATFORM_NO_VERSIONED_SONAME:BOOL=ON)

  args=(
    ${common_cmake_flags}
    -DFEATURE_androiddeployqt:BOOL=OFF
    -DFEATURE_brotli:BOOL=OFF
    -DFEATURE_dbus:BOOL=OFF
    -DFEATURE_doubleconversion:BOOL=ON
    -DFEATURE_glib:BOOL=OFF
    -DFEATURE_jpeg:BOOL=ON
    -DFEATURE_macdeployqt:BOOL=OFF
    -DFEATURE_pcre2:BOOL=ON
    -DFEATURE_pdf:BOOL=OFF
    -DFEATURE_png:BOOL=ON
    -DFEATURE_printsupport:BOOL=OFF
    -DFEATURE_qmake:BOOL=OFF
    -DFEATURE_separate_debug_info:BOOL=ON
    -DFEATURE_sql:BOOL=OFF
    -DFEATURE_system_doubleconversion:BOOL=OFF
    -DFEATURE_system_jpeg:BOOL=OFF
    -DFEATURE_system_pcre2:BOOL=OFF
    -DFEATURE_system_png:BOOL=OFF
    -DFEATURE_system_zlib:BOOL=ON
    -DFEATURE_testlib:BOOL=OFF
    -DFEATURE_windeployqt:BOOL=OFF
    -DINPUT_openssl:STRING=no
    -DQT_BUILD_BENCHMARKS:BOOL=OFF
    -DQT_BUILD_EXAMPLES:BOOL=OFF
    -DQT_BUILD_EXAMPLES_BY_DEFAULT:BOOL=OFF
    -DQT_BUILD_MANUAL_TESTS:BOOL=OFF
    -DQT_BUILD_TESTS:BOOL=OFF
    -DQT_BUILD_TESTS_BY_DEFAULT:BOOL=OFF
    -DQT_BUILD_TOOLS_BY_DEFAULT:BOOL=OFF
    -DQT_CREATE_VERSIONED_HARD_LINK:BOOL=OFF
    -DQT_USE_VCPKG:BOOL=OFF
  )

  log_info "Config qtbase (%F{3}${target}%f)"
  pushd ${dir}/qtbase
  log_debug "CMake configuration options: ${args}'"
  progress cmake -S . -B build_${arch} -G Ninja ${args}
  popd
}

build() {
  autoload -Uz progress

  log_info "Build qtbase (%F{3}${target}%f)"
  pushd ${dir}/qtbase

  args=(
    --build build_${arch}
    --config ${config}
  )

  if (( _loglevel > 1 )) args+=(--verbose)

  cmake ${args}
  popd
}

install() {
  autoload -Uz progress

  log_info "Install qtbase (%F{3}${target}%f)"

  args=(
    --install build_${arch}
    --config ${config}
  )

  if [[ ${config} == (Release|MinSizeRel) ]] args+=(--strip)
  if (( _loglevel > 1 )) args+=(--verbose)

  pushd ${dir}/qtbase
  progress cmake ${args}
  popd

  qt_add_submodules
}

qt_add_submodules() {
  autoload -Uz progress log_info log_error

  local _onoff=(OFF ON)
  local -a common_cmake_flags=(
    ${cmake_flags}
    -DBUILD_SHARED_LIBS:BOOL="${_onoff[(( shared_libs + 1 ))]}"
    -DQT_USE_CCACHE:BOOL=ON
  )

  if [[ ${CPUTYPE} != ${arch} && ${host_os} == macos ]] {
    if ! /usr/bin/pgrep -q oahd; then
      local -A other_arch=(arm64 x86_64 x86_64 arm64)
      common_cmake_flags+=(-DCMAKE_OSX_ARCHITECTURES:STRING="${CPUTYPE};${other_arch[${CPUTYPE}]}")
    fi
  }

  if (( shared_libs )) && [[ ${config} == Release ]] common_cmake_flags+=(-DFEATURE_separate_debug_info:BOOL=ON)
  if (( shared_libs )) && [[ ${config} == Debug ]] common_cmake_flags+=(-DCMAKE_PLATFORM_NO_VERSIONED_SONAME:BOOL=ON)

  for component (${qt_components[2,-1]}) {
    if ! (( ${skips[(Ie)all]} + ${skips[(Ie)build]} )) {
      log_info "Config ${component} (%F{3}${target}%f)"

      local -a _args=(${common_cmake_flags})
      if [[ ${component} == qtimageformats ]] _args+=(-DINPUT_tiff:STRING=qt -DINPUT_webp:STRING=qt)
      if [[ ${component} == qttools ]]; then
        _args+=(
          -DFEATURE_assistant:BOOL=OFF
          -DFEATURE_designer:BOOL=ON
          -DFEATURE_linguist:BOOL=OFF
          -DFEATURE_pixeltool:BOOL=OFF
          -DFEATURE_qtattributionsscanner:BOOL=OFF
          -DFEATURE_qtdiag:BOOL=OFF
          -DFEATURE_qtplugininfo:BOOL=OFF
          -DQT_BUILD_TOOLS_BY_DEFAULT:BOOL=ON
        )
      fi

      pushd ${dir}/${component}
      log_debug "CMake configuration options: ${_args}'"
      progress cmake -S . -B build_${arch} -G Ninja ${_args}

      log_info "Build ${component} (%F{3}${target}%f)"
      args=(
        --build build_${arch}
        --config ${config}
      )

      if (( _loglevel > 1 )) args+=(--verbose)

      cmake ${args}
      popd
    }

    pushd ${dir}/${component}

    args=(
      --install build_${arch}
      --config ${config}
    )

    if [[ ${config} == (Release|MinSizeRel) ]] args+=(--strip)
    if (( _loglevel > 1 )) args+=(--verbose)

    log_info "Install ${component} (%F{3}${target}%f)"
    progress cmake ${args}

    popd
  }
}

fixup() {
  if [[ \
    ${CPUTYPE} != ${arch} && \
    ${target} == macos-(arm64|x86_64) \
    ]] && ! /usr/bin/pgrep -q oahd; then
    local file
    local magic
    local target_arch="${target##*-}"
    local -A other_arch=(arm64 x86_64 x86_64 arm64)

    log_status "Create single-architecture binaries..."
    cd ${target_config[output_dir]}

    local -a fixups=(
      lib/**/(*.a|*.dylib)(.)
      lib/**/*.framework/Versions/A/*(.)
      plugins/**/*.dylib(.)
    )

    for file (bin/**/*(.) libexec/**/*(.)) {
      magic=$(xxd -ps -l 4 ${file})

      if [[ ${magic} == "cafebabe" ]] fixups+=(${file})
    }

    for file (${fixups}) {
      log_status "Slimming ${file}"
      lipo -remove ${other_arch[${target_arch}]} ${file} -output ${file}
    }
  fi
}
