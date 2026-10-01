# WSL host dependencies

This document records **host-side Ubuntu/WSL development packages** that have been explicitly identified and installed during the Kodi PS4 porting work. It exists so a new WSL machine can be prepared without depending on chat history.

> **Scope:** these packages are for Linux host tools. They are not PS4 target libraries. Target dependencies must still be built for the OpenOrbis/FreeBSD target.

## Base environment

Validated build environment:

- Ubuntu 26.04.1 LTS / WSL
- x86_64 host
- Clang/LLVM 21.1.8
- OpenOrbis PS4 toolchain under `~/opt/OpenOrbis/PS4Toolchain`

## Direct host development packages identified by the project

These are the packages explicitly documented as required/installed for the host build so far:

| Package | Why it is needed |
|---|---|
| `liblzo2-dev` | Kodi native TexturePacker host build |
| `libpng-dev` | Kodi native TexturePacker host build |
| `libgif-dev` | Kodi native TexturePacker host build |
| `libjpeg-dev` | Kodi native TexturePacker host build |
| `libcurl4-openssl-dev` | Official Kodi native CMake bootstrap; the recipe uses `--system-curl` |

Install the direct project packages with:

```bash
sudo apt update
sudo apt install -y \
  liblzo2-dev \
  libpng-dev \
  libgif-dev \
  libjpeg-dev \
  libcurl4-openssl-dev
```

## Important: transitive packages

Installing `libcurl4-openssl-dev` on Ubuntu 26.04 pulled additional development/runtime packages, including OpenSSL, Kerberos, LDAP, GnuTLS, Brotli, IDN2, nghttp2, SSH2, PSL, GMP, Zstd, RTMP and related packages.

Those packages are **not listed as separate project prerequisites** because they were installed by APT as dependencies of the direct host package. A fresh machine should normally let APT resolve them rather than maintaining a manually duplicated transitive list.

The exact transaction on 2026-10-01 installed 28 new packages (including `libcurl4-openssl-dev`) and upgraded 4 existing packages. The 27 packages other than the requested direct package were APT-resolved dependencies, including:

- `libssl-dev`
- `libkrb5-dev`
- `libldap-dev`
- `libnghttp2-dev`
- `libgnutls28-dev`
- `libssh2-1-dev`
- `libbrotli-dev`
- `libidn2-dev`
- `libpsl-dev`
- `librtmp-dev`
- `libzstd-dev`
- `libgmp-dev`
- `libtasn1-6-dev`
- `libp11-kit-dev`
- `nettle-dev`
- `libevent-2.1-7t64`
- Kerberos/GSS and related development packages

These are recorded for forensic/reproducibility context, not as packages that must all be installed manually.

## Host tools versus APT libraries

The following are also part of the validated build environment, but are **tools rather than this package list**:

- Git
- GitHub CLI
- CMake
- Ninja
- Clang/LLVM
- GCC/G++
- Python
- Meson
- Autotools
- pkg-config
- NASM
- OpenOrbis PS4 toolchain

Kodi's own `tools/depends/native` is responsible for building/placing several native build tools in:

```text
build/ps4/build/x86_64-linux-gnu-native/
```

Do not confuse that native prefix with the PS4 target dependency prefix:

```text
build/ps4/build/x86_64-pc-freebsd12-release/
```

## Host/target rule

A host package is correct when a program **runs on WSL/Linux** and needs it.

A host package is not a substitute when Kodi is looking for a **PS4 target library**.

Example:

- `libcurl4-openssl-dev` → valid host dependency for native CMake.
- Ubuntu `libharfbuzz-dev` → **not** a solution for PS4 target HarfBuzz.

## Rebuilding a new WSL machine

Start with the direct packages above, then follow `docs/BUILD.md` and the documented OpenOrbis/toolchain setup. As new host packages are genuinely required and verified, add them here with the reason and the date/discovery that established them.

Do not turn this file into a guessed “install everything” list. It should remain an evidence-based record of packages actually required by the project.
