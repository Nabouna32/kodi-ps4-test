#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
KODI_SRC="${ROOT}/references/kodi"
BUILD_DIR="${ROOT}/build/ps4"

: "${OO_PS4_TOOLCHAIN:?Set OO_PS4_TOOLCHAIN to the OpenOrbis installation root}"

if [[ ! -f "${OO_PS4_TOOLCHAIN}/link.x" ]]; then
  echo "Invalid OO_PS4_TOOLCHAIN: ${OO_PS4_TOOLCHAIN}" >&2
  exit 1
fi

cmake \
  -DPROJECT_ROOT="${ROOT}" \
  -DKODI_SRC="${KODI_SRC}" \
  -P "${ROOT}/scripts/apply-kodi-overlay.cmake"

cmake -S "${KODI_SRC}" -B "${BUILD_DIR}" -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_TOOLCHAIN_FILE="${ROOT}/cmake/toolchains/openorbis-ps4-kodi.cmake" \
  -DCORE_SYSTEM_NAME=ps4 \
  -DCORE_PLATFORM_NAME=ps4 \
  -DAPP_RENDER_SYSTEM=gles \
  -DENABLE_PYTHON=OFF \
  -DENABLE_TESTING=OFF \
  -DENABLE_OPTICAL=OFF \
  -DENABLE_DVDCSS=OFF \
  -DENABLE_EVENTCLIENTS=OFF \
  -DENABLE_AIRTUNES=OFF \
  -DENABLE_CEC=OFF \
  -DENABLE_DBUS=OFF \
  -DENABLE_PIPEWIRE=OFF \
  -DENABLE_PULSEAUDIO=OFF \
  -DENABLE_SNDIO=OFF \
  -DENABLE_ALSA=OFF

cmake --build "${BUILD_DIR}" --parallel "${JOBS:-$(nproc)}"
