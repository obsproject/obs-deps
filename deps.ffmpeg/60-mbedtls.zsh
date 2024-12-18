autoload -Uz log_debug log_error log_info log_status log_output

## Dependency Information
local name='mbedtls'
local -A versions=(
  macos 3.6.2
  linux 3.6.2
  windows 3.6.2
)
local url='https://github.com/Mbed-TLS/mbedtls.git'
local -A hashes=(
  macos 107ea89daaefb9867ea9121002fbbdf926780e98
  linux 107ea89daaefb9867ea9121002fbbdf926780e98
  windows 107ea89daaefb9867ea9121002fbbdf926780e98
)
local -a patches=(
  "macos ${0:a:h}/patches/mbedtls/0001-enable-posix-threading-support.patch \
    ea52cf47ca01211cbadf03c0493986e8d4e0d1e9ab4aaa42365b2dea7b591188"
  "linux ${0:a:h}/patches/mbedtls/0001-enable-posix-threading-support.patch \
    ea52cf47ca01211cbadf03c0493986e8d4e0d1e9ab4aaa42365b2dea7b591188"
  "* ${0:a:h}/patches/mbedtls/0002-enable-dtls-srtp-support.patch \
    c299066df252b8b5a08d169925a82ea6c76d6ae8b6c0069b1bb72ac1d40ba67e"
)

## Dependency Overrides
local -i shared_libs=1

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

  args=(
    ${cmake_flags}
    -DUSE_SHARED_MBEDTLS_LIBRARY="${_onoff[(( shared_libs + 1 ))]}"
    -DUSE_STATIC_MBEDTLS_LIBRARY=ON
    -DENABLE_PROGRAMS=OFF
    -DENABLE_TESTING=OFF
    -DGEN_FILES=OFF
  )

  if [[ ${config} == Release ]] args=(${args//-DCMAKE_C_FLAGS=/-DCMAKE_C_FLAGS=-g })

  log_info "Config (%F{3}${target}%f)"
  cd "${dir}"
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

  _install_pkgconfig
}


_install_pkgconfig() {
  mkdir -p ${target_config[output_dir]}/lib/pkgconfig

  zsh -c "cat <<'EOF' > ${target_config[output_dir]}/lib/pkgconfig/mbedcrypto.pc
prefix=${target_config[output_dir]}
exec_prefix=\${prefix}
libdir=\${exec_prefix}/lib
includedir=\${prefix}/include

Name: mbedcrypto
Description: lightweight crypto and SSL/TLS library.
Version: ${version:-${versions[${target%%-*}]}}
Libs: -L\${libdir} -lmbedcrypto
Cflags: -I\${includedir}
EOF"

  zsh -c "cat <<'EOF' > ${target_config[output_dir]}/lib/pkgconfig/mbedtls.pc
prefix=${target_config[output_dir]}
exec_prefix=\${prefix}
libdir=\${exec_prefix}/lib
includedir=\${prefix}/include

Name: mbedtls
Description: lightweight crypto and SSL/TLS library.
Version: ${version:-${versions[${target%%-*}]}}
Libs: -L\${libdir} -lmbedtls
Cflags: -I\${includedir}
Requires.private: mbedx509
EOF"

  zsh -c "cat <<'EOF' > ${target_config[output_dir]}/lib/pkgconfig/mbedx509.pc
prefix=${target_config[output_dir]}
exec_prefix=\${prefix}
libdir=\${exec_prefix}/lib
includedir=\${prefix}/include

Name: mbedx509
Description: The mbedTLS X.509 library
Version: ${version:-${versions[${target%%-*}]}}
Libs: -L\${libdir} -lmbedx509
Cflags: -I\${includedir}
Requires.private: mbedcrypto
EOF"
}

fixup() {
  cd ${dir}

  log_info "Fixup (%F{3}${target}%f)"

  local strip_tool
  local -a strip_files

  case ${target} {
    macos*)
      if (( shared_libs )) {
        pushd "${target_config[output_dir]}"/lib
        for file (libmbed(crypto|tls|x509).dylib(@)) {
          if [[ -h "${file}" ]] {
            rm "${file}"
            ln -s "${file:r}".*.dylib(.) "${file}"
          }
        }
        popd

        local -a dylib_files=(${target_config[output_dir]}/lib/libmbed*.dylib(.))

        autoload -Uz fix_rpaths && fix_rpaths ${dylib_files}

        sed -E -i '' -e 's#(libmbedcrypto|libmbedx509|libmbedtls).*\.dylib#\1.dylib#' ${target_config[output_dir]}/lib/cmake/MbedTLS/MbedTLSTargets-${config}.cmake

        if [[ ${config} == Release ]] dsymutil ${dylib_files}

        strip_tool=strip
        strip_files=(${dylib_files})
      } else {
        rm -rf -- ${target_config[output_dir]}/lib/libmbed*.(dylib|dSYM)(N)
      }
      ;;
    linux-*)
      if (( shared_libs )) {
        strip_tool=strip
        strip_files=(${target_config[output_dir]}/lib/libmbed*.so.*(.))
      } else {
        rm -rf -- ${target_config[output_dir]}/lib/libmbed*.so.*(N)
      }
      ;;
    windows-x*)
      if (( shared_libs )) {
        mkdir -p ${target_config[output_dir]}/bin
        autoload -Uz create_importlibs
        create_importlibs ${target_config[output_dir]}/bin/libmbed*.dll(.)

        strip_tool=${target_config[cross_prefix]}-w64-mingw32-strip
        strip_files=(${target_config[output_dir]}/bin/libmbed*.dll(.))
      } else {
        rm -rf -- ${target_config[output_dir]}/bin/libmbed*.dll(N)
      }
      ;;
  }

  if (( #strip_files )) && [[ ${config} == (Release|MinSizeRel) ]] ${strip_tool} -x ${strip_files}
}
