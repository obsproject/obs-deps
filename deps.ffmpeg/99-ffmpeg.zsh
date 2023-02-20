autoload -Uz log_debug log_error log_info log_status log_output

## Dependency Information
local name='FFmpeg'
local version='5.1.2'
local url='https://github.com/FFmpeg/FFmpeg.git'
local hash='eacfcbae690f914a4b1b4ad06999f138540cc3d8'
local -a patches=(
  "* ${0:a:h}/patches/FFmpeg/0001-FFmpeg-5.1.2-OBS.patch \
    7fcb67d5e68a6ca3102c3a6aaba56750b22850552ccd8704c6636c174968ef56"
)

## Build Steps
setup() {
  log_info "Setup (%F{3}${target}%f)"
  setup_dep ${url} ${hash}
}

clean() {
  cd "${dir}"

  if [[ ${clean_build} -gt 0 && -f "build_${arch}/Makefile" ]] {
    log_info "Clean build directory (%F{3}${target}%f)"

    rm -rf "build_${arch}"
  }
}

patch() {
  autoload -Uz apply_patch

  log_info "Patch (%F{3}${target}%f)"

  cd "${dir}"

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

  local -a ff_cflags=()
  local -a ff_cxxflags=()
  local -a ff_ldflags=()

  case ${target} {
    macos-universal)
      autoload -Uz universal_config && universal_config
      return
      ;;
    macos-*)
      local -A hide_libs=(
        xz libzlma
      )

      local lib lib_name lib_file
      for lib (${hide_libs}) {
        read -r lib_name lib_file <<< "${lib}"

        if [[ -d "${HOMEBREW_PREFIX}/opt/${lib_name}" && -h "${HOMEBREW_PREFIX}/lib/${lib_file}" ]] {
          brew unlink "${lib_name}"
        }
      }

      ff_cflags=(
        -I"${target_config[output_dir]}"/include
        -target "${arch}-apple-macos${MACOSX_DEPLOYMENT_TARGET}"
        ${c_flags}
      )
      ff_cxxflags=(
        -I"${target_config[output_dir]}"/include
        -target "${arch}-apple-macos${MACOSX_DEPLOYMENT_TARGET}"
        ${cxx_flags}
      )
      ff_ldflags=(
        -L"${target_config[output_dir]}"/lib
        -target "${arch}-apple-macos${MACOSX_DEPLOYMENT_TARGET}"
        ${ld_flags}
      )

      args+=(
        --cc=clang
        --cxx=clang++
        --host-cc=clang
        --extra-libs="-lstdc++"
        --arch="${arch}"
        --enable-libaom
        --enable-videotoolbox
        --enable-pthreads
        --enable-libtheora
        --enable-libmp3lame
        --enable-rpath
      )

      if [[ ${CPUTYPE} != "${arch}" ]] args+=(--enable-cross-compile)
    ;;
    linux-*)
      ff_cflags=(
        -I"${target_config[output_dir]}"/include
        ${c_flags}
      )
      ff_cxxflags=(
        -I"${target_config[output_dir]}"/include
        ${cxx_flags}
      )
      ff_ldflags=(
        -L"${target_config[output_dir]}"/lib
        ${ld_flags}
      )

      args+=(
        --arch="${arch}"
        --enable-libaom
        --enable-libsvtav1
        --enable-libtheora
        --enable-libmp3lame
        --enable-pthreads
        --extra-libs="-lpthread -lm"
      )

      if (( ${+commands[clang]} )) {
        args+=(
          --cc=clang
          --cxx=clang++
          --host-cc=clang
        )
      }

      if [[ ${CPUTYPE} != "${arch}" ]] args+=(--enable-cross-compile)
      ;;
    windows-x*)
      ff_cflags=(
        -I"${target_config[output_dir]}"/include
        -static-libgcc
        ${c_flags}
      )
      ff_cxxflags=(
        -I"${target_config[output_dir]}"/include
        -static-libgcc
        -static-libstdc++
        ${cxx_flags}
      )
      ff_ldflags=(
        -L"${target_config[output_dir]}"/lib
        -static-libgcc
        -static-libstdc++
        ${ld_flags}
      )

      if (( ! shared_libs )) {
        ff_ldflags+=(-Wl,-Bstatic -pthread)
        args+=(
          --disable-w32threads
          --enable-pthreads
        )
        autoload -Uz hide_dlls && hide_dlls
      } else {
        args+=(
            --enable-w32threads
            --disable-pthreads
          )
      }

      args+=(
        --arch="${target_config[cmake_arch]}"
        --target-os=mingw32
        --cross-prefix="${target_config[cross_prefix]}-w64-mingw32-"
        --pkg-config=pkg-config
        --enable-cross-compile
        --disable-mediafoundation
      )

      if [[ ${arch} == 'x64' ]] args+=(--enable-libaom --enable-libsvtav1)
    ;;
  }

  args+=(
    --prefix="${target_config[output_dir]}"
    --host-cflags="-I${target_config[output_dir]}/include"
    --host-ldflags="-I${target_config[output_dir]}/include"
    --extra-cflags="${ff_cflags}"
    --extra-cxxflags="${ff_cxxflags}"
    --extra-ldflags="${ff_ldflags}"
    --enable-version3
    --enable-gpl
    --enable-libx264
    --enable-libopus
    --enable-libvorbis
    --enable-libvpx
    --enable-librist
    --enable-libsrt
    --enable-shared
    --disable-static
    --disable-libjack
    --disable-indev=jack
    --disable-sdl2
    --disable-doc
    --disable-postproc
  )

  if (( ! shared_libs )) args+=(--pkg-config-flags="--static")

  log_info "Config (%F{3}${target}%f)"
  cd "${dir}"

  mkcd "build_${arch}"

  log_debug "Configure options: ${args}"
  PKG_CONFIG_LIBDIR="${target_config[output_dir]}/lib/pkgconfig" \
  LD_LIBRARY_PATH="${target_config[output_dir]}/lib" \
  PATH="${(j.:.)cc_path}" \
  progress ../configure ${args}
}

