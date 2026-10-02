# WSL Host Dependencies

This document records host-side Ubuntu/WSL packages actually required by the current Kodi PS4 workflow. They never satisfy PS4 target dependencies.

## Validated environment

- Ubuntu 26.04.1 LTS / WSL2
- x86_64
- LLVM/Clang/LLD 21.1.8 — validated standalone PS4 smoke-test baseline
- LLVM/Clang/LLD 18.1.8 — diagnostic experiment only
- OpenOrbis: `~/opt/OpenOrbis/PS4Toolchain`

## Direct packages

| Package | Purpose |
|---|---|
| `liblzo2-dev` | Kodi native TexturePacker |
| `libpng-dev` | Kodi native TexturePacker |
| `libgif-dev` | Kodi native TexturePacker |
| `libjpeg-dev` | Kodi native TexturePacker |
| `libcurl4-openssl-dev` | Kodi native CMake bootstrap with system CURL |

Install:

```bash
sudo apt update
sudo apt install -y \
  liblzo2-dev \
  libpng-dev \
  libgif-dev \
  libjpeg-dev \
  libcurl4-openssl-dev
```

APT may install transitive packages; they are not maintained here as a manually curated list unless the project proves they are direct requirements.

## Host tools

Git/GitHub CLI, CMake, Ninja, Clang/LLVM, GCC/G++, Python, Meson, Autotools, pkg-config, NASM and the OpenOrbis toolchain are host tools rather than entries in the package list.

Kodi's native dependency system supplies several build-time tools into:

```
build/ps4/build/x86_64-linux-gnu-native/
```

## Host/target rule

A package belongs here only when a program executes on WSL/Linux and genuinely needs it.

- `libcurl4-openssl-dev` → valid host dependency for native CMake.
- Ubuntu `libharfbuzz-dev` → not a solution for PS4 target HarfBuzz.
- Ubuntu `libiconv-dev` → not a solution for the PS4 Iconv detection issue.

Target dependencies are built for the PS4 target and staged in the target prefix.

## LLVM 18 experiment

LLVM 18.1.8 was installed alongside LLVM 21 to test whether the OpenOrbis v0.5.4 `cmath` failure was compiler-version specific.

It reproduced the same failure. LLVM 18 is therefore not a project fix or required baseline. The repository continues to use generic LLVM command names.

## Maintenance

Keep only directly required, verified host packages here. Do not turn this into an “install everything” list or retain transient APT transaction details that do not help reproduce the environment.
