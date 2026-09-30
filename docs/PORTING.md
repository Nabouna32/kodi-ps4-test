# Kodi PS4 Port — Project Continuity

## 1. Project goal

Port the official Kodi source to PlayStation 4 as a native homebrew application, using the official Kodi repository as the source of truth for Kodi code and the PS5 port `VivaLaVent/kodi-ps5` as a technical reference.

The target environment is a PS4 running a compatible exploitable firmware with GoldHEN. The intended development stack is based primarily on OpenOrbis and publicly available PS4 research.

This repository is the long-term memory of the project. Important discoveries, decisions, implementation results, test results, blockers, and next actions must be recorded here so the project can resume accurately in a future conversation.

---

## 2. Source-of-truth hierarchy

1. **Git repository state** — source of truth for what is actually implemented.
2. **Official Kodi source** — source of truth for upstream Kodi behavior and APIs.
3. **Project documentation in this repository** — source of truth for validated project decisions, architecture, discoveries, and current status.
4. **PS5 port** — reference implementation and research material, not the project's source code of truth.
5. **External research** — evidence to be evaluated and recorded with its source and confidence.

No implementation should silently redefine the product or architecture.

---

## 3. Reference repositories

- Official Kodi: https://github.com/xbmc/xbmc
- PS5 port: https://github.com/VivaLaVent/kodi-ps5
- OpenOrbis PS4 toolchain: https://github.com/OpenOrbis/OpenOrbis-PS4-Toolchain

The PS5 repository is particularly valuable because it separates platform-specific changes from upstream Kodi through patches, an overlay, shims, toolchain components, and packaging.

---

## 4. Current architecture hypothesis

The preferred architecture is **not** to fork the PS5 port wholesale.

Instead:

```
Official Kodi
    |
    +-- upstream/common Kodi
    |
    +-- PS4 patches
    |
    +-- overlay
          |
          +-- xbmc/platform/ps4
          |
          +-- CMake/toolchain integration
          +-- PS4-specific APIs
          +-- rendering
          +-- audio
          +-- input
          +-- video
          +-- storage/network integration
```

The PS5 port should be mined for reusable ideas and platform abstractions, while PS4-specific code should be developed against the actual PS4/OpenOrbis APIs.

---

## 5. Initial audit findings

### 5.1 CPU / ABI

PS4 and PS5 are both x86-64 platforms. This makes the port substantially more favorable than a port to a fundamentally different CPU architecture.

### 5.2 Kodi portability

Kodi already separates substantial amounts of platform-dependent functionality from its common core. The PS5 port demonstrates that Kodi can be adapted by adding platform-specific layers rather than rewriting the whole application.

### 5.3 PS5 port architecture

The PS5 project contains platform-specific patches, an overlay, shims, toolchain/build material, and packaging. Its platform code covers areas including:

- windowing/rendering
- input
- audio
- video
- storage/filesystem
- networking
- Sony platform bindings
- application entry point

This architecture is a strong candidate for the PS4 port.

### 5.4 PS4 input

OpenOrbis exposes PS4 controller functionality through the `scePad*` APIs. The PS5 input layer should therefore be useful as a structural reference, but the implementation must target the actual PS4 API definitions and behavior.

Expected mapping:

```
Kodi input
   |
PS4 input adapter
   |
scePad*
   |
DualShock 4
```

This area is currently considered relatively low risk.

### 5.5 Graphics

The PS5 port uses a modern OpenGL/EGL path.

For PS4, OpenOrbis and the PS4 homebrew ecosystem provide EGL/GLES support, including Piglet-based rendering paths. A first implementation should investigate **GLES/EGL/Piglet** before committing to a Vulkan-based renderer.

A newer PS4 Vulkan/RADV ecosystem also exists and must be considered during research, but Vulkan should not be introduced merely because it is newer. The first renderer should minimize unnecessary architectural divergence from Kodi and the PS5 reference.

### 5.6 Audio

The PS5 port has a platform-specific audio sink using Sony audio APIs. PS4 exposes corresponding `sceAudioOut` functionality.

Likely architecture:

```
Kodi audio engine
   |
CAESinkPS4
   |
sceAudioOut
   |
PS4 audio output
```

The exact buffer, timing, channel, passthrough, and latency behavior still needs to be audited.

### 5.7 Video decoding

This is currently considered one of the two principal technical unknowns.

