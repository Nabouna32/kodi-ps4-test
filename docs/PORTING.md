# Kodi PS4 Port — Continuity Index

This file is an index, not a second status log.

## Start here

- [AGENTS.md](../AGENTS.md) — mandatory repository rules.
- [WORKFLOW.md](WORKFLOW.md) — mandatory operational procedure.
- [CONTINUITY.md](CONTINUITY.md) — cross-conversation handoff.
- [STATUS.md](STATUS.md) — current state and next action.
- [BUILD.md](BUILD.md) — build/toolchain knowledge.
- [DECISIONS.md](DECISIONS.md) — durable decisions.
- [ARCHITECTURE.md](ARCHITECTURE.md) — architecture and boundaries.
- [RESEARCH.md](RESEARCH.md) — evidence and investigations.
- [WSL-HOST-DEPENDENCIES.md](WSL-HOST-DEPENDENCIES.md) — host package inventory.

## Project goal

Port official Kodi to PS4 as a native homebrew application using public OpenOrbis-compatible technology.

## Development order

1. Toolchain/build validation.
2. Standalone graphics validation.
3. Kodi GLES/EGL integration.
4. Input/audio/filesystem/network integration.
5. Video pipeline and decoder investigation.
6. Packaging and actual PS4 validation.
7. Optimization and broader feature coverage.

## Maintenance rule

Git history contains chronology; documentation contains durable knowledge.

- Current state belongs in STATUS.
- Handoff belongs in CONTINUITY.
- Build knowledge belongs in BUILD.
- Decisions belong in DECISIONS.
- Evidence belongs in RESEARCH.
- Architecture belongs in ARCHITECTURE.
- Do not duplicate complete sections between documents.
- Remove obsolete chronology when a newer validated state replaces it.
