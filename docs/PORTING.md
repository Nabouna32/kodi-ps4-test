# Kodi PS4 Port — Project Continuity

## 1. Project goal

Port the official Kodi source to PlayStation 4 as a native homebrew application, using the official Kodi repository as the source of truth for Kodi code and the PS5 port \`VivaLaVent/kodi-ps5\` as a technical reference.

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

\`\`\`
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
\`\`\`

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

OpenOrbis exposes PS4 controller functionality through the \`scePad*\` APIs. The PS5 input layer should therefore be useful as a structural reference, but the implementation must target the actual PS4 API definitions and behavior.

Expected mapping:

\`\`\`
Kodi input
   |
PS4 input adapter
   |
scePad*
   |
DualShock 4
\`\`\`

This area is currently considered relatively low risk.

### 5.5 Graphics

The PS5 port uses a modern OpenGL/EGL path.

For PS4, OpenOrbis and the PS4 homebrew ecosystem provide EGL/GLES support, including Piglet-based rendering paths. A first implementation should investigate **GLES/EGL/Piglet** before committing to a Vulkan-based renderer.

A newer PS4 Vulkan/RADV ecosystem also exists and must be considered during research, but Vulkan should not be introduced merely because it is newer. The first renderer should minimize unnecessary architectural divergence from Kodi and the PS5 reference.

### 5.6 Audio

The PS5 port has a platform-specific audio sink using Sony audio APIs. PS4 exposes corresponding \`sceAudioOut\` functionality.

Likely architecture:

\`\`\`
Kodi audio engine
   |
CAESinkPS4
   |
sceAudioOut
   |
PS4 audio output
\`\`\`

The exact buffer, timing, channel, passthrough, and latency behavior still needs to be audited.

### 5.7 Video decoding

This is currently considered one of the two principal technical unknowns.

The PS5 port contains a substantial hardware-video path around Sony's PS5 video decoder APIs and Kodi's video-buffer/renderer architecture.

PS4 projects demonstrate hardware-assisted H.264/H.265 playback capabilities, including use of Sony's higher-level \`libSceAvPlayer\` APIs. However, \`AvPlayer\` cannot yet be assumed to be a direct replacement for the lower-level decoder architecture Kodi expects.

The key research question is:

> Can PS4 expose hardware-decoded frames through an API and memory path suitable for Kodi's \`CDVDVideoCodec\` / \`CVideoBuffer\` architecture without forcing a high-level player abstraction into Kodi?

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

\`\`\`
PS4
 -> PKG / executable
 -> process starts
 -> Kodi initializes
 -> graphical output
\`\`\`

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

**Repository:** \`Nabouna32/kodi-ps4-test\`

**Default branch:** \`main\`

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

\`VivaLaVent/kodi-ps5\` is a technical reference for platform adaptation, not the authoritative source of Kodi.

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

No implementation should begin until this analysis is complete.

---

## 12. Detailed renderer / video audit — 2026-09-30

### 12.1 PS5 renderer architecture is more specific than initially assumed

The PS5 port does not merely add a generic EGL window system. Its rendering path is composed of:

- \`CWinSystemPS5\`
- \`CWinSystemPS5GLContext\`
- Kodi's \`CRenderSystemGL\`
- an EGL context backed by the PS5 OpenGL runtime
- PS5-specific video synchronization/pacing
- PS5-specific HDR/output handling

The PS5 implementation explicitly derives its GL context window system from Kodi's existing EGL/windowing abstractions while also implementing the PS5 platform window system.

This is important because it means the PS4 port should **reuse Kodi's GL/EGL renderer architecture wherever possible**, rather than creating a new renderer abstraction.

The PS5 upstream-comparison document also identifies several changes as platform-forced (display mode/VRR/HDR behavior) and others as extensions/fixes. These must not be copied blindly to PS4.

### 12.2 PS4 GLES/Piglet is a materially different renderer target

OpenOrbis documents PS4-specific EGL/GLES headers, and the PS4 ecosystem has working applications using EGL window surfaces with Sony's Piglet OpenGL ES implementation. Public runtime output from an OpenOrbis-based application reports EGL 1.4 and OpenGL ES 2.0 Piglet.

This changes the renderer assessment:

- **EGL integration:** still promising.
- **Kodi desktop OpenGL renderer:** not directly validated.
- **Kodi GLES renderer:** must be investigated as the primary compatibility target.
- **Shader compatibility:** a major issue because the PS4 Piglet path exposes an ES 2.0-era API/runtime surface, while modern Kodi code can assume substantially newer GL/GLES capabilities depending on renderer/platform configuration.

Therefore the question is no longer simply "can Kodi create an EGL context?" It is:

> Can the current Kodi GLES renderer, GUI shaders, texture formats, framebuffer paths, and video renderer operate correctly against the actual PS4 Piglet feature/extension set?

The answer requires a capability-by-capability audit before choosing the final renderer path.

### 12.3 VideoOut should be treated as the presentation layer

PS4 homebrew graphics stacks expose \`sceVideoOut\` functionality, and newer PS4 graphics projects demonstrate presentation through \`sceVideoOutRegisterBuffers\` / \`sceVideoOutSubmitFlip\`.

For this project, the expected separation should therefore be:

\`\`\`
Kodi render system
      |
PS4 EGL/GLES context
      |
Piglet / GPU
      |
PS4 framebuffer / VideoOut presentation
\`\`\`

The exact buffer allocation, registration, synchronization and swap/present path still requires a small standalone PS4 graphics proof-of-concept before it is embedded into Kodi.

### 12.4 PS5 hardware video integration reveals the required Kodi boundary

The PS5 port's video path is not a generic "play video with Sony API" integration. It implements Kodi-facing components including:

- \`CDVDVideoCodecPS5\`
- \`CVideoBufferPS5\`
- \`CRendererPS5\`
- a platform decoder wrapper
- a zero-copy path from decoder frames to GL textures

The PS5 port explicitly models decoded frames as Kodi \`CVideoBuffer\` objects and uses a renderer selected from those buffers.

This is the correct architectural boundary for PS4 as well:

\`\`\`
FFmpeg / demux
      |
Kodi CDVDVideoCodecPS4
      |
PS4 decoder API
      |
CVideoBufferPS4
      |
PS4-compatible renderer
      |
EGL/GLES
\`\`\`

The **Sony decoder API itself must remain behind the Kodi codec/buffer boundary**. A high-level player API should not replace Kodi's video pipeline.

### 12.5 New evidence for PS4 hardware decoding

A recent public OpenOrbis PS4 IPTV implementation reports hardware decoding through \`libSceAvPlayer\`, with H.264 and H.265 support, and describes decoded NV12 frames being consumed by its rendering path.

This is useful evidence that PS4 homebrew can access hardware-assisted H.264/H.265 playback through a Sony video API. It does **not** yet prove that \`libSceAvPlayer\` exposes the exact low-level frame lifecycle, timestamps, surfaces, synchronization and memory ownership needed by Kodi's \`CDVDVideoCodec\` + \`CVideoBuffer\` architecture.

Therefore:

- hardware H.264/H.265 availability is now **confirmed at ecosystem level**;
- direct suitability as Kodi's decoder backend remains **unconfirmed**;
- \`libSceAvPlayer\` should be investigated experimentally before considering a custom low-level decoder path.

### 12.6 Important correction to the initial renderer assumption

The initial audit treated GLES/EGL/Piglet as a likely straightforward renderer direction. The detailed audit shows that **EGL creation is not the main risk**.

The main graphics risk is **feature compatibility between Kodi's current GLES renderer and PS4 Piglet's actual GLES 2.0 + extension surface**.

This should be tested early, before investing in the rest of the Kodi platform layer.

---

## 13. Revised architecture

The current preferred architecture is now:

\`\`\`
Official Kodi
    |
    +-- upstream/common Kodi
    |
    +-- PS4 platform integration
          |
          +-- CWinSystemPS4
          +-- CWinSystemPS4GLContext / EGL
          +-- Kodi GLES renderer
          +-- PS4 VideoOut presentation
          +-- PS4 input (scePad)
          +-- PS4 audio (sceAudioOut)
          +-- PS4 storage/network adapters
          +-- optional PS4 hardware video codec
                |
                +-- libSceAvPlayer (first candidate to investigate)
                |
                +-- CVideoBufferPS4
                +-- PS4 video renderer integration
    |
    +-- PS4 build/toolchain/package layer
\`\`\`

The PS5 port remains the strongest structural reference for the window system, platform registration, video buffer design, renderer registration, zero-copy concepts, and packaging strategy.

Its PS5-specific graphics/video implementation must not be copied as-is.

---

## 14. Revised risk map

| Area | Previous | Revised | Reason |
|---|---|---|---|
| x86-64 / basic ABI | high confidence | high | unchanged |
| Kodi common code | high | high | unchanged |
| Build/overlay strategy | high | high | PS5 structure confirms approach |
| Input | medium-high | medium-high | PS4 API evidence |
| Audio | medium | medium | still needs sink audit |
| EGL context creation | medium | medium-high | PS4 ecosystem evidence |
| Kodi GLES compatibility | medium | **low-medium** | Piglet exposes ES 2.0-era surface |
| VideoOut presentation | medium | medium | viable, but buffer/sync path unverified |
| Vulkan renderer | medium | medium-high | modern PS4 Vulkan stacks exist, but not yet justified as first path |
| Hardware H.264/H.265 availability | low-medium | **medium-high** | public PS4 homebrew demonstrates libSceAvPlayer hardware playback |
| Kodi-compatible hardware decoder | low-medium | **medium** | ecosystem evidence exists, Kodi frame integration remains unverified |
| Zero-copy decoder → GL | low | **low-medium** | requires PS4-specific buffer/export/import mechanism |
| Packaging | medium-high | medium-high | OpenOrbis provides packaging tooling |

### Current critical risks

1. **Kodi GLES renderer vs PS4 Piglet compatibility.**
2. **Kodi-compatible ownership/lifetime of hardware-decoded PS4 frames.**
3. **Zero-copy or efficient transfer of decoded NV12/P010 frames into the Kodi renderer.**

---

## 15. Next concrete research tasks

### R-001 — Kodi GLES capability audit

Compare the current Kodi GLES renderer requirements against the PS4 Piglet feature/extension surface.

Check at minimum:

- shader language/version
- framebuffer objects
- texture formats
- NPOT textures
- integer/float texture support
- sampler requirements
- shader precision
- vertex/fragment shader features
- extensions used by Kodi
- YUV/video texture paths
- GUI compositor requirements
- render-to-texture paths

**Goal:** determine whether Kodi's existing GLES renderer can be made to work with Piglet with configuration/patches only, or whether a PS4-specific renderer adaptation is required.

### R-002 — PS4 presentation proof of concept

Build a tiny OpenOrbis application that:

1. initializes EGL;
2. creates a GLES context;
3. renders a textured frame;
4. presents it through the PS4 output path;
5. verifies stable frame pacing.

This should happen before modifying Kodi's renderer.

### R-003 — libSceAvPlayer investigation

Determine:

- initialization/module requirements;
- supported containers/codecs;
- access to decoded frames;
- pixel formats;
- frame lifetime/ownership;
- timestamps;
- seeking;
- buffering;
- synchronization;
- whether decoded frames can remain GPU-friendly;
- whether a Kodi \`CVideoBufferPS4\` can wrap them safely.

### R-004 — zero-copy feasibility

Investigate whether PS4 decoder surfaces can be imported into the GLES/Piglet renderer without a full CPU copy.

If zero-copy is impossible, design the fallback around an explicit NV12/P010 → GPU/CPU conversion path and measure its cost before committing to it.

---

## 16. Updated conclusion

The project remains technically plausible, but the detailed audit changes the order of attack.

**Do not start by copying the PS5 renderer or decoder.**

The first implementation milestone should instead be a **standalone PS4 graphics proof of concept plus a Kodi GLES capability audit**.

If that succeeds, the Kodi window-system/platform layer becomes the next implementation target.

In parallel, \`libSceAvPlayer\` should be investigated as the first PS4 hardware-video candidate, while preserving Kodi's existing codec/buffer architecture.

The PS5 port has now been validated as a **strong architectural reference**, but not as a codebase to transplant wholesale.

---

## 17. Vulkan investigation — 2026-09-30

The Vulkan question must remain open rather than being dismissed in favor of GLES.

### 17.1 New evidence: an actual PS4 Vulkan stack exists

The current project research contains evidence for a public PS4 Vulkan/RADV ecosystem. Vulkan therefore remains a viable later renderer direction, but the first implementation target remains GLES/EGL/Piglet until its compatibility is measured against Kodi.

### 17.2 Shader pipeline distinction

Piglet's precompiled shader path must not be conflated with GNM/Vulkan shader binaries. Projects with similar \`psbc\` names can target different runtime formats.

### 17.3 ioQuake3 shader provenance

ioQuake3-PS4 credits \`psbc\` at https://gitgud.io/veiledmerc/psbc for shader compilation. Its renderer uses GLSL ES 1.00 and loads generated shader binaries through \`glShaderBinary()\`.

The exact compiler revision, invocation, license and compatibility with arbitrary Kodi shaders remain to be validated.

---

## 18. R-002A — standalone GLES/Piglet + VideoOut POC design — 2026-09-30

R-002A is a standalone graphics proof-of-concept, independent from Kodi. Its purpose is to establish the minimum PS4 graphics/presentation chain required by the future Kodi port:

\`OpenOrbis -> Piglet -> EGL 1.4 -> GLES 2.0 -> precompiled Piglet shaders -> textures/FBOs -> presentation\`.

The POC probes:

- GL/EGL identification and extensions;
- NPOT texture upload;
- RGBA8 framebuffer completeness;
- float-texture support;
- half-float-related capabilities;
- the existing precompiled Piglet shader/render/presentation path.

Runtime GLSL compilation is intentionally not required.

**Status:** source/build harness added; target-PS4 runtime validation remains pending.

---

## 19. R-004.5 — Native Windows OpenOrbis FSELF packaging smoke test — 2026-09-30

The native Windows OpenOrbis smoke test was validated through Clang compilation, PS4-targeted ELF linkage and FSELF conversion.

Validated artifacts:

| Artifact | Size |
|---|---:|
| \`hello_world.oelf\` | 1,825,272 bytes |
| \`eboot.bin\` | 1,211,280 bytes |

Remaining packaging validation includes GP4/PKG generation and execution on real PS4 hardware.

---

## 20. R-004.6 — OpenOrbis CMake toolchain aligned with validated Windows smoke test — 2026-09-30

The repository's PS4 CMake toolchain uses the validated OpenOrbis Windows conventions:

- \`x86_64-pc-freebsd12-elf\`;
- \`-fPIC\` and \`-funwind-tables\`;
- OpenOrbis libc++ include directory;
- \`-nostdlib\`, \`-pie\`, \`link.x\`, OpenOrbis library directory;
- explicit \`-lc -lkernel\` / \`-lc -lkernel -lc++\`.

Configure validation has now reached Kodi's native dependency setup.

---

## 21. R-004.7 — Kodi overlay application before CMake configuration — 2026-09-30

The first Kodi CMake configure initially failed because the pinned official Kodi checkout did not contain the PS4 platform overlay.

The project now applies these repository-owned directories into \`references/kodi\` before configuration:

- \`cmake/platform/ps4\`
- \`cmake/scripts/ps4\`
- \`overlay/xbmc/platform/ps4\`

The operation is implemented by \`scripts/apply-kodi-overlay.cmake\`, and \`scripts/build-ps4-kodi.sh\` invokes it before CMake configuration.

The overlay application was successfully executed on the Windows development checkout.

---

## 22. R-004.8 — Native Kodi dependency prefix — 2026-09-30

### Observation

After the overlay was applied, Kodi successfully reached its native dependency setup. Meson and Ninja were found, and Kodi downloaded \`pkgconf-2.5.1\`.

The native Meson configuration then failed with:

\`\`\`
meson.build(1): error ...: prefix value '' must be an absolute path
\`\`\`

The failing dependency is a **host/native build tool**, not a PS4 target library.

### Root cause

Kodi distinguishes its target installation prefix from the prefix used for native build tools. The PS4 platform overlay previously defined the target-side \`CMAKE_INSTALL_PREFIX=/app0\`, but did not define Kodi's \`NATIVEPREFIX\`.

As a result, the native pkgconf build received an empty prefix.

### Decision

Define \`NATIVEPREFIX\` in the PS4 platform configuration as a dedicated directory below the CMake build tree:

\`\`\`
build/ps4/build/native
\`\`\`

This deliberately keeps:

- native Windows build tools;
- PS4 target installation/image paths

in separate namespaces.

The fix is implemented in \`cmake/platform/ps4/ps4.cmake\`.

### Rationale

Do not reuse \`CMAKE_INSTALL_PREFIX\` for native tools. \`/app0\` represents the PS4 application image, while \`pkgconf.exe\` and similar helpers execute on Windows during the build.

### Validation status

The fix has been committed directly to \`main\` as:

\`6562c8770270d84065cbaa65e27ae2d83989192d\`

The local Windows configure must now be rerun from a clean \`build/ps4\` directory to validate the fix and expose the next root cause, if any.

### Next action

Pull \`main\`, verify the changed PS4 platform file, remove \`build/ps4\`, reapply the overlay, and rerun configure-only CMake. Do not start the full Kodi build until configure completes successfully.


---

## 23. R-004.9 — Native prefix expansion correction — 2026-09-30

### Observation

The first rerun after R-004.8 no longer failed because Meson received an empty prefix. Instead, Kodi's nested pkgconf CMake project attempted to create:

`build/ps4/build/pkgconf/C:/dev/projects/kodi-ps4-test/build/ps4/build/pkgconf/build/native`

This shows that `NATIVEPREFIX` was still being treated as a malformed relative path by the nested ExternalProject configuration.

### Root cause

The PS4 platform file used an escaped CMake variable reference:

`"${CMAKE_BINARY_DIR}/build/native"`

The escape prevented the parent Kodi CMake configuration from expanding `CMAKE_BINARY_DIR` when defining `NATIVEPREFIX`. The nested pkgconf project consequently received an invalid prefix value and ExternalProject combined it with its own working prefix.

### Correction

`NATIVEPREFIX` is now defined with normal CMake variable expansion:

`"${CMAKE_BINARY_DIR}/build/native"`

The target-side prefix remains separate from this native build-tools prefix.

### Validation status

The correction was committed directly to `main` as:

`4d7bbf738880659ceb59a3e3b08640848dc81085`

The next validation is configure-only from a clean `build/ps4` directory. No full Kodi build should be started until configuration succeeds.
