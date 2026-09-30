/*
 *  Copyright (C) 2026 Team Kodi
 *  This file is part of Kodi - https://kodi.tv
 *
 *  SPDX-License-Identifier: GPL-2.0-or-later
 *  See LICENSES/README.md for more information.
 */

#include "PlatformPS4.h"

CPlatform* CPlatform::CreateInstance()
{
  return new CPlatformPS4();
}

bool CPlatformPS4::InitStageOne()
{
  return CPlatformPosix::InitStageOne();
}

void CPlatformPS4::DeinitStageOne()
{
}

bool CPlatformPS4::IsConfigureAddonsAtStartupEnabled()
{
  return false;
}
