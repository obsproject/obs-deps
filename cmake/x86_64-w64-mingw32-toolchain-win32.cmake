# Sample toolchain file for building for Windows from an Ubuntu Linux system.
#
# Typical usage:
#    *) install cross compiler: `sudo apt-get install mingw-w64`
#    *) mkdir buildMingw64 && cd buildMingw64
#    *) cmake -DCMAKE_TOOLCHAIN_FILE=~/Toolchain-Ubuntu-mingw64.cmake ..
#

set(CMAKE_SYSTEM_NAME Windows CACHE STRING "" FORCE)
set(CMAKE_SYSTEM_VERSION 10.0 CACHE STRING "" FORCE)
set(CMAKE_SYSTEM_PROCESSOR x86_64 CACHE STRING "" FORCE)

set(_PREFIX ${CMAKE_SYSTEM_PROCESSOR}-w64-mingw32-)
set(_ARCH ${CMAKE_SYSTEM_PROCESSOR}-w64-mingw32)
set(_SUFFIX -win32)

# cross compilers to use for C and C++
set(CMAKE_C_COMPILER ${_PREFIX}gcc${_SUFFIX} CACHE FILEPATH "" FORCE)
set(CMAKE_C_COMPILER_AR ${_PREFIX}gcc-ar${_SUFFIX} CACHE FILEPATH "" FORCE)
set(CMAKE_C_COMPILER_RANLIB ${_PREFIX}gcc-ranlib${_SUFFIX} CACHE FILEPATH "" FORCE)
set(CMAKE_CXX_COMPILER ${_PREFIX}g++${_SUFFIX} CACHE FILEPATH "" FORCE)
set(CMAKE_ASM_COMPILER ${_PREFIX}gcc${_SUFFIX} CACHE FILEPATH "" FORCE)
set(CMAKE_ASM_COMPILER_AR ${_PREFIX}gcc-ar${_SUFFIX} CACHE FILEPATH "" FORCE)
set(CMAKE_ASM_COMPILER_RANLIB ${_PREFIX}gcc-ranlib${_SUFFIX} CACHE FILEPATH "" FORCE)
set(CMAKE_AR ${_PREFIX}gcc-ar${_SUFFIX} CACHE FILEPATH "" FORCE)
set(CMAKE_LINKER ${CMAKE_C_COMPILER} CACHE FILEPATH "" FORCE)
set(CMAKE_NM ${_PREFIX}gcc-nm${_SUFFIX} CACHE FILEPATH "" FORCE)
set(CMAKE_OBJCOPY ${_PREFIX}objcopy CACHE FILEPATH "" FORCE)
set(CMAKE_OBJDUMP ${_PREFIX}objdump CACHE FILEPATH "" FORCE)
set(CMAKE_RANLIB ${_PREFIX}gcc-ranlib${_SUFFIX} CACHE FILEPATH "" FORCE)
set(CMAKE_RC_COMPILER ${_PREFIX}windres CACHE FILEPATH "" FORCE)
set(CMAKE_STRIP ${_PREFIX}strip CACHE FILEPATH "" FORCE)
# set(CMAKE_GNUtoMS ON) # Does not work.

# target environment on the build host system
set(CMAKE_FIND_ROOT_PATH /usr/${_ARCH};/usr/lib/gcc/${_ARCH}/7.3-win32;${SYSROOT};${SYSROOT}/include;${SYSROOT}/lib)

# modify default behavior of FIND_XXX() commands to
# search for headers/libs in the target environment and
# search for programs in the build host environment
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
