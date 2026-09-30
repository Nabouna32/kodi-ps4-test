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

NATIVEPREFIX="${BUILD_DIR}/build/native"
DEPENDS_ROOT="${BUILD_DIR}/build"

link_native_tool() {
  local name="$1"
  local source
  source="$(command -v "$name" || true)"
  if [[ -z "$source" ]]; then
    echo "Missing host build tool: $name" >&2
    exit 1
  fi
  mkdir -p "${NATIVEPREFIX}/bin"
  if [[ ! -e "${NATIVEPREFIX}/bin/${name}" ]]; then
    ln -s "$source" "${NATIVEPREFIX}/bin/${name}"
  fi
}

for tool in cmake meson ninja pkg-config python3; do
  link_native_tool "$tool"
done

if ! command -v nasm >/dev/null 2>&1; then
  echo "Missing host build tool: nasm (required by Kodi generated target Toolchain.cmake)" >&2
  exit 1
fi

KODI_SRC="${KODI_SRC}" \
NATIVEPREFIX="${NATIVEPREFIX}" \
JOBS="${JOBS:-$(nproc)}" \
  bash "${ROOT}/scripts/build-ps4-native-host-tools.sh"

echo "==> bootstrapping Kodi target dependency configuration"
(
  cd "${KODI_SRC}/tools/depends"
  ./bootstrap
  ./configure \
    --host=x86_64-pc-freebsd12 \
    --with-platform=ps4 \
    --with-cpu=x86_64 \
    --with-toolchain="${OO_PS4_TOOLCHAIN}" \
    --with-linker=ld.lld \
    --prefix="${DEPENDS_ROOT}" \
    --disable-debug \
    --disable-ccache
)

TARGET_DEPS_PREFIX="${DEPENDS_ROOT}/x86_64-pc-freebsd12-release"
EXPECTED_NATIVEPREFIX="${DEPENDS_ROOT}/x86_64-pc-linux-gnu-native"
if [[ ! -e "${EXPECTED_NATIVEPREFIX}" ]]; then
  ln -s "${NATIVEPREFIX}" "${EXPECTED_NATIVEPREFIX}"
fi

echo "==> building only Kodi target dependencies required by HarfBuzz"
make -C "${KODI_SRC}/tools/depends/target" \
  -j"${JOBS:-$(nproc)}" \
  harfbuzz

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
