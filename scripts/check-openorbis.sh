#!/usr/bin/env bash
set -euo pipefail

: "${OO_PS4_TOOLCHAIN:?Set OO_PS4_TOOLCHAIN to the OpenOrbis installation root}"

fail=0

check_cmd() {
  local name="$1"
  if command -v "$name" >/dev/null 2>&1; then
    printf 'OK   %-12s %s\n' "$name" "$(command -v "$name")"
  else
    printf 'MISS %-12s not found on PATH\n' "$name"
    fail=1
  fi
}

printf 'OpenOrbis environment check\n'
printf '===========================\n'
printf 'OO_PS4_TOOLCHAIN=%s\n' "$OO_PS4_TOOLCHAIN"

if [[ -f "$OO_PS4_TOOLCHAIN/link.x" ]]; then
  printf 'OK   %-12s %s\n' 'link.x' "$OO_PS4_TOOLCHAIN/link.x"
else
  printf 'MISS %-12s %s\n' 'link.x' "$OO_PS4_TOOLCHAIN/link.x"
  fail=1
fi

check_cmd clang
check_cmd clang++
check_cmd ld.lld
check_cmd cmake
check_cmd ninja

if [[ -d "$OO_PS4_TOOLCHAIN/bin" ]]; then
  printf 'OK   %-12s %s\n' 'OO bin' "$OO_PS4_TOOLCHAIN/bin"
else
  printf 'WARN %-12s directory not found\n' 'OO bin'
fi

if (( fail != 0 )); then
  printf '\nEnvironment is not ready for the PS4 configure step.\n' >&2
  exit 1
fi

printf '\nEnvironment is ready for the first OpenOrbis smoke build.\n'
