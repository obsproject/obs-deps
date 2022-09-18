autoload -Uz log_debug log_error log_info log_status log_output

## Dependency Information
local name='qt5'
local version=5.15.5
local url='https://download.qt.io/official_releases/qt/5.15/5.15.5'
local hash="${0:a:h}/checksums"
local -a patches=(
  "macos ${0:a:h}/patches/Qt5/0001-QTBUG-74606.patch \
    6ba73e94301505214b85e6014db23b042ae908f2439f0c18214e92644a356638"
  "macos ${0:a:h}/patches/Qt5/0003-QTBUG-90370.patch \
    277b16f02f113e60579b07ad93c35154d7738a296e3bf3452182692b53d29b85"
  "macos ${0:a:h}/patches/Qt5/0004-QTBUG-70137-1.patch \
    216be72245a80b7762dc2e2bd720a4ea9b9c423ce9d006cce3985b63c0269ba3"
  "macos ${0:a:h}/patches/Qt5/0005-QTBUG-70137-2.patch \
    92d49352c321c653d6f5377e64603e48b38a9c1ec87a8956acba42459c151e42"
  "macos ${0:a:h}/patches/Qt5/0006-QTBUG-70137-3.patch \
    f8b220a444fcd0e121b8643e7526af33a4f30e0c85d11c28d40fcc7072d56783"
  "macos ${0:a:h}/patches/Qt5/0007-QTBUG-97855.patch \
    d8620262ad3f689fdfe6b6e277ddfdd3594db3de9dbc65810a871f142faa9966"
  "macos ${0:a:h}/patches/Qt5/0008-fix-sdk-version-check.patch \
    167664bed786baf67902dce7ed63570cbc6a13f52f446e1a95d3a6991c89c274"
)

local -a qt_components=(
  qtbase
  qtimageformats
  qtmultimedia
  qtsvg
  qtserialport
)
local dir='qt5'

## Build Steps
setup() {
  if [[ ${shared_libs} -eq 0 && ${CPUTYPE} != "${arch}" ]] {
    log_error "Cross compilation requires shared library build"
    exit 2
  }

  autoload -Uz dep_download

  local -a _tarflags=(--strip-components 1)
  if (( _loglevel > 1 )) _tarflags+=(-v)
  _tarflags+=('-xJf')

  local -r source_dir=${PWD}

  for component (${qt_components}) {
    log_info "Setup ${component} (%F{3}${target}%f)"

    local _url="${url}/submodules/${component}-everywhere-opensource-src-${version}.tar.xz"
    local _hash="${hash}/${component}-everywhere-opensource-src-${version}.tar.xz.sha256"

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

    for dir (${build_dirs}) {
      log_info "Clean build directory ${dir} (%F{3}${target}%f)"

      rm -rf ${dir}
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
  if [[ ${target} == 'macos-universal' ]] {
    universal_qt_config
    return
  }
  qt_config
}

qt_config() {
  autoload -Uz mkcd progress

  case ${config} {
    Debug) args+=(-debug) ;;
    RelWithDebInfo) args+=(-release -force-debug-info -separate-debug-info) ;;
    Release) args+=(-release -strip) ;;
    MinSizeRel) args+=(-release -optimize-size -strip) ;;
  }

  args+=(
    --prefix="${target_config[output_dir]}"
    -opensource
    -confirm-license
    -qt-libpng
    -qt-libjpeg
    -qt-freetype
    -qt-pcre
    -nomake examples
    -nomake tests
    -no-compile-examples
    -no-dbus
    -no-glib
    -system-zlib
    -c++std c++17
    -DQT_NO_PDF
    -DQT_NO_PRINTER
    ${${commands[ccache]}:+-ccache}
  )

  if (( _loglevel > 1 )) {
    args+=(-verbose)
  } elif (( ! _loglevel )) {
    args+=(-silent)
  }

  if (( shared_libs )) {
    args+=(-shared -rpath)
  } else {
    args+=(-no-shared -static)
  }

  local part
  for part ('itemmodeltester' 'printdialog' 'printer' 'printpreviewdialog' 'printpreviewwidget'
    'sql' 'sqlmodel' 'testlib') {
    args+=("-no-feature-${part}")
  }

  args+=(QMAKE_APPLE_DEVICE_ARCHS="${arch}")

  log_status "Hide undesired libraries from qt..."
  if [[ -d "${HOMEBREW_PREFIX}/opt/zstd" ]] brew unlink zstd

  log_info "Config qtbase (%F{3}${target}%f)"

  mkcd ${dir}/qtbase/build_${arch}

  log_debug "Configure options: ${args}"
  ../configure ${args}
}

