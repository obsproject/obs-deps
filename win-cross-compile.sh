#!/bin/bash
export SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

# Might be worth it to try no prefix generation?
# -DCMAKE_SHARED_LIBRARY_PREFIX= \
# -DCMAKE_SHARED_LIBRARY_SUFFIX= \
# -DCMAKE_SHARED_MODULE_PREFIX= \
# -DCMAKE_SHARED_MODULE_SUFFIX= \
# -DCMAKE_STATIC_LIBRARY_PREFIX= \
# -DCMAKE_STATIC_LIBRARY_SUFFIX= \
# -DCMAKE_IMPORT_LIBRARY_PREFIX= \
# -DCMAKE_IMPORT_LIBRARY_SUFFIX= \

# Options
OPT_LOGLEVEL=0
OPT_TARGET=
OPT_BUILDDIR=
OPT_OUTPUTDIR=
OPT_DEPDIR=
OPT_SOLO=FALSE

# Steps
declare -A STEPS
STEPS["apt"]=""
STEPS["zlib"]="apt"
STEPS["mbedtls"]="apt zlib"
#STEPS["curl"]="apt mbedtls zlib"
STEPS["curl"]="apt"
#STEPS["libpng"]="apt zlib"
STEPS["libpng"]="apt"
STEPS["x264"]="apt"
STEPS["ogg"]="apt"
#STEPS["vorbis"]="apt ogg"
STEPS["vorbis"]="apt"
STEPS["opus"]="apt"
STEPS["vpx"]="apt"
#STEPS["srt"]="apt mbedtls"
STEPS["srt"]="apt"
STEPS["nvenc"]="apt"
#STEPS["ffmpeg"]="apt nvenc srt vpx opus vorbis x264 zlib libpng mbedtls"
STEPS["ffmpeg"]="apt nvenc"
#STEPS["freetype"]="apt libpng zlib"
STEPS["freetype"]="apt"
#STEPS["websockets"]="apt mbedtls"
STEPS["websockets"]="apt"
#STEPS["luajit"]="apt"
STEPS["python"]="apt"
STEPS["swig"]="apt"
#STEPS["package"]="zlib mbedtls curl libpng ffmpeg freetype swig"
#STEPS["package"]="zlib mbedtls"
#STEPS["all"]="package"

# Storage
declare -A _MYENV
declare -A STEPS_COMPLETED

# Argument Function
function arguments {
	# --long "help,verbose"
	OPTIONS=$(getopt -l "help,verbose,quiet,target:,output:,build:,solo" -o "hvqt:o:b:s" -- $*)
	if [ $? -ne 0 ]; then
		return 1
	fi
	eval set -- "${OPTIONS}"
	SHIFT=0
	while [ "${1+exists}" == "exists" ]; do
		case "$1" in
		-h|--help)
cat << EOF
Usage: $0 [options] -- <step> [<step> ...]
Available Options:
  -q,--quiet                 Decrease verbosity (can be used multiple times).
  -v,--verbose               Increase verbosity (can be used multiple times).
  -t,--target ...            Set the target architecture.
      win32                      32-bit Windows
      win64                      64-bit Windows
  -o,--output <path>         Output directory for final binaries.
  -b,--build <path>          Build directory to use during building.
  -d,--deps <path>           Path to dependencies of the step.
  -s,--solo                  Do not build any dependencies, only the given steps.
EOF
			exit 0
			;;
		-v|--verbose)
			OPT_LOGLEVEL=$((OPT_LOGLEVEL + 1))
			;;
		-q|--quiet)
			OPT_LOGLEVEL=$((OPT_LOGLEVEL - 1))
			;;
		-t|--target)
			case "$2" in
			win32|win64)
				OPT_TARGET=$2
				;;
			*)
				echo "Unknown target: $2"
				return 1
			esac
			SHIFT=$((SHIFT + 1))
			shift
			;;
		-o|--output)
			OPT_OUTPUTDIR=$2
			SHIFT=$((SHIFT + 1))
			shift
			;;
		-b|--build)
			OPT_BUILDDIR=$2
			SHIFT=$((SHIFT + 1))
			shift
			;;
		-d|--deps)
			OPT_DEPDIR=$2
			SHIFT=$((SHIFT + 1))
			shift
			;;
		-s|--solo)
			OPT_SOLO=TRUE
			;;
		--)
			SHIFT=$((SHIFT + 1))
			shift
			break
			;;
		esac
		SHIFT=$((SHIFT + 1))
		shift
	done
	
	# Default Values
	if [ "$OPT_TARGET" == "" ]; then
		OPT_TARGET=win64
	fi
	if [ "$OPT_BUILDDIR" == "" ]; then
		OPT_BUILDDIR=${SCRIPT_DIR}/build/${OPT_TARGET}
	fi
	if [ "$OPT_DEPDIR" == "" ]; then
		OPT_DEPDIR=${OPT_BUILDDIR}
	fi
	if [ "$OPT_OUTPUTDIR" == "" ]; then
		OPT_OUTPUTDIR=${SCRIPT_DIR}/build/${OPT_TARGET}-bin
	fi

	# Set up Environment
	setup_env

	# Show Options
	if can_log_config; then
		echo "Options:"
		echo "  Target: ${OPT_TARGET} (${_TARGET})"
		echo "  Build Dir: ${OPT_BUILDDIR}"
		echo "  Output Dir: ${OPT_OUTPUTDIR}"
	fi

	return $SHIFT
}

# Helper Functions
function is_solo {
	if [ $OPT_SOLO == TRUE ]; then return 0; fi
	return 1
}

## Log Level Tests
function can_log_info {
	if [ $OPT_LOGLEVEL -ge 0 ]; then return 0; fi
	return 1
}

function can_log_config {
	if [ $OPT_LOGLEVEL -ge 1 ]; then return 0; fi
	return 1
}

function can_log_debug {
	if [ $OPT_LOGLEVEL -ge 2 ]; then return 0; fi
	return 1
}

## Architecture
function is_target_32bit {
	case "$OPT_TARGET" in
	win32)
		return 0
		;;
	*)
		return 1
		;;
	esac
}

function is_target_64bit {
	if is_target_32bit; then return 1; else return 0; fi
}

