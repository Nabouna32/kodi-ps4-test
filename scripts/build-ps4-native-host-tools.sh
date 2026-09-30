#!/usr/bin/env bash
set -euo pipefail

KODI_SRC="${KODI_SRC:?KODI_SRC must point to the materialized Kodi source tree}"
NATIVEPREFIX="${NATIVEPREFIX:?NATIVEPREFIX must point to the native host-tools prefix}"
JOBS="${JOBS:-$(nproc)}"

TOOLS=(
  TexturePacker
  JsonSchemaBuilder
)

mkdir -p "${NATIVEPREFIX}"

build_tool() {
  local tool="$1"
  local src="${KODI_SRC}/tools/depends/native/${tool}/src"
  local build="${NATIVEPREFIX}/build-${tool}"

  if [[ ! -f "${src}/CMakeLists.txt" ]]; then
    echo "${tool} source not found: ${src}" >&2
    exit 1
  fi

  echo "==> configuring native ${tool}"
  echo "    source: ${src}"
  echo "    prefix: ${NATIVEPREFIX}"

  cmake -S "${src}" -B "${build}" -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_C_COMPILER=/usr/bin/cc \
    -DCMAKE_CXX_COMPILER=/usr/bin/c++ \
    -DCMAKE_INSTALL_PREFIX="${NATIVEPREFIX}" \
    -DKODI_SOURCE_DIR="${KODI_SRC}" \
    -DAPP_NAME_LC=kodi \
    -DARCH_DEFINES="-DTARGET_POSIX;-DTARGET_LINUX;-D_GNU_SOURCE"

  cmake --build "${build}" --parallel "${JOBS}"
  cmake --install "${build}"
}

for tool in "${TOOLS[@]}"; do
  build_tool "${tool}"
done

for tool in "${TOOLS[@]}"; do
  executable="${NATIVEPREFIX}/bin/${tool}"
  if [[ "${tool}" == "JsonSchemaBuilder" ]]; then
    executable="${NATIVEPREFIX}/bin/kodi-JsonSchemaBuilder"
  fi

  if [[ ! -x "${executable}" ]]; then
    echo "Native ${tool} was not installed at ${executable}" >&2
    exit 1
  fi

  echo "==> native ${tool} ready: ${executable}"
done