build() {
  autoload -Uz mkcd progress

  if [[ ${target} == 'macos-universal' ]] {
    universal_qt_build
    return
  }

  if [[ ${CPUTYPE} != "${arch}" ]] {
    cross_prepare
  }

  local -r source_dir=${PWD}

  for component (${qt_components}) {
    log_info "Build ${component} (%F{3}${target}%f)"
    mkdir -p ${dir}/${component}/build_${arch}
    pushd ${dir}/${component}/build_${arch}

    if [[ ${component} != 'qtbase' ]] {
      log_debug "Running qmake"
      ${source_dir}/${dir}/qtbase/build_${arch}/bin/qmake ..
    }

    log_debug "Running make -j ${num_procs}"
    progress make -j "${num_procs}"
    popd

  }
}

install() {
  autoload -Uz progress

  if [[ ${target} == 'macos-universal' ]] {
    universal_install
    universal_fixup
    return
  }

  for component (${qt_components}) {
    log_info "Install ${component} (%F{3}${target}%f)"
    pushd ${dir}/${component}/build_"${arch}"
    progress make install
    popd
  }

  if [[ ${CPUTYPE} != "${arch}" ]] {
    cp -cp ${dir}/qtbase/build_${arch}/bin/qmake "${target_config[output_dir]}/bin/"

    for file (
      'lib/QtCore.framework/Versions/5/QtCore'
      'lib/libQt5Bootstrap.a'
      'bin/moc'
      'bin/qvkgen'
      'bin/rcc'
      'bin/uic'
      'bin/qmake'
      'bin/qlalr'
    ) {
      lipo "${target_config[output_dir]}/${file}" \
        -thin ${arch} \
        -output "${target_config[output_dir]}/${file}"
    }
  }
}

fixup() {
  if [[ -d "${HOMEBREW_PREFIX}/opt/zstd" && ! -h "${HOMEBREW_PREFIX}/lib/libzstd.dylib" ]] brew link zstd
}