The PS5 port contains a substantial hardware-video path around Sony's PS5 video decoder APIs and Kodi's video-buffer/renderer architecture.

PS4 projects demonstrate hardware-assisted H.264/H.265 playback capabilities, including use of Sony's higher-level `libSceAvPlayer` APIs. However, `AvPlayer` cannot yet be assumed to be a direct replacement for the lower-level decoder architecture Kodi expects.

The key research question is:

> Can PS4 expose hardware-decoded frames through an API and memory path suitable for Kodi's `CDVDVideoCodec` / `CVideoBuffer` architecture without forcing a high-level player abstraction into Kodi?

Do not implement the PS4 video decoder until this question is sufficiently answered.

---

## 6. Current risk map

| Area | Current assessment | Confidence |
|---|---|---|
| x86-64 / basic ABI | favorable | high |
| Kodi common code | largely reusable | high |
| Build/overlay strategy | reusable concept | high |
| Input | likely straightforward | medium-high |
| Audio | likely manageable | medium |
| Filesystem/network | likely manageable, needs audit | medium |
| EGL/GLES | viable research direction | medium |
| Piglet renderer | promising but must be validated against Kodi | medium |
| Vulkan renderer | technically possible, not first target | medium |
| Hardware video decoding | major unknown | low-medium |
| PS4-specific packaging | feasible, needs implementation | medium-high |

The two main technical risks currently are:

1. **Kodi rendering through the PS4 GLES/EGL/Piglet stack.**
2. **A Kodi-compatible PS4 hardware video decoding path.**

---

## 7. Development strategy

The project should progress incrementally.

### Phase A — research / architecture

- audit current Kodi renderer architecture
- audit PS5 renderer implementation
- audit PS4 GLES/EGL/Piglet
- audit PS4 VideoOut
- audit PS4 hardware video APIs
- identify reusable PS5 patches
- identify PS4-specific replacements

No broad code copy should occur before this phase produces a sufficiently concrete architecture.

### Phase B — minimal PS4 application

First functional target:

```
PS4
 -> PKG / executable
 -> process starts
 -> Kodi initializes
 -> graphical output
```

Do not initially target every Kodi feature.

### Phase C — platform integration

Progressively integrate:

1. rendering
2. controller input
3. filesystem/storage
4. networking
5. audio
6. software video
7. hardware video
8. advanced display/video features

Each phase must be build-tested and, where possible, tested on real PS4 hardware.

---

## 8. Documentation rules

This documentation must be updated after meaningful discoveries or validated decisions.

Each important discovery should record:

- question/problem
- evidence/source
- observation
- conclusion
- confidence
- impact on architecture
- next action

Do not promote an unverified hypothesis into a project fact.

When a future conversation begins, the assistant should first inspect Git and these documents before relying on old chat context.

---

## 9. Current status

**Repository:** `Nabouna32/kodi-ps4-test`

**Default branch:** `main`

**Implementation:** not started.

**Documentation:** initial project continuity document created.

**Current phase:** Phase A — research / architecture.

**Next planned investigation:** detailed comparison of the current Kodi renderer/windowing architecture, the PS5 renderer, and the PS4 GLES/EGL/Piglet + VideoOut stack, followed by a dedicated investigation of PS4 hardware video decoding.

---

## 10. Important decisions so far

### D-001 — Official Kodi remains the base

The PS4 port will be based on official Kodi rather than treating the PS5 fork as the new upstream.

**Reason:** preserve upstream maintainability and isolate PS4-specific changes.

### D-002 — PS5 port is a reference

`VivaLaVent/kodi-ps5` is a technical reference for platform adaptation, not the authoritative source of Kodi.

### D-003 — Prefer a platform layer

PS4-specific functionality should be isolated in a PS4 platform layer and supporting patches/overlays where practical.

### D-004 — Do not commit to Vulkan yet

GLES/EGL/Piglet is the first graphics path to investigate because it may require less divergence from Kodi and the existing PS5 architecture.

### D-005 — Do not implement hardware video prematurely

The PS4 video decoder integration needs architectural investigation before code is copied or written.

---

## 11. Next action

**Step 1 continuation:** perform the detailed renderer and video architecture audit.

Expected output:

- exact Kodi renderer components involved
- exact PS5 files/components involved
- PS4 equivalents
- reusable vs PS5-specific code
- missing APIs
- recommended PS4 architecture
- concrete implementation order
- updated risk assessment

No implementation should begin until this analysis is complete and the resulting architecture is validated.
