# Kodi PS4 cross-compilation toolchain for OpenOrbis.
#
# Usage:
#   cmake -S references/kodi -B build/ps4 \
#     -DCMAKE_TOOLCHAIN_FILE=$PWD/cmake/toolchains/openorbis-ps4-kodi.cmake
#
# The OpenOrbis installation is supplied through OO_PS4_TOOLCHAIN.
# No Sony SDK files are required by this toolchain.

set(OO_PS4_TOOLCHAIN "$ENV{OO_PS4_TOOLCHAIN}" CACHE PATH
    "OpenOrbis PS4 toolchain root")

if(NOT OO_PS4_TOOLCHAIN OR NOT EXISTS "${OO_PS4_TOOLCHAIN}/link.x")
  message(FATAL_ERROR
    "OO_PS4_TOOLCHAIN must point to an OpenOrbis installation containing link.x")
endif()

set(CMAKE_SYSTEM_NAME FreeBSD)
set(CMAKE_SYSTEM_PROCESSOR x86_64)

# OpenOrbis' validated Clang target for PS4 homebrew.
set(PS4_TRIPLE "x86_64-pc-freebsd12-elf")
set(CMAKE_C_COMPILER clang)
set(CMAKE_CXX_COMPILER clang++)
set(CMAKE_ASM_COMPILER clang)
set(CMAKE_AR llvm-ar)
set(CMAKE_RANLIB llvm-ranlib)
set(CMAKE_LINKER ld.lld)

set(CMAKE_C_FLAGS_INIT
    "--target=${PS4_TRIPLE} -fPIC -funwind-tables -isystem ${OO_PS4_TOOLCHAIN}/include")
set(CMAKE_CXX_FLAGS_INIT
    "--target=${PS4_TRIPLE} -fPIC -funwind-tables -isystem ${OO_PS4_TOOLCHAIN}/include/c++/v1 -isystem ${OO_PS4_TOOLCHAIN}/include")
set(CMAKE_ASM_FLAGS_INIT "--target=${PS4_TRIPLE}")

set(CMAKE_SYSROOT "${OO_PS4_TOOLCHAIN}")

# Kodi's target dependencies are a separate target prefix from the OpenOrbis
# SDK. Keep both available to CMake's target-side find_*() logic, with the
# dependency prefix taking precedence for Kodi-built libraries and headers.
set(CMAKE_FIND_ROOT_PATH "${OO_PS4_TOOLCHAIN}")
if(DEFINED DEPENDS_PATH AND DEPENDS_PATH)
  list(PREPEND CMAKE_FIND_ROOT_PATH "${DEPENDS_PATH}")
  set(CMAKE_LIBRARY_PATH "${DEPENDS_PATH}/lib")
endif()

# Kodi target dependencies use both FreeBSD-style pkg-config locations.
# Restrict pkg-config to the PS4 target prefix so host packages cannot satisfy
# target dependency discovery.
if(DEFINED DEPENDS_PATH AND DEPENDS_PATH)
  set(_PS4_PKG_CONFIG_LIBDIRS
      "${DEPENDS_PATH}/lib/pkgconfig:${DEPENDS_PATH}/libdata/pkgconfig")
  set(ENV{PKG_CONFIG_LIBDIR} "${_PS4_PKG_CONFIG_LIBDIRS}")
endif()

set(CMAKE_C_COMPILER_TARGET "${PS4_TRIPLE}")
set(CMAKE_CXX_COMPILER_TARGET "${PS4_TRIPLE}")

# Match the validated OpenOrbis hello_world link flow:
# - no host C/C++ runtime;
# - OpenOrbis' linker script controls the PS4 executable layout;
# - target libraries are supplied explicitly below.
set(CMAKE_EXE_LINKER_FLAGS_INIT
    "--target=${PS4_TRIPLE} -fuse-ld=lld -nostdlib -pie -Wl,--script=${OO_PS4_TOOLCHAIN}/link.x -L${OO_PS4_TOOLCHAIN}/lib")

set(CMAKE_C_STANDARD_LIBRARIES_INIT
    "-lc -lkernel")
set(CMAKE_CXX_STANDARD_LIBRARIES_INIT
    "-lc -lkernel -lc++")

set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)

set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)
