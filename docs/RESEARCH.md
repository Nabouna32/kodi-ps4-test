# Kodi PS4 Port — Research and Validation

This file records investigations and evidence. It deliberately distinguishes validated results from hypotheses.

## R-001 — Kodi GLES/Piglet compatibility

Status: open.

Kodi GLES requirements have not yet been fully compared with the PS4 Piglet GLES 2.0/extension surface.

Required audit: shader language/version, framebuffer objects, texture formats, NPOT textures, float/half-float support, sampler requirements, shader precision, extensions used by Kodi, YUV/video texture paths, GUI compositor and render-to-texture requirements.

## R-002 — PS4 graphics/presentation proof of concept

Status: harness exists; real PS4 runtime validation pending.

Target chain: OpenOrbis -> Piglet -> EGL 1.4 -> GLES 2.0 -> shaders -> textures/FBOs -> VideoOut.

The POC is intentionally independent from Kodi.

## R-003 — PS4 hardware video / libSceAvPlayer

Status: open.

Public PS4 homebrew evidence reports hardware H.264/H.265 playback through libSceAvPlayer and NV12 frames. This establishes ecosystem-level capability only.

Still unknown: module/initialization requirements, supported containers, decoded-frame access, pixel formats, frame ownership/lifetime, timestamps and seeking, buffering/synchronization, GPU-friendly surface access, and Kodi CVideoBufferPS4 compatibility.

## R-004 — Zero-copy feasibility

Status: open.

The project has not proven direct import of PS4 decoder surfaces into Piglet/GLES. If zero-copy is impossible, an explicit NV12/P010 conversion path must be measured before committing to an architecture.

## R-004.5 — Windows OpenOrbis FSELF smoke test

Status: validated.

Native Windows testing validated compilation, PS4-targeted ELF linkage and FSELF conversion. GP4/PKG generation and real hardware execution remain unvalidated.

## R-004.6 — OpenOrbis CMake toolchain

Status: validated.

The repository toolchain uses the OpenOrbis FreeBSD target triple, libc++ headers, OpenOrbis linker script, target libraries and PIE settings consistent with the validated smoke test.

## R-004.7 — Kodi overlay application

Status: validated concept.

The repository-owned PS4 overlay is applied to a generated Kodi source tree before configuration.

## R-004.8 / R-004.9 — Native prefix corrections

Status: validated.

Kodi native build tools require a dedicated absolute NATIVEPREFIX. The prefix is kept separate from the PS4 target installation prefix.

## R-004.10 / R-004.11 — WSL2 + LLVM 21

Status: validated.

WSL2/Linux with LLVM/LLD 21.1.8 can compile, link and FSELF-package a minimal PS4 executable. The LLVM 21 tool suite is exposed through the development environment without hard-coding the path into the repository toolchain.

## R-004.12 — Clean Kodi submodule staging

Status: validated.

The build materializes the pinned Kodi commit into build/ps4/kodi-source and applies the overlay there. The pinned references/kodi submodule remains clean.

## R-004.13 — PS5 host-tool reference

Status: validated as build-system evidence.

The online PS5 reference builds TexturePacker and JsonSchemaBuilder natively, then supplies them to the cross-configure through WITH_TEXTUREPACKER, WITH_JSONSCHEMABUILDER and NATIVEPREFIX. It also disables target-side TexturePacker packaging for PS5.

This confirms the host/target separation required for the PS4 build. It does not justify copying unrelated PS5 platform or packaging logic.


## R-004.14 — Native TexturePacker integration

**Status:** host prerequisites installed; build/configure validation pending.

The pinned Kodi `FindTexturePacker.cmake` was inspected at the exact pinned Kodi commit. It confirms that `WITH_TEXTUREPACKER` is a host executable/path used during cross-compilation, while FreeBSD normally enables `INTERNAL_TEXTUREPACKER_INSTALLABLE`. Therefore the PS4 build supplies a native TexturePacker and explicitly sets `INTERNAL_TEXTUREPACKER_INSTALLABLE=FALSE` rather than changing `HOST_CAN_EXECUTE_TARGET`.

The native tool is built from `tools/depends/native/TexturePacker/src` with `KODI_SOURCE_DIR` pointing at the materialized Kodi tree, `APP_NAME_LC=kodi`, POSIX/Linux architecture defines, and the WSL host compilers `/usr/bin/cc` and `/usr/bin/c++`. It installs into the existing native prefix.

The first synchronized configure-only validation reached native TexturePacker configuration but failed because `LZO2_LIBRARY` and `LZO2_INCLUDE_DIR` were missing. This was a host dependency issue, not a PS4 toolchain failure.

The following Ubuntu 26.04.1 host packages are now installed and verified:

    liblzo2-dev
    libpng-dev
    libgif-dev
    libjpeg-dev

No project-local replacement for these libraries was introduced. The next validation is to rerun the native host-tool build and continue through Kodi cross-configuration.