cross_prepare() {
  autoload -Uz progress

  pushd ${PWD}

  if [[ ! -f ${dir}/qtbase/build_${CPUTYPE}/lib/QtCore.framework/Versions/5/QtCore ]] {
    log_status "Build QtCore (macos-${CPUTYPE})..."

    pushd ${PWD}
    (
      arch=${CPUTYPE}
      target="macos-${CPUTYPE}"
      args=()

      qt_config

      progress make -j ${num_procs} qmake_all

      pushd src
      progress make -j ${num_procs} sub-moc-all
      progress make -j ${num_procs} sub-corelib
      popd
    )
    popd
  }

  pushd ${dir}/qtbase/build_${arch}
  if ! ([[ -f bin/qmake ]] && lipo -archs bin/qmake | grep "${arch}" &> /dev/null); then
    pushd ${PWD}
    log_info "Fix qmake to enable building ${arch} on ${CPUTYPE} host"

    log_status "Apply patches to qmake makefile..."
    apply_patch "${funcfiletrace[1]:a:h}/patches/Qt5/0009-qmake-append-cflags-and-ldflags.patch" \
      "6c880f3b744222ed2ac2eb5bca0ff0ba907e1d77605ad4b06f814e4d5813e496"

    log_status "Remove thin qmake"
    rm bin/qmake
    cd qmake
    progress make clean

    log_status "Build qmake..."
    EXTRA_LFLAGS="-arch arm64 -arch x86_64" \
    EXTRA_CXXFLAGS="-arch arm64 -arch x86_64" \
    progress make -j ${num_procs} qmake
    popd
  fi

  # we need to build some tools universal so we can cross compile on x86 host
  log_status "Build Qt build tools..."
  progress make -j ${num_procs} qmake_all

  # Modify Makefiles so we can specify ARCHS
  local fixup
  for fixup (src/**/Makefile) {
    log_status "Patching ${fixup}"
    sed -i '.orig' "s/EXPORT_VALID_ARCHS =/EXPORT_VALID_ARCHS +=/" ${fixup}
  }

  log_status "Build Qt tools (part 1)..."
  pushd ${PWD}
  cd src
  ARCHS="arm64 x86_64" EXPORT_VALID_ARCHS="arm64 x86_64" progress make -j ${num_procs} sub-moc-all

  # QtCore sadly does not build universal so we build it for both archs, lipo them,
  # then continue building all of the other tools we need
  log_status "Build QtCore..."
  progress make -j ${num_procs} sub-corelib
  popd

  log_status "Create universal QtCore..."
  if lipo -archs "lib/QtCore.framework/Versions/5/QtCore" \
    | grep "${CPUTYPE}" >/dev/null 2>&1; then
      log_info "Target architecture ${CPUTYPE} already found, will remove"
      lipo -remove ${CPUTYPE} "lib/QtCore.framework/Versions/5/QtCore" \
        -output "lib/QtCore.framework/Versions/5/QtCore"
  fi

  lipo -create "../build_${CPUTYPE}/lib/QtCore.framework/Versions/5/QtCore" \
    "lib/QtCore.framework/Versions/5/QtCore" \
    -output "lib/QtCore.framework/Versions/5/QtCore"

  log_status "Build Qt tools (part 2)..."
  pushd ${PWD}
  cd src
  ARCHS="arm64 x86_64" EXPORT_VALID_ARCHS="arm64 x86_64" \
    progress make -j ${num_procs} sub-qvkgen-all sub-rcc sub-uic sub-qlalr
  popd
  popd
}

universal_qt_config() {
  local a
  local -A other_arch=( arm64 x86_64 x86_64 arm64 )

  for a (${CPUTYPE} ${other_arch[${CPUTYPE}]}) {
    (
      arch="${a}"
      target="${target//universal/${a}}"
      args=()
      target_config=(${(kv)target_config//universal/${a}})
      qt_config
    )
  }
}

universal_qt_build() {
  local a
  local -A other_arch=( arm64 x86_64 x86_64 arm64 )

  for a (${CPUTYPE} ${other_arch[${CPUTYPE}]}) {
    (
      arch="${a}"
      target="${target//universal/${a}}"
      args=()
      target_config=(${(kv)target_config//universal/${a}})
      build
    )
  }
}

universal_install() {
  local a
  local -A other_arch=( arm64 x86_64 x86_64 arm64 )
  for a (${CPUTYPE} ${other_arch[${CPUTYPE}]}) {
    (
      arch="${a}"
      target="${target//universal/${a}}"
      target_config=(${(kv)target_config//universal/${a}})
      install
    )
  }
}

universal_fixup() {
  local file
  local magic

  log_status "Create universal binaries..."
  rm -rf "${target_config[output_dir]}"
  cp -cpR "${${target_config[output_dir]}//universal/arm64}" "${target_config[output_dir]}"
  cd ${target_config[output_dir]}

  # Using arm64 as the source build, find any file starting with magic bytes for thin binary

  local -a fixups=(
    lib/**/(*.a|*.dylib)(.)
    lib/**/*.framework/Versions/(5|6)/*(.)
    plugins/**/*.dylib(.)
    )

  for file (bin/**/*(.)) {
    magic=$(xxd -ps -l 4 ${file})

    if [[ ${magic} == "cffaedfe" ]] fixups+=(${file})
  }

  for file (${fixups}) {
    log_status "Combining ${file}..."
    lipo -create \
      "${${target_config[output_dir]}//universal/arm64}/${file}" \
      "${${target_config[output_dir]}//universal/x86_64}/${file}" \
      -output ${file}
  }
}
