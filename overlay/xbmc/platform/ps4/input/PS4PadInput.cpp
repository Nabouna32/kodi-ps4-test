/*
 *  Copyright (C) 2026 Team Kodi
 *  This file is part of Kodi - https://kodi.tv
 *
 *  SPDX-License-Identifier: GPL-2.0-or-later
 *  See LICENSES/README.md for more information.
 */

#include "PS4PadInput.h"

#include "ServiceBroker.h"
#include "application/AppInboundProtocol.h"
#include "input/keyboard/XBMC_keyboard.h"
#include "utils/log.h"
#include "windowing/XBMC_events.h"

#include <orbis/Pad.h>
#include <orbis/UserService.h>
#include <orbis/_types/pad.h>
#include <orbis/_types/user.h>

#include <cstring>
#include <thread>

using namespace KODI::PLATFORM::PS4;
using namespace std::chrono_literals;

namespace
{
constexpr uint32_t DIRECTION_BITS =
    ORBIS_PAD_BUTTON_UP | ORBIS_PAD_BUTTON_DOWN | ORBIS_PAD_BUTTON_LEFT |
    ORBIS_PAD_BUTTON_RIGHT;

constexpr auto POLL_INTERVAL = 8ms; // Match the PS5 reference's 125 Hz phase-1 bridge.
constexpr auto REPEAT_DELAY = 400ms;
constexpr auto REPEAT_RATE = 80ms;
constexpr uint8_t STICK_DEADZONE = 32;

uint32_t StickToDpad(uint8_t x, uint8_t y)
{
  uint32_t bits = 0;

  if (x < 128 - STICK_DEADZONE)
    bits |= ORBIS_PAD_BUTTON_LEFT;
  else if (x > 128 + CPS4PadInput::STICK_DEADZONE)
    bits |= ORBIS_PAD_BUTTON_RIGHT;

  if (y < 128 - CPS4PadInput::STICK_DEADZONE)
    bits |= ORBIS_PAD_BUTTON_UP;
  else if (y > 128 + CPS4PadInput::STICK_DEADZONE)
    bits |= ORBIS_PAD_BUTTON_DOWN;

  return bits;
}

uint16_t ButtonToKeysym(uint32_t button)
{
  switch (button)
  {
    case ORBIS_PAD_BUTTON_UP:
      return XBMCK_UP;
    case ORBIS_PAD_BUTTON_DOWN:
      return XBMCK_DOWN;
    case ORBIS_PAD_BUTTON_LEFT:
      return XBMCK_LEFT;
    case ORBIS_PAD_BUTTON_RIGHT:
      return XBMCK_RIGHT;
    case ORBIS_PAD_BUTTON_CROSS:
      return XBMCK_RETURN;
    case ORBIS_PAD_BUTTON_CIRCLE:
      return XBMCK_BACKSPACE;
    case ORBIS_PAD_BUTTON_TRIANGLE:
      return XBMCK_c;
    case ORBIS_PAD_BUTTON_SQUARE:
      return XBMCK_i;
    case ORBIS_PAD_BUTTON_OPTIONS:
      return XBMCK_MEDIA_PLAY_PAUSE;
    case ORBIS_PAD_BUTTON_L1:
      return XBMCK_PAGEUP;
    case ORBIS_PAD_BUTTON_R1:
      return XBMCK_PAGEDOWN;
    case ORBIS_PAD_BUTTON_L2:
      return XBMCK_r;
    case ORBIS_PAD_BUTTON_R2:
      return XBMCK_f;
    case ORBIS_PAD_BUTTON_L3:
      return XBMCK_o;
    case ORBIS_PAD_BUTTON_R3:
      return XBMCK_m;
    case ORBIS_PAD_BUTTON_TOUCH_PAD:
      return XBMCK_ESCAPE;
    default:
      return 0;
  }
}
} // namespace

CPS4PadInput::CPS4PadInput() : CThread("PS4PadInput")
{
}

CPS4PadInput::~CPS4PadInput()
{
  Stop();
}

void CPS4PadInput::Start()
{
  if (!IsRunning())
    Create();
}

void CPS4PadInput::Stop()
{
  StopThread(true);
  ClosePad();
}

