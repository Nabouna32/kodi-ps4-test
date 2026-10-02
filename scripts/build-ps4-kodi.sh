#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
KODI_UPSTREAM_SRC="${ROOT}/references/kodi"
BUILD_DIR="${ROOT}/build/ps4"
KODI_SRC="${BUILD_DIR}/kodi-source"

: "${OO_PS4_TOOLCHAIN:?Set OO_PS4_TOOLCHAIN to the OpenOrbis installation root}"

if [[ ! -f "${OO_PS4_TOOLCHAIN}/link.x" ]]; then
  echo "Invalid OO_PS4_TOOLCHAIN: ${OO_PS4_TOOLCHAIN}" >&2
  exit 1
fi

rm -rf "${KODI_SRC}"
mkdir -p "${KODI_SRC}"

echo "==> materializing pinned Kodi source into ${KODI_SRC}"
git -C "${KODI_UPSTREAM_SRC}" archive --format=tar HEAD | tar -x -C "${KODI_SRC}"

cmake \
  -DPROJECT_ROOT="${ROOT}" \
  -DKODI_SRC="${KODI_SRC}" \
  -P "${ROOT}/scripts/apply-kodi-overlay.cmake"

DEPENDS_ROOT="${BUILD_DIR}/build"
JOBS="${JOBS:-$(nproc)}"

echo "==> bootstrapping Kodi target dependency configuration"
(
  cd "${KODI_SRC}/tools/depends"
  ./bootstrap
  ./configure \
    --host=x86_64-pc-freebsd12 \
    --with-platform=ps4 \
    --with-cpu=x86_64 \
    --with-toolchain="${OO_PS4_TOOLCHAIN}" \
    --with-linker=lld \
    --prefix="${DEPENDS_ROOT}" \
    --disable-debug \
    --disable-ccache
)

echo "==> building Kodi native dependency toolchain"
make -C "${KODI_SRC}/tools/depends/native" \
  -j"${JOBS}" \
  native
make -C "${KODI_SRC}/tools/depends/native/JsonSchemaBuilder" \
  -j"${JOBS}"

TARGET_DEPS_PREFIX="${DEPENDS_ROOT}/x86_64-pc-freebsd12-release"
NATIVEPREFIX="${DEPENDS_ROOT}/x86_64-linux-gnu-native"

for tool in cmake ninja meson pkg-config python3 nasm TexturePacker JsonSchemaBuilder; do
  if [[ ! -x "${NATIVEPREFIX}/bin/${tool}" ]]; then
    echo "Missing Kodi native tool: ${NATIVEPREFIX}/bin/${tool}" >&2
    exit 1
  fi
done

echo "==> building Kodi target dependencies required by ASS/libass"
make -C "${KODI_SRC}/tools/depends/target" \
  -j"${JOBS}" \
  fribidi harfbuzz fontconfig
make -C "${KODI_SRC}/tools/depends/target/brotli" \
  -j"${JOBS}"
make -C "${KODI_SRC}/tools/depends/target/openssl" \
  -j"${JOBS}"

cmake -S "${KODI_SRC}" -B "${BUILD_DIR}" -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_TOOLCHAIN_FILE="${ROOT}/cmake/toolchains/openorbis-ps4-kodi.cmake" \
  -DCORE_SYSTEM_NAME=ps4 \
  -DCORE_PLATFORM_NAME=ps4 \
  -DAPP_RENDER_SYSTEM=gles \
  -DNATIVEPREFIX="${NATIVEPREFIX}" \
  -DDEPENDS_PATH="${TARGET_DEPS_PREFIX}" \
  -DWITH_TEXTUREPACKER="${NATIVEPREFIX}/bin" \
  -DWITH_JSONSCHEMABUILDER="${NATIVEPREFIX}/bin" \
  -DINTERNAL_TEXTUREPACKER_INSTALLABLE=FALSE \
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

if [[ "${CONFIGURE_ONLY:-0}" == "1" ]]; then
  echo "==> configure-only requested; skipping Kodi build"
  exit 0
fi

cmake --build "${BUILD_DIR}" --parallel "${JOBS:-$(nproc)}"