build() {
  autoload -Uz mkcd progress

  case ${target} {
    macos-universal)
      autoload -Uz universal_build && universal_build
      return
      ;;
  }

  log_info "Build (%F{3}${target}%f)"
  cd "${dir}/build_${arch}"

  log_debug "Running make -j ${num_procs}"
  PATH="${(j.:.)cc_path}" progress make -j "${num_procs}"
}

install() {
  autoload -Uz progress

  log_info "Install (%F{3}${target}%f)"

  if [[ ${target} == 'macos-universal' ]] {
    cd "${dir}/build_${CPUTYPE}"
  } else {
    cd "${dir}/build_${arch}"
  }

  make install

  _fixup_ffmpeg
}

function _fixup_ffmpeg() {
  autoload -Uz fix_rpaths create_importlibs
  log_info "Fixup (%F{3}${target}%f)"

  case ${target} {
    macos*)
      local -A other_arch=(arm64 x86_64 x86_64 arm64)
      local cross_lib
      local lib

      if [[ ${arch} == 'universal' ]] {
        log_info "Create universal binaries"
        for lib ("${target_config[output_dir]}"/lib/lib(sw|av|postproc)*.dylib(.)) {
          if [[ ! -e ${lib} || -h ${lib} ]] continue

          cross_lib=("../build_${other_arch[${CPUTYPE}]}/**/${~${lib##*/}%%.*}*.dylib(.)")

          lipo -create ${lib} ${~cross_lib[1]} -output ${lib}
          log_status "Combined ${lib##*/}"
        }
      }

      fix_rpaths "${target_config[output_dir]}"/lib/lib(sw|av|postproc)*.dylib
      ;;
    windows-x*)
      mv "${target_config[output_dir]}"/bin/(sw|av|postproc)*.lib "${target_config[output_dir]}"/lib

      if (( ! shared_libs )) { autoload -Uz restore_dlls && restore_dlls }
      ;;
  }
}