bool CPS4PadInput::InitLibraries()
{
  if (m_librariesReady)
    return true;

  int result = scePadInit();
  if (result != 0)
  {
    CLog::Log(LOGERROR, "CPS4PadInput: scePadInit failed: {:#x}",
              static_cast<uint32_t>(result));
    return false;
  }

  OrbisUserServiceInitializeParams params{};
  params.priority = ORBIS_KERNEL_PRIO_FIFO_LOWEST;

  result = sceUserServiceInitialize(&params);
  if (result != 0 && result != ORBIS_USER_SERVICE_ERROR_ALREADY_INITIALIZED)
  {
    CLog::Log(LOGERROR, "CPS4PadInput: sceUserServiceInitialize failed: {:#x}",
              static_cast<uint32_t>(result));
    return false;
  }

  result = sceUserServiceGetInitialUser(&m_userId);
  if (result != 0 || m_userId < 0)
  {
    CLog::Log(LOGERROR, "CPS4PadInput: cannot obtain initial user: {:#x}",
              static_cast<uint32_t>(result));
    return false;
  }

  m_librariesReady = true;
  return true;
}

bool CPS4PadInput::OpenPad()
{
  if (m_pad >= 0)
    return true;

  m_pad = scePadOpen(m_userId, ORBIS_PAD_PORT_TYPE_STANDARD, 0, nullptr);
  if (m_pad < 0)
  {
    CLog::Log(LOGWARNING, "CPS4PadInput: scePadOpen failed for user {}: {:#x}", m_userId,
              static_cast<uint32_t>(m_pad));
    return false;
  }

  m_lastButtons = 0;
  m_heldRepeat = 0;
  CLog::Log(LOGINFO, "CPS4PadInput: opened DualShock 4 for user {}", m_userId);
  return true;
}

void CPS4PadInput::ClosePad()
{
  if (m_pad >= 0)
    scePadClose(m_pad);

  m_pad = -1;
  m_lastButtons = 0;
  m_heldRepeat = 0;
}

uint32_t CPS4PadInput::StickToDpad(uint8_t x, uint8_t y)
{
  return ::StickToDpad(x, y);
}

uint16_t CPS4PadInput::ButtonToKeysym(uint32_t button)
{
  return ::ButtonToKeysym(button);
}

void CPS4PadInput::PollPad()
{
  if (m_pad < 0)
    return;

  OrbisPadData data{};
  const int result = scePadRead(m_pad, &data, 1);
  if (result != 0 || !data.connected)
  {
    if (m_lastButtons != 0)
    {
      for (uint32_t bit = 1; bit != 0; bit <<= 1)
      {
        if (m_lastButtons & bit)
          EmitButton(bit, false);
      }
      m_lastButtons = 0;
      m_heldRepeat = 0;
    }
    return;
  }

  uint32_t buttons = data.buttons;
  if ((buttons & DIRECTION_BITS) == 0)
    buttons |= StickToDpad(data.leftStick.x, data.leftStick.y);

  const uint32_t changed = buttons ^ m_lastButtons;

  for (uint32_t bit = 1; bit != 0; bit <<= 1)
  {
    if (changed & bit)
      EmitButton(bit, (buttons & bit) != 0);
  }

  m_lastButtons = buttons;
}

void CPS4PadInput::EmitButton(uint32_t button, bool down)
{
  const uint16_t sym = ButtonToKeysym(button);
  if (sym != 0)
    EmitKeysym(sym, down);
}

void CPS4PadInput::EmitKeysym(uint16_t sym, bool down)
{
  XBMC_Event event = {};
  event.type = down ? XBMC_KEYDOWN : XBMC_KEYUP;
  event.key.keysym.scancode = sym;
  event.key.keysym.sym = static_cast<XBMCKey>(sym);
  event.key.keysym.mod = XBMCKMOD_NONE;
  event.key.keysym.unicode = 0;

  const auto appPort = CServiceBroker::GetAppPort();
  if (appPort)
    appPort->OnEvent(event);
}

void CPS4PadInput::Process()
{
  if (!InitLibraries() || !OpenPad())
  {
    CLog::Log(LOGERROR, "CPS4PadInput: controller initialization failed");
    return;
  }

  auto nextRepeat = std::chrono::steady_clock::now() + REPEAT_DELAY;

  while (!m_bStop)
  {
    const uint32_t previous = m_lastButtons;
    PollPad();
    const uint32_t directions = m_lastButtons & DIRECTION_BITS;
    const uint32_t previousDirections = previous & DIRECTION_BITS;

    if (directions != previousDirections)
    {
      if (directions != 0 && (directions & (directions - 1)) == 0)
      {
        m_heldRepeat = directions;
        nextRepeat = std::chrono::steady_clock::now() + REPEAT_DELAY;
      }
      else
      {
        m_heldRepeat = 0;
      }
    }
    else if (m_heldRepeat != 0 && (m_lastButtons & m_heldRepeat) != 0 &&
             std::chrono::steady_clock::now() >= nextRepeat)
    {
      EmitButton(m_heldRepeat, true);
      nextRepeat = std::chrono::steady_clock::now() + REPEAT_RATE;
    }

    std::this_thread::sleep_for(POLL_INTERVAL);
  }
}
