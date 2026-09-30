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
file(COPY "${PROJECT_ROOT}/overlay/tools/depends/configure.ac"
  DESTINATION "${KODI_SRC}/tools/depends")

message(STATUS "Applied PS4 Kodi overlay to: ${KODI_SRC}")
