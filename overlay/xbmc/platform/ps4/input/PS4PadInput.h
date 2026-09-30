/*
 *  Copyright (C) 2026 Team Kodi
 *  This file is part of Kodi - https://kodi.tv
 *
 *  SPDX-License-Identifier: GPL-2.0-or-later
 *  See LICENSES/README.md for more information.
 */

#pragma once

#include "threads/Thread.h"

#include <chrono>
#include <cstdint>

namespace KODI::PLATFORM::PS4
{

/*!
 * \brief Phase-1 DualShock 4 bridge for the PS4 platform.
 *
 * Polls the primary PS4 user controller through OpenOrbis scePad and injects
 * Kodi keyboard events. This intentionally mirrors the first-stage PS5 port
 * approach; a real Kodi peripheral/joystick provider can replace it later.
 */
class CPS4PadInput : public CThread
{
public:
  CPS4PadInput();
  ~CPS4PadInput() override;

  void Start();
  void Stop();

protected:
  void Process() override;

private:
  bool InitLibraries();
  bool OpenPad();
  void ClosePad();
  void PollPad();

  static uint32_t StickToDpad(uint8_t x, uint8_t y);
  static uint16_t ButtonToKeysym(uint32_t button);
  void EmitButton(uint32_t button, bool down);
  void EmitKeysym(uint16_t sym, bool down);

  int32_t m_pad{-1};
  int32_t m_userId{-1};
  uint32_t m_lastButtons{0};
  uint32_t m_heldRepeat{0};
  bool m_librariesReady{false};
};

} // namespace KODI::PLATFORM::PS4
