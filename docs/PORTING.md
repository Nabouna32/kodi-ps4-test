# Kodi PS4 Port — Continuity Index

This file is intentionally small. The project previously kept architecture, build notes, decisions, research and current status in one large document. That made the source of truth harder to navigate.

The documentation is now split by responsibility.

## Start here

- [STATUS.md](STATUS.md) — current validated state, blockers and next action.
- [DECISIONS.md](DECISIONS.md) — durable decisions and constraints.
- [BUILD.md](BUILD.md) — WSL/OpenOrbis/LLVM build knowledge and build-system state.
- [ARCHITECTURE.md](ARCHITECTURE.md) — platform, graphics and video architecture.
- [RESEARCH.md](RESEARCH.md) — investigations, experiments, evidence and open questions.
- [README.md](README.md) — documentation map and maintenance rules.

## Project goal

Port official Kodi to PS4 as a native homebrew application.

Official Kodi remains the upstream source. VivaLaVent/kodi-ps5 is a technical reference only. The project uses publicly available PS4/OpenOrbis technology and does not include proprietary Sony SDK artifacts.

## Current development order

1. Build and toolchain validation.
2. Standalone PS4 graphics validation.
3. Kodi GLES/EGL platform integration.
4. Input/audio/filesystem/network integration.
5. Video pipeline and hardware-decoder investigation.
6. Packaging and real PS4 validation.
7. Optimization and broader feature coverage.

## Continuity rule

Every meaningful discovery, decision, implementation result, test result, blocker, correction or changed next action must be recorded in the appropriate specialized document before the work phase is considered complete.

For historical continuity, the repository Git history remains authoritative for the exact evolution of these documents and implementations.


## Current build-system checkpoint

The official Kodi native TexturePacker mechanism and the PS5 host-tool implementation have been compared. The PS4 project keeps a focused native TexturePacker bootstrap that builds Kodi's own CMake source for WSL/Linux, because the full Kodi native-dependency orchestration is broader than the current need. The PS5 approach provides independent evidence for this host/target separation. The next checkpoint is executable configure-only validation after synchronizing WSL with `origin/main`.
## Current build-system checkpoint — host CMake

The native dependency investigation established that the official Kodi CMake bootstrap explicitly requests system CURL. The first direct bootstrap failed because WSL lacked the CURL development package. `libcurl4-openssl-dev` is now installed and verified through pkg-config.

This is a host-tool prerequisite, not a PS4 dependency. The next checkpoint is to rerun the unchanged CMake bootstrap and verify the generated native Makefile before proceeding to the remaining explicit native-tool targets.


## Current build-system checkpoint — CMake bootstrap resolved

The official Kodi native CMake bootstrap now succeeds after installing the required WSL host development package `libcurl4-openssl-dev`. The native `Makefile` is generated successfully. The next checkpoint is explicit native-tool dependency validation, followed by the target HarfBuzz path.


## Current toolchain checkpoint — OpenOrbis v0.5.4 / LLVM 18 experiment

The active target toolchain is OpenOrbis v0.5.4. The latest HarfBuzz failure is in the OpenOrbis C/C++ math-header interface (cmath expects global abs, while the inspected math.h region exposes fabs but not abs).

LLVM/Clang/LLD 18.1.8 is now installed alongside the previously validated LLVM/LLD 21.1.8 environment. No repository pin or code workaround has been introduced.

The next executable checkpoint is a single configure-only run with LLVM 18 selected explicitly through PATH. This experiment must establish whether the host compiler version explains the OpenOrbis header mismatch before any Kodi-side compatibility patch is considered.

## Current toolchain checkpoint — LLVM 18 experiment rejected as fix

The LLVM/Clang/LLD 18.1.8 configure-only experiment reproduced the exact same OpenOrbis cmath failure as LLVM 21:

    cmath:341: using ::abs
    math.h:295: fabs declared

The host LLVM major version is therefore not sufficient to explain the blocker. No repository pin or compatibility workaround was added.

The next checkpoint is a direct comparison of the OpenOrbis v0.5.4 libc++/math header integration and its expected upstream build environment.

## Current toolchain checkpoint — OpenOrbis C++ include-order root cause

The repeated cmath failure has been traced to the generated PS4 C++ include order.

The current overlay emits the SDK C include directory before the OpenOrbis libc++ directory. OpenOrbis' libc++ cmath relies on its own math.h wrapper, which uses #include_next and includes <stdlib.h> before cmath imports ::abs.

The immediate checkpoint is a minimal compile proving that reversing the C++ include order resolves the error. Only that narrow ordering change should then be applied to the repository.
