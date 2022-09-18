autoload -Uz log_debug log_error log_info log_status log_output

## Dependency Information
local name='qt6'
local version=6.3.1
local url='https://download.qt.io/official_releases/qt/6.3/6.3.1'
local hash="${0:a:h}/checksums"
local -a patches=()

local -a qt_components=(
  'qtbase'
  'qtimageformats'
  'qtshadertools'
  'qtmultimedia'
  'qtsvg'
  'qtserialport'
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

    if [[ "${target%%-*}" == ${~_target} ]] apply_patch "${_url}" "${_hash}"
  }
}

config() {
  autoload -Uz mkcd progress

  local _onoff=(OFF ON)
  local -a common_cmake_flags=(
    ${cmake_flags}
    -DBUILD_SHARED_LIBS="${_onoff[(( shared_libs + 1 ))]}"
  )
  if (( ${+commands[ccache]} )) common_cmake_flags+=(-DQT_USE_CCACHE=ON)

  if [[ ${CPUTYPE} != "${arch}" && ${host_os} == 'macos' ]] {
    unset VCPKG_ROOT
    if ! /usr/bin/pgrep -q oahd; then
      local -A other_arch=(arm64 x86_64 x86_64 arm64)
      common_cmake_flags+=(-DCMAKE_OSX_ARCHITECTURES="${CPUTYPE};${other_arch[${CPUTYPE}]}")
    fi
  }

  if [[ ${config} == 'RelWithDebInfo' ]] common_cmake_flags+=(-DFEATURE_separate_debug_info=ON)

  args=(
    ${common_cmake_flags}
    -DFEATURE_brotli=OFF
    -DFEATURE_cups=OFF
    -DFEATURE_dbus=OFF
    -DFEATURE_glib=OFF
    -DFEATURE_itemmodeltester=OFF
    -DFEATURE_macdeployqt=OFF
    -DFEATURE_windeployqt=OFF
    -DFEATURE_androiddeployqt=OFF
    -DFEATURE_printsupport=OFF
    -DFEATURE_printer=OFF
    -DFEATURE_printdialog=OFF
    -DFEATURE_printpreviewdialog=OFF
    -DFEATURE_printpreviewwidget=OFF
    -DFEATURE_qmake=OFF
    -DFEATURE_rpath=ON
    -DFEATURE_sql=OFF
    -DFEATURE_system_zlib=ON
    -DINPUT_libjpeg=qt
    -DINPUT_libpng=qt
    -DINPUT_pcre=qt
    -DINPUT_doubleconversion=qt
    -DINPUT_libmd4c=qt
    -DFEATURE_openssl=OFF
    -DQT_BUILD_BENCHMARKS=OFF
    -DQT_BUILD_EXAMPLES=OFF
    -DQT_BUILD_EXAMPLES_BY_DEFAULT=OFF
    -DQT_BUILD_MANUAL_TESTS=OFF
    -DQT_BUILD_TESTS=OFF
    -DQT_BUILD_TOOLS_BY_DEFAULT=OFF
    -DQT_CREATE_VERSIONED_HARD_LINK=OFF
  )

  log_info "Config qtbase (%F{3}${target}%f)"
  pushd ${dir}/qtbase
  log_debug "CMake configuration options: ${args}'"
  progress cmake -S . -B "build_${arch}" -G Ninja ${args}
  popd
}

build() {
  autoload -Uz progress

  log_info "Build qtbase (%F{3}${target}%f)"
  pushd ${dir}/qtbase

  args=(
    --build "build_${arch}"
    --config "${config}"
  )

  if (( _loglevel > 1 )) args+=(--verbose)

  cmake ${args}
  popd
}

install() {
  autoload -Uz progress

  log_info "Install qtbase (%F{3}${target}%f)"

  args=(
    --install "build_${arch}"
    --config "${config}"
  )

  if [[ "${config}" =~ "Release|MinSizeRel" ]] args+=(--strip)
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
    -DBUILD_SHARED_LIBS="${_onoff[(( shared_libs + 1 ))]}"
    -DQT_USE_CCACHE=ON
  )

  if [[ ${CPUTYPE} != "${arch}" && ${host_os} == 'macos' ]] {
    if ! /usr/bin/pgrep -q oahd; then
      local -A other_arch=(arm64 x86_64 x86_64 arm64)
      common_cmake_flags+=(-DCMAKE_OSX_ARCHITECTURES="${CPUTYPE};${other_arch[${CPUTYPE}]}")
    fi
  }

  if [[ ${config} == 'RelWithDebInfo' ]] common_cmake_flags+=(-DFEATURE_separate_debug_info=ON)

  for component (${qt_components[2,-1]}) {
    if ! (( ${skips[(Ie)all]} + ${skips[(Ie)build]} )) {
      log_info "Config ${component} (%F{3}${target}%f)"

      local -a _args=(${common_cmake_flags})
      if [[ ${component} == 'qtimageformats' ]] _args+=(-DINPUT_tiff=qt -DINPUT_webp=qt)

      pushd ${dir}/${component}
      log_debug "CMake configuration options: ${_args}'"
      progress cmake -S . -B "build_${arch}" -G Ninja ${_args}

      log_info "Build ${component} (%F{3}${target}%f)"
      args=(
        --build "build_${arch}"
        --config "${config}"
      )

      if (( _loglevel > 1 )) args+=(--verbose)

      cmake ${args}
      popd
    }

    pushd ${dir}/${component}

    args=(
      --install "build_${arch}"
      --config "${config}"
    )

    if [[ "${config}" =~ "Release|MinSizeRel" ]] args+=(--strip)
    if (( _loglevel > 1 )) args+=(--verbose)

    log_info "Install ${component} (%F{3}${target}%f)"
    progress cmake ${args}

    popd
  }
}

fixup() {
  if [[ \
    ${CPUTYPE} != "${arch}" && \
    ${target} =~ "macos-[arm64|x86_64]" \
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
