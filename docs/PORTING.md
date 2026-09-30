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
