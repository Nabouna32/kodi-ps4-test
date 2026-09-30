# PlayStation 4 architecture setup for the OpenOrbis bring-up build.

if(NOT CMAKE_TOOLCHAIN_FILE)
  message(FATAL_ERROR
    "The ps4 platform must be built with openorbis-ps4-kodi.cmake")
endif()

set(CORE_MAIN_SOURCE ${CMAKE_SOURCE_DIR}/xbmc/platform/ps4/main.cpp)

set(PLATFORM_DIR platform/ps4)
set(PLATFORMDEFS_DIR platform/posix)

set(ARCH_DEFINES
    -DTARGET_POSIX
    -DTARGET_FREEBSD
    -DTARGET_PS4)
set(SYSTEM_DEFINES
    -D__STDC_CONSTANT_MACROS
    -D_LARGEFILE64_SOURCE
    -D_FILE_OFFSET_BITS=64)

set(ARCH x86_64-ps4)
set(CPU x86_64)
set(NEON False)
set(HOST_CAN_EXECUTE_TARGET FALSE)

set(USE_INTERNAL_LIBS ON CACHE BOOL
    "PS4 bring-up: build dependencies internally where Kodi supports it" FORCE)

set(ENABLE_GOLD OFF CACHE BOOL "PS4: gold disabled" FORCE)
set(ENABLE_LLD ON CACHE BOOL "PS4: lld enabled" FORCE)
set(ENABLE_MOLD OFF CACHE BOOL "PS4: mold disabled" FORCE)

set(ENABLE_PYTHON OFF CACHE BOOL "PS4 bring-up: Python disabled" FORCE)
set(ENABLE_OPTICAL OFF CACHE BOOL "PS4 bring-up: optical disabled" FORCE)
set(ENABLE_DVDCSS OFF CACHE BOOL "PS4 bring-up: DVD CSS disabled" FORCE)
set(ENABLE_EVENTCLIENTS OFF CACHE BOOL "PS4 bring-up: event clients disabled" FORCE)
set(ENABLE_TESTING OFF CACHE BOOL "PS4 bring-up: tests disabled" FORCE)

set(AUDIO_BACKENDS_LIST ps4)

set(SYSTEM_LDFLAGS
    -lSceSysmodule
    -lSceUserService
    -lScePad
    -lSceAudioOut
    -lSceNet
    -lSceNetCtl
    -lScePigletv2VSH)

set(PATH_DEFINES
    -DBIN_INSTALL_PATH="${libdir}/${APP_NAME_LC}"
    -DINSTALL_PATH="${datarootdir}/${APP_NAME_LC}")
