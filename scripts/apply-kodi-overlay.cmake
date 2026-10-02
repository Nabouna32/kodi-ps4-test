# Apply the repository's PS4 overlay to the pinned Kodi checkout before configuration.
#
# This intentionally modifies references/kodi at build time. The checkout remains
# the pinned upstream source plus this repository's generated/applied overlay.

if(NOT DEFINED PROJECT_ROOT OR PROJECT_ROOT STREQUAL "")
  get_filename_component(PROJECT_ROOT "${CMAKE_CURRENT_LIST_DIR}/.." ABSOLUTE)
endif()

if(NOT DEFINED KODI_SRC OR KODI_SRC STREQUAL "")
  set(KODI_SRC "${PROJECT_ROOT}/references/kodi")
endif()

if(NOT EXISTS "${KODI_SRC}/CMakeLists.txt")
  message(FATAL_ERROR "KODI_SRC does not look like a Kodi source checkout: ${KODI_SRC}")
endif()

set(OVERLAY_DIRS
  "cmake/platform/ps4"
  "cmake/scripts/ps4"
  "overlay/xbmc/platform/ps4"
)

foreach(relative_dir IN LISTS OVERLAY_DIRS)
  set(source_dir "${PROJECT_ROOT}/${relative_dir}")

  if(NOT IS_DIRECTORY "${source_dir}")
    message(FATAL_ERROR "Missing overlay directory: ${source_dir}")
  endif()
endforeach()

file(COPY "${PROJECT_ROOT}/cmake/platform/ps4"
  DESTINATION "${KODI_SRC}/cmake/platform")
file(COPY "${PROJECT_ROOT}/cmake/scripts/ps4"
  DESTINATION "${KODI_SRC}/cmake/scripts")
file(COPY "${PROJECT_ROOT}/overlay/xbmc/platform/ps4"
  DESTINATION "${KODI_SRC}/xbmc/platform")
file(COPY "${PROJECT_ROOT}/overlay/tools/depends/target/zlib/Makefile"
  DESTINATION "${KODI_SRC}/tools/depends/target/zlib")
file(COPY "${PROJECT_ROOT}/overlay/tools/depends/target/openssl/0001-openorbis-in6-addr.patch"
  DESTINATION "${KODI_SRC}/tools/depends/target/openssl")
file(COPY "${PROJECT_ROOT}/overlay/tools/depends/target/openssl/0002-openorbis-endian-header.patch"
  DESTINATION "${KODI_SRC}/tools/depends/target/openssl")
file(COPY "${PROJECT_ROOT}/overlay/tools/depends/target/openssl/0003-openorbis-openssl-ps4-random.patch"
  DESTINATION "${KODI_SRC}/tools/depends/target/openssl")
execute_process(
  COMMAND patch --dry-run -p1 -i "${PROJECT_ROOT}/overlay/tools/depends/0001-openorbis-ps4-target-depends.patch"
  WORKING_DIRECTORY "${KODI_SRC}"
  RESULT_VARIABLE PATCH_DRY_RUN_RESULT)
if(NOT PATCH_DRY_RUN_RESULT EQUAL 0)
  message(FATAL_ERROR "OpenOrbis PS4 target-dependency patch does not match the pinned Kodi source")
endif()
execute_process(
  COMMAND patch -p1 -i "${PROJECT_ROOT}/overlay/tools/depends/0001-openorbis-ps4-target-depends.patch"
  WORKING_DIRECTORY "${KODI_SRC}"
  RESULT_VARIABLE PATCH_RESULT)
if(NOT PATCH_RESULT EQUAL 0)
  message(FATAL_ERROR "Failed to apply OpenOrbis PS4 target-dependency patch")
endif()

execute_process(
  COMMAND patch --dry-run -p1 -i "${PROJECT_ROOT}/overlay/tools/depends/0002-openorbis-openssl-in6-addr.patch"
  WORKING_DIRECTORY "${KODI_SRC}"
  RESULT_VARIABLE OPENSSL_PATCH_DRY_RUN_RESULT)
if(NOT OPENSSL_PATCH_DRY_RUN_RESULT EQUAL 0)
  message(FATAL_ERROR "OpenOrbis OpenSSL compatibility patch does not match the pinned Kodi source")
endif()
execute_process(
  COMMAND patch -p1 -i "${PROJECT_ROOT}/overlay/tools/depends/0002-openorbis-openssl-in6-addr.patch"
  WORKING_DIRECTORY "${KODI_SRC}"
  RESULT_VARIABLE OPENSSL_PATCH_RESULT)
if(NOT OPENSSL_PATCH_RESULT EQUAL 0)
  message(FATAL_ERROR "Failed to apply OpenOrbis OpenSSL compatibility patch")
endif()

message(STATUS "Applied PS4 Kodi overlay to: ${KODI_SRC}")
