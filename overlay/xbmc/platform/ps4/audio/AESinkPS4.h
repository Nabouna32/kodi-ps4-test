/*
 *  Copyright (C) 2026 Team Kodi
 *  This file is part of Kodi - https://kodi.tv
 *
 *  SPDX-License-Identifier: GPL-2.0-or-later
 *  See LICENSES/README.md for more information.
 */

#pragma once

#include "cores/AudioEngine/Interfaces/AESink.h"
#include "cores/AudioEngine/Utils/AEDeviceInfo.h"

#include <cstdint>
#include <memory>
#include <string>
#include <vector>

class CAESinkPS4 : public IAESink
{
public:
  const char* GetName() override { return "PS4"; }

  CAESinkPS4() = default;
  ~CAESinkPS4() override;

  static void Register();
  static std::unique_ptr<IAESink> Create(std::string& device, AEAudioFormat& desiredFormat);
  static void EnumerateDevicesEx(AEDeviceInfoList& list, bool force);

  bool Initialize(AEAudioFormat& format, std::string& device) override;
  void Deinitialize() override;

  double GetCacheTotal() override;
  double GetLatency() override;
  unsigned int AddPackets(uint8_t** data, unsigned int frames, unsigned int offset) override;
  void GetDelay(AEDelayStatus& status) override;
  void Drain() override;

private:
  static constexpr unsigned int GRAIN_FRAMES = 256;

  bool OpenPort(AEAudioFormat& format);
  bool Output(const uint8_t* block);

  int32_t m_handle{-1};
  unsigned int m_sampleRate{48000};
  unsigned int m_channels{2};
  unsigned int m_frameSize{0};
  std::vector<uint8_t> m_block;
  unsigned int m_blockFrames{0};
};
