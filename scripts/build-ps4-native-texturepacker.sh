#!/usr/bin/env bash
set -euo pipefail

KODI_SRC="${KODI_SRC:?KODI_SRC must point to the materialized Kodi source tree}"
NATIVEPREFIX="${NATIVEPREFIX:?NATIVEPREFIX must point to the native host-tools prefix}"
JOBS="${JOBS:-$(nproc)}"

SRC="${KODI_SRC}/tools/depends/native/TexturePacker/src"
BUILD="${NATIVEPREFIX}/build-TexturePacker"

if [[ ! -f "${SRC}/CMakeLists.txt" ]]; then
  echo "TexturePacker source not found: ${SRC}" >&2
  exit 1
fi

mkdir -p "${NATIVEPREFIX}"

echo "==> configuring native TexturePacker"
echo "    source: ${SRC}"
echo "    prefix: ${NATIVEPREFIX}"

cmake -S "${SRC}" -B "${BUILD}" -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_C_COMPILER=/usr/bin/cc \
  -DCMAKE_CXX_COMPILER=/usr/bin/c++ \
  -DCMAKE_INSTALL_PREFIX="${NATIVEPREFIX}" \
  -DKODI_SOURCE_DIR="${KODI_SRC}" \
  -DAPP_NAME_LC=kodi \
  -DARCH_DEFINES="-DTARGET_POSIX;-DTARGET_LINUX;-D_GNU_SOURCE"

cmake --build "${BUILD}" --parallel "${JOBS}"
cmake --install "${BUILD}"

if [[ ! -x "${NATIVEPREFIX}/bin/TexturePacker" ]]; then
  echo "Native TexturePacker was not installed at ${NATIVEPREFIX}/bin/TexturePacker" >&2
  exit 1
fi

echo "==> native TexturePacker ready: ${NATIVEPREFIX}/bin/TexturePacker"
