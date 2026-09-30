# PS4 install rules are intentionally minimal during bring-up.
# The executable/package conversion will be added once the first cross build
# is reproducible and the Kodi runtime layout is validated on console.

include(GNUInstallDirs)

if(NOT CMAKE_INSTALL_PREFIX)
  set(CMAKE_INSTALL_PREFIX /app0)
endif()
