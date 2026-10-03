# Kodi PS4 Port — Build and Toolchain

## Build architecture

The pinned Kodi source is not modified in the repository by the normal workflow.

```text
references/kodi
  -> git archive HEAD
build/ps4/kodi-source
  -> repository-owned PS4 overlay
Kodi tools/depends + CMake
```

Generated output is under `build/`.

## Host environment

- Ubuntu 26.04.1 LTS / WSL2, x86_64
- LLVM/Clang/LLD 21.1.8 — validated standalone PS4 smoke-test baseline
- LLVM/Clang/LLD 18.1.8 — diagnostic experiment only
- CMake 4.2.3
- Ninja 1.13.2
- Meson 1.10.1
- pkg-config 2.5.1
- OpenOrbis at `~/opt/OpenOrbis/PS4Toolchain`

The repository uses generic LLVM command names rather than hard-coding an Ubuntu LLVM path.

## OpenOrbis validation

Validated minimal chain:

```text
Clang 21
 -> x86_64-pc-freebsd12-elf
 -> LLD + OpenOrbis link.x + crt1.o
 -> target ELF
 -> create-fself
 -> OELF + eboot.bin
```

This is not PS4 runtime validation.

## Prefix separation

Native host tools:
`build/ps4/build/x86_64-linux-gnu-native`

PS4 target dependencies:
`build/ps4/build/x86_64-pc-freebsd12-release`

Never use a Linux host library as a PS4 target dependency.

## Native tools

The build uses Kodi's official native dependency graph:

- `make -C tools/depends/native native`
- `make -C tools/depends/native/JsonSchemaBuilder`

The native prefix must provide `cmake`, `ninja`, `meson`, `pkg-config`, `python3`, `nasm`, `TexturePacker`, and `JsonSchemaBuilder`.

Kodi receives the host generators through `WITH_TEXTUREPACKER` and `WITH_JSONSCHEMABUILDER`. `HOST_CAN_EXECUTE_TARGET=FALSE` remains mandatory.

## PS4 CMake toolchain

`cmake/toolchains/openorbis-ps4-kodi.cmake` uses:

- `CMAKE_SYSTEM_NAME=FreeBSD`
- `CMAKE_SYSTEM_PROCESSOR=x86_64`
- `x86_64-pc-freebsd12-elf`
- OpenOrbis sysroot and `link.x`
- `-fuse-ld=lld`
- target libraries `-lc -lkernel` and `-lc -lkernel -lc++`
- static-library try-compile mode

C++ header order is significant:

```
$OO_PS4_TOOLCHAIN/include/c++/v1
$OO_PS4_TOOLCHAIN/include
```

C compiler flags also expose `$OO_PS4_TOOLCHAIN/include` because CMake's implicit Iconv test otherwise cannot see `iconv.h`.

## Target pkg-config

With `DEPENDS_PATH`, the toolchain sets `PKG_CONFIG_LIBDIR` to:

```
<DEPENDS_PATH>/lib/pkgconfig
<DEPENDS_PATH>/libdata/pkgconfig
```

This prevents host Linux metadata from satisfying target dependency discovery.

## Current target dependencies

Before Kodi CMake configuration, the build stages:

```
fribidi harfbuzz fontconfig ffmpeg
```

The repository-owned zlib overlay copies the pinned Kodi recipe into the materialized source and adds only:

```
-DZLIB_BUILD_TESTING=OFF
```

The target zlib library remains enabled; only its optional testing/coverage executable is disabled.

## Minimal bring-up profile

The initial milestone does not require the full Kodi feature set. Optional integrations such as Blu-ray, XSLT/libxslt, optical media, Python add-ons and several desktop audio/network integrations are disabled or excluded where they are not required for GUI/GLES/controller bring-up.

This is staged bring-up policy, not a permanent feature-removal decision.

## Authoritative configure-only workflow

```bash
cd ~/projects/kodi-ps4-test
export OO_PS4_TOOLCHAIN="$HOME/opt/OpenOrbis/PS4Toolchain"
export PATH="/usr/lib/llvm-21/bin:$OO_PS4_TOOLCHAIN/bin/linux:$PATH"
CONFIGURE_ONLY=1 ./scripts/build-ps4-kodi.sh
```

For repository work, synchronize with `origin/main`, create/switch to the approved task branch, and validate that branch. Do not run the full Kodi build until configure-only succeeds.

## Direct host packages

- `liblzo2-dev`
- `libpng-dev`
- `libgif-dev`
- `libjpeg-dev`
- `libcurl4-openssl-dev`

See `WSL-HOST-DEPENDENCIES.md`.

## Durable investigation conclusions

- The old custom `build/native` compatibility-prefix approach is not used.
- LLVM 18 did not fix the OpenOrbis `cmath`/global-`abs` failure.
- OpenOrbis libc++ headers must precede raw SDK C headers for C++.
- CMake Iconv detection required explicit OpenOrbis C header visibility; no libiconv dependency was added.
- FriBidi and Fontconfig are target dependencies for the current ASS/libass path.
- zlib testing is disabled narrowly because its optional target test executable is incompatible with the current OpenOrbis environment.

## Current validation boundary

The FFmpeg 9.0.2 target dependency staging change is implemented on the approved branch, but fresh WSL configure-only validation is still required. Do not start a full Kodi build until configure-only succeeds.
\n\nThe pinned Kodi target Makefile only adds FFmpeg to `DEPENDS` for `OS=linux`. PS4 uses `OS=freebsd`, so the build script's explicit `ffmpeg` target alone was a no-op. The PS4 overlay now adds `dav1d ffmpeg` to `DEPENDS` when `TARGET_PLATFORM=ps4`, preserving other platforms unchanged. The overlay performs a dry-run patch check before applying it.\n