function arch_select {
	# Arguments:
	#  $1 value for 32-bit
	#  $2 value for 64-bit
	# Usage: var=$(arch_select "32-bit" "64-bit")

	if is_target_32bit; then
		echo $1
	else
		echo $2
	fi
	return 0
}

## Commands
function quiet_call {
	if ! can_log_debug; then
		$* > /dev/null
		return $?
	else
		$*
		return $?
	fi
}

function ninja_args {
	if can_log_debug; then
		echo "-v"
	else
		echo ""
	fi
}

function make_args {
	echo -n "-j 16 "
	if can_log_debug; then
		echo "--trace"
	elif ! can_log_info; then
		echo "--quiet"
	else
		echo ""
	fi
}

function cmake_args {
	echo -n "-DCMAKE_MODULE_LINKER_FLAGS='-static-libgcc' "
	echo -n "-DCMAKE_SHARED_LINKER_FLAGS='-static-libgcc' "
	echo -n "-DCMAKE_EXE_LINKER_FLAGS='-static-libgcc' "
	if can_log_debug; then
		echo "-DCMAKE_VERBOSE_MAKEFILE=On -DCMAKE_AUTOGEN_VERBOSE=On -DCMAKE_INSTALL_MESSAGE=ALWAYS -DCMAKE_RULE_MESSAGES=On"
	elif ! can_log_info; then
		echo "--no-warn-unused-cli -DCMAKE_VERBOSE_MAKEFILE=Off -DCMAKE_AUTOGEN_VERBOSE=Off -DCMAKE_INSTALL_MESSAGE=NEVER -DCMAKE_RULE_MESSAGES=Off"
	else
		echo "--no-warn-unused-cli -DCMAKE_INSTALL_MESSAGE=LAZY"
	fi
}

function setup_call_env {
	# Arguments:
	# ... - name of variable to not export.
	local _KEY

	if can_log_config; then echo "Environment:"; fi

	declare -A __MYENV
	for _KEY in ${!_MYENV[@]}; do
		__MYENV[${_KEY}]=${_MYENV[${_KEY}]}
	done

#	echo $*
	while [ "${1+exists}" == "exists" ]; do
		if can_log_debug; then echo "    $1 Cleared"; fi
		unset __MYENV[$1]
		shift
	done

	for _KEY in ${!__MYENV[@]}; do
		export "${_KEY}=${_MYENV[${_KEY}]}"
		if can_log_config; then echo "    $_KEY=${__MYENV[${_KEY}]}"; fi
	done
}

