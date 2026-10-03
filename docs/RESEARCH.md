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

## R-015 — ps4dev/ps4sdk as historical PS4 reference

The public `ps4dev/ps4sdk` repository is pinned under `references/ps4sdk/` at `4df9d001b66ae4ec07d9a51b62d1e4c5e270eecc` (last `master` commit, 2017). It is a historical/open-source PS4 SDK reference, not a replacement for OpenOrbis and not a source of proprietary Sony SDK artifacts.

It is relevant to the current OpenSSL blocker because its public headers include FreeBSD-derived compatibility interfaces missing from OpenOrbis v0.5.4, including `sys/sysctl.h`, and define `KERN_ARND`. This gives us concrete historical PS4/FreeBSD evidence for the API shape selected by OpenSSL's FreeBSD random-seeding path. It does not prove that the same interface is available or linkable in the current OpenOrbis userland.

Decision for this step: keep the repository immutable and use it only for source comparison. No PS4SDK headers, libraries, binaries, or code are copied into the build.

Source: https://github.com/ps4dev/ps4sdk/commit/4df9d001b66ae4ec07d9a51b62d1e4c5e270eecc
Confidence: high for the contents of that public revision; low for current runtime/API availability on modern PS4/OpenOrbis.

## R-016 — OpenSSL FreeBSD random path versus PS4 APIs

OpenSSL 3.5.7's failure at `providers/implementations/rands/seeding/rand_unix.c` was a FreeBSD compatibility-path mismatch, not evidence that `sysctl(KERN_ARND)` is the correct PS4 implementation. OpenSSL's source includes both the older FreeBSD `sysctl(KERN_ARND)` path and a `getrandom()` path for sufficiently recent FreeBSD versions. citeturn5view0

Current OpenOrbis v0.5.4 evidence changed the decision: the installed toolchain contains `include/sys/random.h` declaring `getrandom(void *, size_t, unsigned)`, and a minimal executable linked with the same OpenOrbis PS4 model used by Kodi resolves `getrandom` as a defined target symbol. This establishes a usable OpenOrbis entropy primitive without copying `sys/sysctl.h` from the historical PS4SDK.

Implementation:
- add an OpenSSL `kodi-ps4` target inheriting the existing `BSD-x86_64` target shape;
- define `KODI_PS4` only for that target;
- include `<sys/random.h>` for PS4;
- bypass the FreeBSD `sysctl(KERN_ARND)` backend on PS4;
- call `getrandom(buf, buflen, 0)` as the PS4 entropy source.

No OpenOrbis SDK files are modified and no historical PS4SDK compatibility header is copied.

Validation level: source-level verification plus a successful OpenOrbis target-link smoke test for `getrandom`; the full OpenSSL dependency build remains pending.

Confidence: high for the OpenOrbis header/symbol evidence and the narrow source adaptation; pending full dependency-build validation.


## R-017 — Pinned Kodi FFmpeg dependency

The pinned Kodi revision `9c3e7f4d7b3ff314cd2f19a291766555e0346024` uses FFmpeg `9.0.2` in `tools/depends/target/ffmpeg/FFMPEG-VERSION`. Its target recipe invokes the pinned FFmpeg CMake wrapper, passes the cross compiler/linker/archive tools and target pkg-config, and applies Kodi's three maintained FFmpeg source patches.

The top-level `FindFFMPEG.cmake` requires the exact 9.0.2 library ABI versions when using the Kodi depends-build path. The previous PS4 configure failure occurred because the target dependency prefix contained no FFmpeg libraries, not because FFmpeg 9.0.2 had yet been shown incompatible with PS4.

Decision for this step: stage FFmpeg through the official Kodi target dependency graph before Kodi CMake configuration. Do not force `ENABLE_INTERNAL_FFMPEG=ON` at the top level and do not adapt FFmpeg source until an actual OpenOrbis build failure establishes the need.

Validation level: source inspection of the exact pinned Kodi revision plus implementation in the repository build script. Fresh WSL FFmpeg compilation/configuration remains pending.

Confidence: high for the dependency-path diagnosis; pending target-build validation.
\n\n## R-018 — FFmpeg target was not being built on PS4

The first validation after adding `ffmpeg` to the build script still reached Kodi `FindFFMPEG.cmake` with no FFmpeg libraries. Exact inspection of the pinned Kodi `tools/depends/target/Makefile` showed that `DEPENDS += dav1d ffmpeg` is conditional on `OS=linux`. The PS4 depends configuration deliberately reports `platform_os=freebsd`, so the explicit `make ffmpeg` invocation did not pull the FFmpeg directory into the real dependency graph.

Implementation: add `dav1d ffmpeg` to `DEPENDS` only for `TARGET_PLATFORM=ps4` through `overlay/tools/depends/0003-openorbis-ps4-ffmpeg-depends.patch`, with a dry-run check in `scripts/apply-kodi-overlay.cmake`.

This is a dependency-graph correction, not an FFmpeg source adaptation. No FFmpeg/OpenOrbis compatibility issue has yet been observed.

Validation status: patch implemented; fresh WSL configure-only validation pending.\n

## R-019 — Corrected FFmpeg dependency overlay hunk

The first PS4 FFmpeg dependency overlay used an invalid unified-diff hunk header: `@@ -90,6 +90,10 @@` declared six old lines although the hunk contains four. `patch --dry-run` therefore rejected the overlay before any FFmpeg build occurred.

The exact pinned Kodi Makefile context is unchanged; only the patch metadata was wrong. The overlay was corrected to `@@ -90,4 +90,8 @@` in commit `9f26094668334004873f0f254e1119d7bfc2b2dd`.

Validation level: source-level exactness verified against the pinned Kodi Makefile; fresh WSL configure-only execution remains required.
