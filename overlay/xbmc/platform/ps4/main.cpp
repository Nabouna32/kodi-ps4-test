/*
 *  Copyright (C) 2026 Team Kodi
 *  This file is part of Kodi - https://kodi.tv
 *
 *  SPDX-License-Identifier: GPL-2.0-or-later
 *  See LICENSES/README.md for more information.
 */

#include "application/AppEnvironment.h"
#include "application/AppParamParser.h"
#include "platform/xbmc.h"

#include "platform/posix/PlatformPosix.h"

#include <clocale>
#include <csignal>
#include <cstring>

namespace
{
extern "C" void XBMC_PS4_HandleSignal(int)
{
  CPlatformPosix::RequestQuit();
}
} // namespace

int main(int argc, char* argv[])
{
  struct sigaction signalHandler{};
  signalHandler.sa_handler = &XBMC_PS4_HandleSignal;
  signalHandler.sa_flags = SA_RESTART;
  sigaction(SIGINT, &signalHandler, nullptr);
  sigaction(SIGTERM, &signalHandler, nullptr);

  setlocale(LC_NUMERIC, "C");

  CAppParamParser appParamParser;
  appParamParser.Parse(argv, argc);

  CAppEnvironment::SetUp(appParamParser.GetAppParams());
  const int status = XBMC_Run(true);
  CAppEnvironment::TearDown();

  return status;
}