function clear_call_env {
	local _KEY

	for _KEY in ${_MYENV[#]}; do
		unset ${_KEY}
		if can_log_debug; then echo "Cleared Environment Variable: $_KEY"; fi
	done
}

function setup_env {
	# Basic variables
	export _TARGET=$(arch_select "i686-w64-mingw32" "x86_64-w64-mingw32")
	export _TARGET_RUNTIME="win32"
	export _SCRIPTROOT=${SCRIPT_DIR}
	export _SYSROOT=${OPT_BUILDDIR}
	export _BUILDROOT=${OPT_BUILDDIR}/tmp
	export _CMAKE_TOOLCHAIN=${_SCRIPTROOT}/cmake/${_TARGET}-toolchain-${_TARGET_RUNTIME}.cmake

	# Compiler & Flags	
	export CROSS="${_TARGET}"
	_MYENV[CC]="/usr/bin/${_TARGET}-gcc-${_TARGET_RUNTIME}"
	_MYENV[CXX]="/usr/bin/${_TARGET}-g++-${_TARGET_RUNTIME}"
	_MYENV[CPP]="/usr/bin/${_TARGET}-gcc-${_TARGET_RUNTIME} -E"
	_MYENV[AR]="/usr/bin/${_TARGET}-gcc-ar-${_TARGET_RUNTIME}"
	_MYENV[NM]="/usr/bin/${_TARGET}-gcc-nm-${_TARGET_RUNTIME}"
	_MYENV[RANLIB]="/usr/bin/${_TARGET}-gcc-ranlib-${_TARGET_RUNTIME}"
	_MYENV[GCOV]="/usr/bin/${_TARGET}-gcov-${_TARGET_RUNTIME}"
	_MYENV[DLLTOOL]="/usr/bin/${_TARGET}-dlltool"
	_MYENV[DLLWRAP]="/usr/bin/${_TARGET}-dllwrap"
	_MYENV[STRIP]="/usr/bin/${_TARGET}-strip"
	_MYENV[AS]="/usr/bin/${_TARGET}-as"
	_MYENV[LD]="${_MYENV[CC]}"
	_MYENV[RC]="/usr/bin/${_TARGET}-windres"
	_MYENV[NASM]="/usr/bin/nasm"
	_MYENV[CFLAGS]="-static-libgcc -static-libstdc++"
	_MYENV[CXXFLAGS]="-static-libgcc -static-libstdc++"
	_MYENV[CPPFLAGS]="-static-libgcc -static-libstdc++"
	_MYENV[LDFLAGS]="-static-libgcc -static-libstdc++"

	# Package Config
	_MYENV[PKG_CONFIG_DIR]=
	_MYENV[PKG_CONFIG_LIBDIR]="${_SYSROOT}/lib/pkgconfig:${_SYSROOT}/share/pkgconfig:${_SYSROOT}/usr/lib/pkgconfig:${_SYSROOT}/usr/share/pkgconfig:${_SYSROOT}/usr/local/lib/pkgconfig:${_SYSROOT}/usr/local/share/pkgconfig"
	_MYENV[PKG_CONFIG_SYSROOT_DIR]=
	_MYENV[PKG_CONFIG_PATH]=
	
	# Verbose, Quiet
	if can_log_debug; then
		unset CMAKE_NO_VERBOSE
		export VERBOSE=1
		export CMAKE_AUTOGEN_VERBOSE=1
		export CMAKE_VERBOSE_MAKEFILE=1
	fi
	if can_log_info; then
		export CMAKE_NO_VERBOSE=1
		unset VERBOSE
	fi

	# Directories
	if [ ! -d ${_SYSROOT} ]; then mkdir -p ${_SYSROOT}; fi
	if [ ! -d ${_SYSROOT}/bin ]; then mkdir -p ${_SYSROOT}/bin; fi
	if [ ! -d ${_SYSROOT}/lib/pkgconfig ]; then mkdir -p ${_SYSROOT}/lib/pkgconfig; fi
	if [ ! -d ${_SYSROOT}/share/pkgconfig ]; then mkdir -p ${_SYSROOT}/share/pkgconfig; fi
	if [ ! -d ${_SYSROOT}/usr/lib/pkgconfig ]; then mkdir -p ${_SYSROOT}/usr/lib/pkgconfig; fi
	if [ ! -d ${_SYSROOT}/usr/share/pkgconfig ]; then mkdir -p ${_SYSROOT}/usr/share/pkgconfig; fi
	if [ ! -d ${_SYSROOT}/usr/local/lib/pkgconfig ]; then mkdir -p ${_SYSROOT}/usr/local/lib/pkgconfig; fi
	if [ ! -d ${_SYSROOT}/usr/local/share/pkgconfig ]; then mkdir -p ${_SYSROOT}/usr/local/share/pkgconfig; fi
	if [ ! -d ${_BUILDROOT} ]; then mkdir -p ${_BUILDROOT}; fi
	if [ ! -d ${OPT_OUTPUTDIR} ]; then mkdir -p ${OPT_OUTPUTDIR}; fi
	if [ ! -d ${OPT_OUTPUTDIR}/bin ]; then mkdir -p ${OPT_OUTPUTDIR}/bin; fi
	if [ ! -d ${OPT_OUTPUTDIR}/include ]; then mkdir -p ${OPT_OUTPUTDIR}/include; fi

	return 0
}

function step_apt {
	quiet_call sudo apt-get install -y \
		build-essential \
		gcc \
		mingw-w64 \
		binutils-mingw-w64 \
		nasm \
		ninja-build \
		autoconf \
		make \
		automake \
		cmake \
		libtool \
		pkg-config \
		git \
		python3 \
		tclsh \
		gawk
	# Can't fail, if the user doesn't allow this we just assume everything is present.
	return 0
}

function step_zlib {
	quiet_call git submodule update --init --recursive --force zlib
	if [ $? -ne 0 ]; then return $?; fi
	
	# Create Build Directory
	if [ ! -d ${_BUILDROOT}/zlib ]; then mkdir -p ${_BUILDROOT}/zlib; fi

	# Apply Patches
	pushd ${_SCRIPTROOT}/zlib > /dev/null
	quiet_call git apply ${_SCRIPTROOT}/patches/zlib/*.patch
	popd > /dev/null

	# Compile
	pushd ${_BUILDROOT}/zlib > /dev/null
	quiet_call cmake \
		-H${_SCRIPTROOT}/zlib -B. -GNinja \
		-DCMAKE_TOOLCHAIN_FILE=${_CMAKE_TOOLCHAIN} \
		-DCMAKE_BUILD_TYPE=Release \
		-DCMAKE_INSTALL_PREFIX=${_SYSROOT} \
		-DBUILD_SHARED_LIBS=On $(cmake_args)
	if [ $? -ne 0 ]; then popd > /dev/null; return $?; fi
	quiet_call ninja install $(ninja_args)
	if [ $? -ne 0 ]; then popd > /dev/null; return $?; fi
	popd > /dev/null

	# zlib installs pkg-config files to share/pkgconfig instead of lib/pkgconfig
	if [ ! -d ${_SYSROOT}/lib/pkgconfig/ ]; then mkdir -p ${_SYSROOT}/lib/pkgconfig; fi
	cp ${_SYSROOT}/share/pkgconfig/zlib.pc ${_SYSROOT}/lib/pkgconfig/zlib.pc > /dev/null

	# Some configure scripts require libz instead of libzlib
	cp ${_SYSROOT}/lib/libzlib.dll.a ${_SYSROOT}/lib/libz.dll.a > /dev/null
	cp ${_SYSROOT}/lib/libzlibstatic.a ${_SYSROOT}/lib/libz.a > /dev/null
	cp ${_SYSROOT}/lib/libzlib.dll.a ${_SYSROOT}/lib/zlib.lib > /dev/null
	cp ${_SYSROOT}/lib/libzlibstatic.a ${_SYSROOT}/lib/zlibstatic.lib > /dev/null

	return 0
}

function step_mbedtls {
	quiet_call git submodule update --init --recursive --force mbedtls
	if [ $? -ne 0 ]; then return $?; fi
	
	# Create Build Directories
	if [ ! -d ${_BUILDROOT}/mbedtls ]; then mkdir -p ${_BUILDROOT}/mbedtls; fi
	if [ ! -d ${_BUILDROOT}/mbedcrypto ]; then mkdir -p ${_BUILDROOT}/mbedcrypto; fi
	
	# Build mbedcrypto
	pushd ${_BUILDROOT}/mbedcrypto > /dev/null
	quiet_call cmake -H${_SCRIPTROOT}/mbedtls -B. -GNinja \
		-DCMAKE_TOOLCHAIN_FILE=${_CMAKE_TOOLCHAIN} \
		-DCMAKE_BUILD_TYPE=Release \
		-DCMAKE_INSTALL_PREFIX=${_SYSROOT}/.mbedtls-crypto \
		-DCMAKE_FIND_ROOT_PATH=${_SYSROOT} \
		-DENABLE_TESTING=OFF \
		-DENABLE_PROGRAMS=OFF \
		-DUSE_SHARED_MBEDTLS_LIBRARY=ON \
		-DUSE_STATIC_MBEDTLS_LIBRARY=ON \
		-DENABLE_ZLIB_SUPPORT=ON \
		-DZLIB_ROOT=${_SYSROOT} \
		-DZLIB_INCLUDE_DIR=${_SYSROOT}/include \
		-DZLIB_LIBRARY=${_SYSROOT}/lib/libzlib.dll.a \
		-DCMAKE_EXE_LINKER_FLAGS="-static-libgcc" \
		-DCMAKE_SHARED_LINKER_FLAGS="-static-libgcc" $(cmake_args)
	if [ $? -ne 0 ]; then popd > /dev/null; return $?; fi
	quiet_call ninja crypto/include/install $(ninja_args)
	if [ $? -ne 0 ]; then popd > /dev/null; return $?; fi
	quiet_call ninja crypto/library/install $(ninja_args)
	if [ $? -ne 0 ]; then popd > /dev/null; return $?; fi
	popd > /dev/null

	# Build mbedtls
	pushd ${_BUILDROOT}/mbedtls > /dev/null
	quiet_call cmake -H${_SCRIPTROOT}/mbedtls -B. -GNinja \
		-DCMAKE_TOOLCHAIN_FILE=${_CMAKE_TOOLCHAIN} \
		-DCMAKE_BUILD_TYPE=Release \
		-DCMAKE_INSTALL_PREFIX=${_SYSROOT}/.mbedtls-tls \
		-DCMAKE_FIND_ROOT_PATH=${_SYSROOT} \
		-DENABLE_TESTING=OFF \
		-DENABLE_PROGRAMS=OFF \
		-DUSE_SHARED_MBEDTLS_LIBRARY=ON \
		-DUSE_STATIC_MBEDTLS_LIBRARY=ON \
		-DENABLE_ZLIB_SUPPORT=ON \
		-DZLIB_ROOT=${_SYSROOT} \
		-DZLIB_INCLUDE_DIR=${_SYSROOT}/include \
		-DZLIB_LIBRARY=${_SYSROOT}/lib/libzlib.dll.a \
		-DCMAKE_EXE_LINKER_FLAGS="-static-libgcc" \
		-DCMAKE_SHARED_LINKER_FLAGS="-static-libgcc" $(cmake_args)
	if [ $? -ne 0 ]; then popd > /dev/null; return $?; fi
	quiet_call ninja include/install $(ninja_args)
	if [ $? -ne 0 ]; then popd > /dev/null; return $?; fi
	quiet_call ninja library/install $(ninja_args)
	if [ $? -ne 0 ]; then popd > /dev/null; return $?; fi
	popd > /dev/null

	# Copy actual content because CMake is dumb and doesn't override files even if their date, hash and content are different.
	cp -R ${_SYSROOT}/.mbedtls-crypto/* ${_SYSROOT}
	cp -R ${_SYSROOT}/.mbedtls-tls/* ${_SYSROOT}

	# mbedtls places .dll files inside lib, we need them in bin.
	mv ${_SYSROOT}/lib/libmbedtls.dll ${_SYSROOT}/lib/libmbedx509.dll ${_SYSROOT}/lib/libmbedcrypto.dll ${_SYSROOT}/bin

	# Let's just craft our own pkg-config file, as the PR made in 2018 was never finished
	# and also never merged.
	sed "s#@@PREFIX@@#${_SYSROOT}#" ${_SCRIPTROOT}/patches/mbedtls/mbedtls.pc > ${_SYSROOT}/lib/pkgconfig/mbedtls.pc
	sed "s#@@PREFIX@@#${_SYSROOT}#" ${_SCRIPTROOT}/patches/mbedtls/mbedx509.pc > ${_SYSROOT}/lib/pkgconfig/mbedx509.pc
	sed "s#@@PREFIX@@#${_SYSROOT}#" ${_SCRIPTROOT}/patches/mbedtls/mbedcrypto.pc > ${_SYSROOT}/lib/pkgconfig/mbedcrypto.pc

	return 0
}

function step_libpng {
	quiet_call git submodule update --init --recursive --force libpng
	if [ $? -ne 0 ]; then return $?; fi
	
	# Create Build Directory
	if [ ! -d ${_BUILDROOT}/libpng ]; then mkdir -p ${_BUILDROOT}/libpng; fi

	# Build
	pushd ${_BUILDROOT}/libpng > /dev/null
	quiet_call cmake \
		-H${_SCRIPTROOT}/libpng -B. "-GNinja" \
		-DCMAKE_TOOLCHAIN_FILE=${_CMAKE_TOOLCHAIN} \
		-DCMAKE_BUILD_TYPE=Release \
		-DCMAKE_INSTALL_PREFIX=${_SYSROOT} \
		-DCMAKE_FIND_ROOT_PATH=${_SYSROOT} \
		-DCMAKE_VERBOSE_MAKEFILE=ON \
		-DPNG_TESTS=OFF \
		-DPNG_DEBUG=OFF \
		-DZLIB_ROOT=${_SYSROOT} \
		-DZLIB_INCLUDE_DIR=${_SYSROOT}/include \
		-DZLIB_LIBRARY=${_SYSROOT}/lib/libzlib.dll.a \
		$(cmake_args)
	if [ $? -ne 0 ]; then popd > /dev/null; return $?; fi
	quiet_call ninja install $(ninja_args)
	if [ $? -ne 0 ]; then popd > /dev/null; return $?; fi
	popd > /dev/null

	return 0
}

function step_x264 {
	quiet_call git submodule update --init --recursive --force x264
	if [ $? -ne 0 ]; then return $?; fi
	
	# Create Build Directory
	if [ ! -d ${_BUILDROOT}/x264 ]; then mkdir -p ${_BUILDROOT}/x264; fi

	# Build
	pushd ${_BUILDROOT}/x264 > /dev/null
	setup_call_env
	AS=nasm \
	quiet_call ${_SCRIPTROOT}/x264/configure \
		--prefix=${_SYSROOT} \
		--host=$(arch_select mingw32-win32 mingw64-win32) \
		--cross-prefix=${_TARGET}- \
		--sysroot=${_SYSROOT} \
		--extra-cflags="-O3" \
		--enable-pic \
		--enable-shared \
		--enable-strip \
		--disable-opencl \
		--disable-swscale \
		--disable-cli
	clear_call_env
	if [ $? -ne 0 ]; then popd > /dev/null; return $?; fi
	quiet_call make $(make_args)
	if [ $? -ne 0 ]; then popd > /dev/null; return $?; fi
	quiet_call make install $(make_args)
	if [ $? -ne 0 ]; then popd > /dev/null; return $?; fi
	popd > /dev/null

	return 0
}

function step_ogg {
	quiet_call git submodule update --init --recursive --force ogg
	if [ $? -ne 0 ]; then return $?; fi
	
	# Create Build Directory
	if [ ! -d ${_BUILDROOT}/ogg ]; then mkdir -p ${_BUILDROOT}/ogg; fi

	# Build
	pushd ${_BUILDROOT}/ogg > /dev/null
	quiet_call cmake \
		-H${_SCRIPTROOT}/ogg -B. -GNinja \
		-DCMAKE_TOOLCHAIN_FILE=${_CMAKE_TOOLCHAIN} \
		-DCMAKE_BUILD_TYPE=Release \
		-DCMAKE_INSTALL_PREFIX=${_SYSROOT} \
		-DCMAKE_SHARED_LIBRARY_PREFIX=lib \
		-DCMAKE_SHARED_MODULE_PREFIX=lib \
		-DCMAKE_STATIC_LIBRARY_PREFIX=lib \
		-DBUILD_SHARED_LIBS=ON \
		-DBUILD_TESTING=OFF \
		$(cmake_args)
	if [ $? -ne 0 ]; then popd > /dev/null; return $?; fi
	quiet_call ninja install $(ninja_args)
	if [ $? -ne 0 ]; then popd > /dev/null; return $?; fi
	popd > /dev/null

	# libogg.dll.a actually links to ogg.dll, not libogg.dll.
	# Nothing seems to change if we set the necessary CMake variables, so...
	mv ${_SYSROOT}/bin/libogg.dll ${_SYSROOT}/bin/ogg.dll

	return 0
}

function step_vorbis {
	quiet_call git submodule update --init --recursive --force vorbis
	if [ $? -ne 0 ]; then return $?; fi
	
	# Create Build Directory
	if [ ! -d ${_BUILDROOT}/vorbis ]; then mkdir -p ${_BUILDROOT}/vorbis; fi

	# Build
	pushd ${_BUILDROOT}/vorbis > /dev/null
	quiet_call cmake \
		-H${_SCRIPTROOT}/vorbis -B. -GNinja \
		-DCMAKE_TOOLCHAIN_FILE=${_CMAKE_TOOLCHAIN} \
		-DCMAKE_BUILD_TYPE=Release \
		-DCMAKE_INSTALL_PREFIX=${_SYSROOT} \
		-DBUILD_SHARED_LIBS=ON \
		-DOGG_ROOT=${_SYSROOT} \
		-DOGG_INCLUDE_DIRS=${_SYSROOT}/include \
		-DOGG_LIBRARIES=${_SYSROOT}/lib/libogg.dll.a \
		$(cmake_args)
	if [ $? -ne 0 ]; then popd > /dev/null; return $?; fi
	quiet_call ninja install $(ninja_args)
	if [ $? -ne 0 ]; then popd > /dev/null; return $?; fi
	popd > /dev/null

	return 0
}

function step_opus {
	quiet_call git submodule update --init --recursive --force opus
	if [ $? -ne 0 ]; then return $?; fi
	
	# Create Build Directory
	if [ ! -d ${_BUILDROOT}/opus ]; then mkdir -p ${_BUILDROOT}/opus; fi

	# Build
	pushd ${_BUILDROOT}/opus > /dev/null
	quiet_call cmake \
		-H${_SCRIPTROOT}/opus -B. -GNinja \
		-DCMAKE_TOOLCHAIN_FILE=${_CMAKE_TOOLCHAIN} \
		-DCMAKE_BUILD_TYPE=Release \
		-DCMAKE_INSTALL_PREFIX=${_SYSROOT} \
		-DBUILD_SHARED_LIBS=ON \
		-DBUILD_TESTING=OFF \
		-DOPUS_STACK_PROTECTOR=OFF \
		-DOPUS_BUILD_PROGRAMS=ON \
		$(cmake_args)
	if [ $? -ne 0 ]; then popd > /dev/null; return $?; fi
	quiet_call ninja install $(ninja_args)
	if [ $? -ne 0 ]; then popd > /dev/null; return $?; fi
	popd > /dev/null

	return 0
}

function step_vpx {
	quiet_call git submodule update --init --recursive --force libvpx
	if [ $? -ne 0 ]; then return $?; fi
	
	# Create Build Directory
	if [ ! -d ${_BUILDROOT}/libvpx ]; then mkdir -p ${_BUILDROOT}/libvpx; fi

	# Apply Patches
	pushd ${_SCRIPTROOT}/libvpx > /dev/null
	quiet_call git apply ${_SCRIPTROOT}/patches/libvpx/*.patch
	popd > /dev/null

	# Compile
	pushd ${_BUILDROOT}/libvpx > /dev/null
	setup_call_env
	AS=nasm \
	quiet_call ${_SCRIPTROOT}/libvpx/configure \
		--prefix=${_SYSROOT} \
		--target=$(arch_select x86-win32-gcc x86_64-win64-gcc) \
		--as=nasm \
		--extra-cflags="-O3" \
		--extra-cflags="-static-libgcc" \
		--extra-cxxflags="-O3" \
		--extra-cxxflags="-static-libgcc" \
		--extra-cxxflags="-static-libstdc++" \
		--enable-pic \
		--disable-examples \
		--disable-dependency-tracking \
		--disable-tools \
		--enable-shared \
		--disable-static \
		--enable-vp8 \
		--enable-vp9 \
		--enable-runtime-cpu-detect \
		--enable-realtime-only \
		--enable-onthefly-bitpacking \
		--enable-error-concealment \
		--enable-vp9-temporal-denoising \
		--enable-multi-res-encoding \
		--enable-vp9-highbitdepth
	clear_call_env
	if [ $? -ne 0 ]; then popd > /dev/null; return $?; fi
	quiet_call make $(make_args)
	if [ $? -ne 0 ]; then popd > /dev/null; return $?; fi
	quiet_call make install $(make_args)
	if [ $? -ne 0 ]; then popd > /dev/null; return $?; fi
	popd > /dev/null

	return 0
}

function step_srt {
	quiet_call git submodule update --init --recursive --force srt
	if [ $? -ne 0 ]; then return $?; fi
	
	# Create Build Directory
	if [ ! -d ${_BUILDROOT}/srt ]; then mkdir -p ${_BUILDROOT}/srt; fi

	# Compile
	pushd ${_BUILDROOT}/srt > /dev/null
	quiet_call cmake \
		-H${_SCRIPTROOT}/srt -B. -GNinja \
		-DCMAKE_TOOLCHAIN_FILE=${_CMAKE_TOOLCHAIN} \
		-DCMAKE_BUILD_TYPE=Release \
		-DCMAKE_INSTALL_PREFIX=${_SYSROOT} \
		-DENABLE_SHARED=On \
		-DENABLE_STATIC=On \
		-DUSE_ENCLIB=mbedtls \
		-DENABLE_APPS=Off \
		-DUSE_GNUSTL=Off \
		-DUSE_STATIC_LIBSTDCXX=On \
		-DENABLE_CXX_DEPS=On \
		$(cmake_args)
	if [ $? -ne 0 ]; then popd > /dev/null; return $?; fi
	quiet_call ninja install $(ninja_args)
	if [ $? -ne 0 ]; then popd > /dev/null; return $?; fi
	popd > /dev/null

	# Requires pthreads
	cp /usr/${_TARGET}/lib/libwinpthread-1.dll ${_SYSROOT}/bin

	return 0
}

function step_nvenc {
	quiet_call git submodule update --init --recursive --force nv-codec-headers
	if [ $? -ne 0 ]; then return $?; fi

	pushd ${_SCRIPTROOT}/nv-codec-headers > /dev/null
	quiet_call make PREFIX=${_SYSROOT} DESTDIR= install $(make_args)
	if [ $? -ne 0 ]; then popd > /dev/null; return $?; fi
	popd > /dev/null

	return 0
}

function step_ffmpeg {
	quiet_call git submodule update --init --recursive --force ffmpeg
	if [ $? -ne 0 ]; then return $?; fi
	
	# Create Build Directory
	if [ ! -d ${_BUILDROOT}/ffmpeg ]; then mkdir -p ${_BUILDROOT}/ffmpeg; fi

	# Compile
	pushd ${_BUILDROOT}/ffmpeg > /dev/null
	AS=nasm \
	quiet_call ${_SCRIPTROOT}/ffmpeg/configure \
		--prefix=${_SYSROOT} \
		--enable-cross-compile \
		--cross-prefix=${_TARGET}- \
		--progs-suffix= \
		--arch=$(arch_select x86_32 x86_64) \
		--target-os=$(arch_select mingw32 mingw64) \
		"--nm=${NM}" \
		"--ar=${AR}" \
		"--as=${AS}" \
		"--strip=${STRIP}" \
		"--windres=${WINDRES}" \
		"--cc=${CC}" \
		"--cxx=${CXX}" \
		"--objcc=${CC}" \
		"--ld=${CC}" \
		"--ranlib=${RANLIB}" \
		--x86asmexe=nasm \
		--pkg-config=pkg-config \
		--extra-cflags=-O3 \
		--extra-cflags=$(arch_select -m32 -m64) \
		--extra-cflags=-static-libgcc \
		--extra-cxxflags=-O3 \
		--extra-cxxflags=$(arch_select -m32 -m64) \
		--extra-cxxflags=-static-libgcc \
		--extra-ldflags=-O3 \
		--extra-ldflags=-static-libgcc \
		--enable-pic \
		--enable-shared \
		--disable-static \
		--disable-doc \
		--disable-debug \
		--enable-gpl \
		--disable-postproc \
		--enable-libsrt \
		--enable-libvorbis \
		--enable-libopus \
		--enable-libvpx \
		--enable-libx264 \
		--enable-d3d11va \
		--enable-dxva2 \
		--enable-nvenc #\
#		--enable-amf # \
#		--enable-libmfx
	if [ $? -ne 0 ]; then popd > /dev/null; return $?; fi
	quiet_call make $(make_args)
	if [ $? -ne 0 ]; then popd > /dev/null; return $?; fi
	quiet_call make install $(make_args)
	if [ $? -ne 0 ]; then popd > /dev/null; return $?; fi
	popd > /dev/null

	return 0
}

function step_curl {
	quiet_call git submodule update --init --recursive --force curl
	if [ $? -ne 0 ]; then return $?; fi
	
	# Create Build Directory
	if [ ! -d ${_BUILDROOT}/curl ]; then mkdir -p ${_BUILDROOT}/curl; fi
	#if [ ! -d ${_BUILDROOT}/curl2 ]; then mkdir -p ${_BUILDROOT}/curl2; fi

	# Compile
	pushd ${_SCRIPTROOT}/curl > /dev/null
	quiet_call git clean -fdx
#	quiet_call wget -Oconfig.sub https://git.savannah.gnu.org/gitweb/?p=config.git\;a=blob_plain\;f=config.sub
#	quiet_call wget -Oconfig.guess https://git.savannah.gnu.org/gitweb/?p=config.git\;a=blob_plain\;f=config.guess
	quiet_call autoreconf -i
	if [ $? -ne 0 ]; then popd > /dev/null; return $?; fi
	popd > /dev/null

	pushd ${_BUILDROOT}/curl > /dev/null
	setup_call_env AR AS CC CPP CXX DLLTOOL DLLWRAP GCOV LD NM RANLIB RC STRIP WINDRES
	quiet_call ${_SCRIPTROOT}/curl/configure \
		--prefix=${_SYSROOT} \
		--with-gnu-ld --build=x86_64-pc-linux-gnu --host=${_TARGET} \
		--enable-shared --enable-static --with-pic \
		--disable-debug \
		--disable-curldebug \
		--enable-optimize \
		--disable-dependency-tracking  \
		--enable-ipv6 \
		--enable-http \
		--enable-http-auth \
		--enable-ftp \
		--enable-file \
		--enable-proxy \
		--enable-mime \
		--enable-cookies \
		--enable-dnsshuffle \
		--enable-crypto-auth \
		--enable-tls-srp \
		--enable-progress-meter \
		--enable-threaded-resolver \
		--enable-pthreads \
		--enable-sspi \
		--enable-schannel \
		--enable-secure-transport \
		--disable-manual \
		--disable-versioned-symbols \
		--with-mbedtls=${OPT_DEPDIR} \
		--with-zlib=${OPT_DEPDIR}

	clear_call_env
	if [ $? -ne 0 ]; then popd > /dev/null; return $?; fi
	quiet_call make $(make_args)
	if [ $? -ne 0 ]; then popd > /dev/null; return $?; fi
	quiet_call make install $(make_args)
	if [ $? -ne 0 ]; then popd > /dev/null; return $?; fi
	popd

	# Requires pthreads
	cp /usr/${_TARGET}/lib/libwinpthread-1.dll ${_SYSROOT}/bin

	return 0
}

function step_freetype {
	# Does not rely on a submodule due to even the configure files being generated.
	# Who came up with generating the tools to generate your makefile to generate your binaries? It's dumb.
	
	# Create Build Directory
	if [ ! -d ${_BUILDROOT}/freetype ]; then mkdir -p ${_BUILDROOT}/freetype; fi

	# Build
	pushd ${_BUILDROOT}/freetype > /dev/null
#	# Download Source, Configure, Make
#	local VERSION=2.10.1
#	if [ ! -f freetype.tar.gz ]; then
#		quiet_call wget -Ofreetype.tar.gz https://download.savannah.gnu.org/releases/freetype/freetype-${VERSION}.tar.xz
#		if [ $? -ne 0 ]; then popd > /dev/null; return $?; fi
#	fi
#	if [ ! -f ]
#	quiet_call tar -xvf freetype.tar.gz
#	if [ $? -ne 0 ]; then popd > /dev/null; return $?; fi
#	quiet_call cp -R freetype-${VERSION}/* ${_BUILDROOT}/freetype2
#	if [ $? -ne 0 ]; then popd > /dev/null; return $?; fi
#	quiet_call configure \
#		--with-gnu-ld \
#		--prefix=${_SYSROOT} \
#		--host=${_TARGET} \
#		--enable-shared \
#		--enable-static \
#		--with-pic \
#		--with-sysroot=${_SYSROOT} \
#		--with-png=yes \
#		--with-zlib=yes
#	if [ $? -ne 0 ]; then popd > /dev/null; return $?; fi

	quiet_call cmake \
		-H${_SCRIPTROOT}/freetype -B. -GNinja \
		-DCMAKE_TOOLCHAIN_FILE=${_CMAKE_TOOLCHAIN} \
		-DCMAKE_BUILD_TYPE=Release \
		-DCMAKE_INSTALL_PREFIX=${_SYSROOT} \
		-DZLIB_INCLUDE_DIR=${_SYSROOT}/include \
		-DZLIB_LIBRARY=${_SYSROOT}/lib/libzlib.dll.a \
		-DPNG_PNG_INCLUDE_DIR=${_SYSROOT}/include \
		-DPNG_LIBRARY=${_SYSROOT}/lib/liblibpng16.dll.a \
		$(cmake_args)
	if [ $? -ne 0 ]; then popd > /dev/null; return $?; fi
	quiet_call ninja install $(ninja_args)
	if [ $? -ne 0 ]; then popd > /dev/null; return $?; fi
	popd > /dev/null

	return 0
}

function step_websockets {
	# Create Build Directory
	if [ ! -d ${_BUILDROOT}/libwebsockets ]; then mkdir -p ${_BUILDROOT}/libwebsockets; fi

	# Build
	pushd ${_BUILDROOT}/libwebsockets > /dev/null
	quiet_call cmake \
		-H${_SCRIPTROOT}/libwebsockets -B. -GNinja \
		-DCMAKE_TOOLCHAIN_FILE=${_CMAKE_TOOLCHAIN} \
		-DCMAKE_BUILD_TYPE=Release \
		-DCMAKE_INSTALL_PREFIX=${_SYSROOT} \
		-DLWS_WITH_MBEDTLS=1 \
		-DMBEDTLS_LIBRARY=${_SYSROOT}/lib/libmbedtls.dll.a \
		-DMBEDX509_LIBRARY=${_SYSROOT}/lib/libmbedx509.dll.a \
		-DMBEDCRYPTO_LIBRARY=${_SYSROOT}/lib/libmbedcrypto.dll.a \
		-DLWS_MBEDTLS_INCLUDE_DIRS=${_SYSROOT}/include \
		-DLWS_IPV6=ON \
		-DLWS_WITHOUT_DAEMONIZE=ON \
		-DLWS_WITHOUT_TESTAPPS=ON \
		-DLWS_WITHOUT_TEST_CLIENT=ON \
		-DLWS_WITHOUT_TEST_PING=ON \
		-DLWS_WITHOUT_TEST_SERVER=ON \
		-DLWS_WITHOUT_TEST_SERVER_EXTPOLL=ON \
		-DLWS_WITH_BUNDLED_ZLIB=OFF \
		-DLWS_WITH_SHARED=ON \
		$(cmake_args)
	if [ $? -ne 0 ]; then popd > /dev/null; return $?; fi
	quiet_call ninja install $(ninja_args)	
	if [ $? -ne 0 ]; then popd > /dev/null; return $?; fi
	popd > /dev/null

	return 0
}

#function step_luajit {
#	# luajit's build system is, to say it in nice terms, dumb.
#	# It depends on itself, which ruins cross compiling completely.
#	# So instead we build luajit once for the host, to get minilua,
#	# And then build the actual luajit for the target.
#
#	# Create Build Directory
#	if [ ! -d ${_BUILDROOT}/luajit ]; then mkdir -p ${_BUILDROOT}/luajit; fi
#	if [ ! -d ${_BUILDROOT}/luajit-dumb ]; then mkdir -p ${_BUILDROOT}/luajit-dumb; fi
#
#	# Build
#	export CC=${_TARGET}-gcc-${_TARGET_RUNTIME}
#	export CXX=${_TARGET}-g++-${_TARGET_RUNTIME}
#	export CPP=${_TARGET}-cpp-${_TARGET_RUNTIME}
#	export AR=${_TARGET}-gcc-ar-${_TARGET_RUNTIME}
#	export NM=${_TARGET}-gcc-nm-${_TARGET_RUNTIME}
#	export RANLIB=${_TARGET}-gcc-ranlib-${_TARGET_RUNTIME}
#	export GCOV=${_TARGET}-gcov-${_TARGET_RUNTIME}
#	export DLLTOOL=${_TARGET}-dlltool
#	export DLLWRAP=${_TARGET}-dllwrap
#	export AS=${_TARGET}-as
#	export LD=${CC}
#	export STRIP=${_TARGET}-strip
#	export WINDRES=${_TARGET}-windres
#	export RC=${WINDRES}
#	export AS=${_TARGET}-as
#	pushd ${_BUILDROOT}/luajit-dumb > /dev/null
#	CC=gcc CXX=g++ CPP=cpp AR=ar NM=nm RANLIB=ranlib DLLTOOL= DLLWRAP= AS=as LD=gcc STRIP=strip WINDRES=gcc RC=gcc AS=as \
#	quiet_call cmake \
#		-H${_SCRIPTROOT}/luajit -B. -GNinja \
#		-DCMAKE_BUILD_TYPE=Release \
#		$(cmake_args)
#	if [ $? -ne 0 ]; then popd > /dev/null; return $?; fi
#	quiet_call sudo ninja install $(ninja_args)
#	if [ $? -ne 0 ]; then popd > /dev/null; return $?; fi
#	popd > /dev/null
#
#	pushd ${_BUILDROOT}/luajit > /dev/null
#	quiet_call cmake \
#		-H${_SCRIPTROOT}/luajit -B. -GNinja \
#		-DCMAKE_TOOLCHAIN_FILE=${_CMAKE_TOOLCHAIN} \
#		-DCMAKE_BUILD_TYPE=Release \
#		-DCMAKE_INSTALL_PREFIX=${_SYSROOT} \
#		$(cmake_args)
#	if [ $? -ne 0 ]; then popd > /dev/null; return $?; fi
#	quiet_call ninja install $(ninja_args)
#	if [ $? -ne 0 ]; then popd > /dev/null; return $?; fi
#	popd > /dev/null
#
#	return 0
#}

function step_python {
	# Create Build Directory
	if [ ! -d ${_BUILDROOT}/python ]; then mkdir -p ${_BUILDROOT}/python; fi

	# Download Python Libs
	pushd ${_BUILDROOT}/python > /dev/null
	quiet_call wget -O${_BUILDROOT}/python/python-libs.7z $(arch_select "https://cdn.xaymar.com/obs/obs-deps/python-3.7.5-32.7z" "https://cdn.xaymar.com/obs/obs-deps/python-3.7.5-64.7z")
	if [ $? -ne 0 ]; then popd > /dev/null; return $?; fi
	quiet_call 7z x -aoa -o. ${_BUILDROOT}/python/python-libs.7z
	if [ $? -ne 0 ]; then popd > /dev/null; return $?; fi
	quiet_call cp -R * ${_SYSROOT}
	if [ $? -ne 0 ]; then popd > /dev/null; return $?; fi
	popd > /dev/null

	return 0
}

function step_swig {
	# Create Build Directory
	if [ ! -d ${_BUILDROOT}/swig ]; then mkdir -p ${_BUILDROOT}/swig; fi

	# Download SWIG
	pushd ${_BUILDROOT}/swig > /dev/null
	quiet_call wget -O${_BUILDROOT}/swig/swig.7z "https://cdn.xaymar.com/obs/obs-deps/swig-3.0.12.7z"
	if [ $? -ne 0 ]; then popd > /dev/null; return $?; fi
	quiet_call 7z x -aoa -o${OPT_OUTPUTDIR}/swig ${_BUILDROOT}/swig/swig.7z
	if [ $? -ne 0 ]; then popd > /dev/null; return $?; fi
	popd > /dev/null

	return 0
}

function step_package {
	# MSVC expects .lib, not .dll.a. No way to change this in CMake or MinGW. :(

	if [ ! -d ${OPT_OUTPUTDIR}/bin ]; then mkdir -p ${OPT_OUTPUTDIR}/bin; fi
	if [ ! -d ${OPT_OUTPUTDIR}/include ]; then mkdir -p ${OPT_OUTPUTDIR}/include; fi
	
	if [ ! -d ${OPT_OUTPUTDIR} ]; then mkdir -p ${OPT_OUTPUTDIR}; fi
	pushd ${OPT_OUTPUTDIR} > /dev/null
	cp -r ${_SYSROOT}/include ${OPT_OUTPUTDIR}
	find ${_SYSROOT}/bin -name "*.dll" -exec cp '{}' "${OPT_OUTPUTDIR}/bin/" \;
	find ${_SYSROOT}/bin -name "*.exe" -exec cp '{}' "${OPT_OUTPUTDIR}/bin/" \;
	find ${_SYSROOT}/bin -name "*.lib" -exec cp '{}' "${OPT_OUTPUTDIR}/bin/" \;
	for file in ${_SYSROOT}/lib/*.dll.a; do
		OUT=$(basename -s .dll.a "${file}")
		cp "${file}" "${OPT_OUTPUTDIR}/bin/${OUT}.lib"
	done
	popd > /dev/null

	return 0
}

function step_all {
	# Blank Step for stuff
	echo -n ""
	return 0
}

function run_steps {
	local STEP="${1:-all}"
	if [ "${STEPS["${STEP}"]+exists}" != "exists" ]; then
		echo "ERROR: Unknown Step '$STEP'"
		return 1
	fi
	if [ "${STEPS_COMPLETED["$STEP"]+exists}" == "exists" ]; then
		if can_log_debug; then echo "Step already completed: $STEP"; fi
		return 0
	fi

	if can_log_info; then echo "Step: ${STEP} (Dependencies)"; fi
	if ! is_solo; then
		local DEP
		for DEP in ${STEPS["${STEP}"]}; do
			if can_log_info; then echo "Step: ${STEP} > ${DEP}"; fi
			run_steps $DEP
			if [ $? -ne 0 ]; then return $?; fi
			STEPS_COMPLETED[$DEP]=TRUE
		done
	fi
	if can_log_info; then echo "Step: ${STEP} (Build)"; fi
	step_${STEP}
	return $?
}

pushd $SCRIPT_DIR > /dev/null
arguments $@
RET=$?
eval set -- "${OPTIONS}"
shift $RET

# At this point, the argument should be which step to build, or nothing if we want to build "all".
if [ "$1" == "pkg-config" ]; then
	# User wants to invoke pkg-config, special step
	shift 1
	popd > /dev/null
	exec pkg-config $*
fi
if [ "$1" == "cmd" ]; then
	# User wants to invoke pkg-config, special step
	shift 1
	popd > /dev/null
	exec $*
fi

RET=0
while [ "$1" != "" ]; do
	run_steps $1
	if [ $? -ne 0 ]; then
		RET=$?
		break
	fi
	shift
done
popd > /dev/null
exit $RET
