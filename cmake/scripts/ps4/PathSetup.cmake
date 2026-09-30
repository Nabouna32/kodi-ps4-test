# Runtime/install paths for the PS4 title image.

include(GNUInstallDirs)

if(NOT prefix)
  set(prefix ${CMAKE_INSTALL_PREFIX})
endif()
if(NOT exec_prefix)
  set(exec_prefix ${prefix})
endif()
if(NOT libdir)
  set(libdir ${prefix}/lib)
endif()
if(NOT bindir)
  set(bindir ${prefix}/bin)
endif()
if(NOT includedir)
  set(includedir ${prefix}/include)
endif()
if(NOT datarootdir)
  set(datarootdir ${prefix}/share)
endif()
if(NOT datadir)
  set(datadir ${datarootdir})
endif()

set(PATH_DEFINES
    -DBIN_INSTALL_PATH="${libdir}/${APP_NAME_LC}"
    -DINSTALL_PATH="${datadir}/${APP_NAME_LC}")

list(APPEND final_message "-- PS4 PATH config --")
list(APPEND final_message "Prefix: ${prefix}")
list(APPEND final_message "Datarootdir: ${datarootdir}")
