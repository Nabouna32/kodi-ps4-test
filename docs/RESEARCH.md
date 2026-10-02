# Kodi PS4 Port — Research and Validation

This document stores durable conclusions. Superseded command transcripts and chronological handoff text belong in Git history.

## R-001 — Graphics direction

GLES/EGL/Piglet is the first renderer path to validate. Vulkan/OpenGNM is a later path.

A standalone PS4 graphics/presentation proof of concept is required before deep Kodi renderer integration. Piglet compatibility with Kodi's exact GLES requirements is not runtime-validated.

## R-002 — Hardware video

A PS4 decoder must integrate through Kodi's codec/video-buffer boundaries. A high-level player abstraction must not replace that architecture.

libSceAvPlayer is a candidate to investigate, but Kodi-compatible frame ownership, synchronization and zero-copy behavior are not established.

## R-003 — Host tools versus target dependencies

TexturePacker, JsonSchemaBuilder and similar build-time generators execute on WSL/Linux and belong in the native prefix. PS4 libraries belong in the OpenOrbis/FreeBSD target prefix.

PS5 evidence supports this host/target separation but does not justify reusing PS5 binaries.

## R-004 — Minimal bring-up dependency policy

Blu-ray/libbluray and XSLT/libxslt are optional at the pinned Kodi revision and are not required for the initial GUI/GLES/controller milestone.

Decision: exclude those paths during bring-up instead of adding unrelated dependencies solely to satisfy optional features. This is not a permanent feature-removal decision.

## R-005 — HarfBuzz target dependency

HarfBuzz is required by the pinned ASS/libass path. The official Kodi target recipe builds it for PS4 and uses `freetype2-noharfbuzz` to break the FreeType/HarfBuzz bootstrap cycle.

Ubuntu `libharfbuzz-dev` cannot satisfy this target requirement.

## R-006 — Native CMake and system CURL

Kodi's native CMake recipe requests system CURL. The WSL failure was caused by missing `libcurl4-openssl-dev`.

Installing the normal host package resolved the bootstrap. This was a host-tool dependency, not an OpenOrbis target issue.

## R-007 — LLVM 18 experiment

LLVM/Clang/LLD 18.1.8 was tested against the OpenOrbis v0.5.4 `cmath`/global-`abs` failure reproduced with LLVM 21.

LLVM 18 reproduced the same failure.

Conclusion: compiler major version is not the sufficient fix; no repository LLVM pin was adopted.

## R-008 — OpenOrbis C++ header ordering

OpenOrbis libc++ relies on its own `math.h` wrapper being found before the raw SDK C header.

The standalone target test showed that:

```
include/c++/v1
include
```

resolves the `cmath` global-`abs` issue while the reverse order does not.

Decision: preserve this order in repository-owned PS4 C++ integrations. Do not patch HarfBuzz or copy OpenOrbis headers.

## R-009 — Target pkg-config routing

Kodi target metadata is installed in both `lib/pkgconfig` and `libdata/pkgconfig`.

Decision: set `PKG_CONFIG_LIBDIR` to only those target-prefix locations during PS4 configuration so host Linux metadata cannot satisfy target dependencies.

## R-010 — FriBidi target dependency

After HarfBuzz discovery was corrected, required ASS/libass configuration exposed FriBidi as the next target dependency.

Implementation: stage the official Kodi `fribidi` recipe rather than patching Kodi's finder or using a host package.

## R-011 — Iconv detection

Kodi Autoconf reports iconv as built into target libc, and a direct OpenOrbis target test successfully compiles/links `iconv_open`, `iconv`, and `iconv_close`.

CMake 4.2 failed its implicit Iconv test until the OpenOrbis SDK C include directory was supplied.

Conclusion: this was CMake/OpenOrbis C-header visibility, not evidence of missing libiconv.

Implementation: `CMAKE_C_FLAGS_INIT` exposes `$OO_PS4_TOOLCHAIN/include`. No host `libiconv-dev`, target libiconv, finder override or PS5 Iconv patch was added.

Whether the target libc is semantically sufficient for every Kodi legacy encoding is a separate, unvalidated question.

## R-012 — Fontconfig target dependency

The required ASS/libass path next exposed Fontconfig as a target dependency.

Implementation: stage the official Kodi `fontconfig` recipe alongside `fribidi` and `harfbuzz`.

Fresh WSL validation remains pending.

## R-013 — zlib target testing

The pinned Kodi zlib recipe attempted an optional coverage/test executable that is not required by the initial target library and is incompatible with the current OpenOrbis profiling/runtime environment.

Implementation: retain the official recipe in the repository-owned overlay and add only `-DZLIB_BUILD_TESTING=OFF`.

The target zlib library remains enabled. Fresh WSL validation remains pending.

## R-014 — Public-platform boundaries

Validated boundaries:

- target triple: `x86_64-pc-freebsd12-elf`;
- OpenOrbis `link.x` controls target executable layout;
- target libraries are supplied explicitly;
- host programs execute on WSL/Linux;
- PS5 target libraries/binaries are not reused;
- proprietary Sony SDK artifacts are not accepted.

## Open questions

1. Kodi GLES compatibility with actual PS4 Piglet/EGL behavior.
2. Minimal PS4 input integration through `scePad`.
3. PS4 audio integration through `sceAudioOut`.
4. Kodi-compatible decoder/frame ownership and zero-copy behavior.
5. Self-hosted OpenOrbis CI design.

These are future investigations, not current build blockers.
