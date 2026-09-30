# PlayStation 4 homebrew platform.
#
# Bring-up profile: keep Kodi's common code and only the dependencies required
# to reach the first on-console GUI. Optional desktop/console integrations are
# explicitly disabled here and can be enabled later as they become supported.

set(CORE_SYSTEM_NAME ps4 CACHE STRING "Kodi core system name" FORCE)
set(CORE_PLATFORM_NAME ps4 CACHE STRING "Kodi platform" FORCE)

set(APP_RENDER_SYSTEM gles CACHE STRING "Kodi render system" FORCE)

set(PLATFORM_REQUIRED_DEPS EGL)
set(PLATFORM_OPTIONAL_DEPS_EXCLUDE
    Alsa
    Avahi
    Bluetooth
    CAP
    Bluray
    CEC
    DBus
    LircClient
    Pipewire
    PulseAudio
    Sndio
    UDEV
    XSLT)

# The first build is a core bring-up build. Binary add-ons are built separately
# by Kodi's add-on buildsystem and are intentionally not part of this target.
set(ENABLE_PYTHON OFF CACHE BOOL "PS4 bring-up: Python add-ons disabled" FORCE)
set(ENABLE_OPTICAL OFF CACHE BOOL "PS4: optical media disabled" FORCE)
set(ENABLE_DVDCSS OFF CACHE BOOL "PS4: DVD CSS disabled" FORCE)
set(ENABLE_EVENTCLIENTS OFF CACHE BOOL "PS4: event clients disabled" FORCE)
set(ENABLE_TESTING OFF CACHE BOOL "PS4: host tests disabled" FORCE)
set(ENABLE_BLURAY OFF CACHE BOOL "PS4 bring-up: Blu-ray support disabled" FORCE)

# These facilities depend on later PS4 platform work. Keep the build honest
# instead of allowing host libraries to leak into the cross build.
set(ENABLE_AIRTUNES OFF CACHE BOOL "PS4: AirTunes disabled" FORCE)
set(ENABLE_CEC OFF CACHE BOOL "PS4: CEC disabled" FORCE)
set(ENABLE_DBUS OFF CACHE BOOL "PS4: D-Bus disabled" FORCE)
set(ENABLE_PIPEWIRE OFF CACHE BOOL "PS4: PipeWire disabled" FORCE)
set(ENABLE_PULSEAUDIO OFF CACHE BOOL "PS4: PulseAudio disabled" FORCE)
set(ENABLE_SNDIO OFF CACHE BOOL "PS4: sndio disabled" FORCE)
set(ENABLE_ALSA OFF CACHE BOOL "PS4: ALSA disabled" FORCE)
set(ENABLE_UDEV OFF CACHE BOOL "PS4: udev disabled" FORCE)

# Keep the first Kodi build independent of binary add-on repositories.
set(ENABLE_INTERNAL_LIBS ON CACHE BOOL "PS4: prefer Kodi internal dependencies" FORCE)

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

# Do not let Kodi select a host linker for the target.
set(ENABLE_GOLD OFF CACHE BOOL "PS4: gold disabled" FORCE)
set(ENABLE_LLD ON CACHE BOOL "PS4: use lld" FORCE)
set(ENABLE_MOLD OFF CACHE BOOL "PS4: mold disabled" FORCE)

# OpenOrbis provides the target system stubs. More Sony API libraries will be
# added only when their corresponding Kodi subsystem is actually integrated.
set(SYSTEM_LDFLAGS
    -lSceSysmodule
    -lSceUserService
    -lScePad
    -lSceAudioOut
    -lSceNet
    -lSceNetCtl
    -lScePigletv2VSH)

include(GNUInstallDirs)

# Kodi builds some helper programs for the host while cross-compiling the
# target. Keep their prefix separate from the PS4 application install root.
# Native tools such as pkgconf must receive an absolute prefix on Windows.
if(NOT NATIVEPREFIX)
  set(NATIVEPREFIX "${CMAKE_BINARY_DIR}/build/native"
      CACHE PATH "PS4 native build-tools prefix" FORCE)
endif()

if(NOT CMAKE_INSTALL_PREFIX)
  set(CMAKE_INSTALL_PREFIX /app0 CACHE PATH "PS4 application image root" FORCE)
endif()

if(NOT prefix)
  set(prefix "${CMAKE_INSTALL_PREFIX}")
endif()
set(exec_prefix "${prefix}" CACHE PATH "PS4 exec prefix" FORCE)
set(libdir "${prefix}/lib" CACHE PATH "PS4 library directory" FORCE)
set(bindir "${prefix}/bin" CACHE PATH "PS4 binary directory" FORCE)
set(datarootdir "${prefix}/share" CACHE PATH "PS4 data root" FORCE)
set(datadir "${datarootdir}" CACHE PATH "PS4 data directory" FORCE)

set(PATH_DEFINES
    -DBIN_INSTALL_PATH="${libdir}/${APP_NAME_LC}"
    -DINSTALL_PATH="${datadir}/${APP_NAME_LC}")