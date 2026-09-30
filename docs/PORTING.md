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


---

## 12. Detailed renderer / video audit — 2026-09-30

### 12.1 PS5 renderer architecture is more specific than initially assumed

The PS5 port does not merely add a generic EGL window system. Its rendering path is composed of:

- `CWinSystemPS5`
- `CWinSystemPS5GLContext`
- Kodi's `CRenderSystemGL`
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

PS4 homebrew graphics stacks expose `sceVideoOut` functionality, and newer PS4 graphics projects demonstrate presentation through `sceVideoOutRegisterBuffers` / `sceVideoOutSubmitFlip`.

For this project, the expected separation should therefore be:

```
Kodi render system
      |
PS4 EGL/GLES context
      |
Piglet / GPU
      |
PS4 framebuffer / VideoOut presentation
```

The exact buffer allocation, registration, synchronization and swap/present path still requires a small standalone PS4 graphics proof-of-concept before it is embedded into Kodi.

### 12.4 PS5 hardware video integration reveals the required Kodi boundary

The PS5 port's video path is not a generic "play video with Sony API" integration. It implements Kodi-facing components including:

- `CDVDVideoCodecPS5`
- `CVideoBufferPS5`
- `CRendererPS5`
- a platform decoder wrapper
- a zero-copy path from decoder frames to GL textures

The PS5 port explicitly models decoded frames as Kodi `CVideoBuffer` objects and uses a renderer selected from those buffers.

This is the correct architectural boundary for PS4 as well:

```
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
```

The **Sony decoder API itself must remain behind the Kodi codec/buffer boundary**. A high-level player API should not replace Kodi's video pipeline.

### 12.5 New evidence for PS4 hardware decoding

A recent public OpenOrbis PS4 IPTV implementation reports hardware decoding through `libSceAvPlayer`, with H.264 and H.265 support, and describes decoded NV12 frames being consumed by its rendering path.

This is useful evidence that PS4 homebrew can access hardware-assisted H.264/H.265 playback through a Sony video API. It does **not** yet prove that `libSceAvPlayer` exposes the exact low-level frame lifecycle, timestamps, surfaces, synchronization and memory ownership needed by Kodi's `CDVDVideoCodec` + `CVideoBuffer` architecture.

Therefore:

- hardware H.264/H.265 availability is now **confirmed at ecosystem level**;
- direct suitability as Kodi's decoder backend remains **unconfirmed**;
- `libSceAvPlayer` should be investigated experimentally before considering a custom low-level decoder path.

### 12.6 Important correction to the initial renderer assumption

The initial audit treated GLES/EGL/Piglet as a likely straightforward renderer direction. The detailed audit shows that **EGL creation is not the main risk**.

The main graphics risk is **feature compatibility between Kodi's current GLES renderer and PS4 Piglet's actual GLES 2.0 + extension surface**.

This should be tested early, before investing in the rest of the Kodi platform layer.

---

## 13. Revised architecture

The current preferred architecture is now:

```
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
```

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
- whether a Kodi `CVideoBufferPS4` can wrap them safely.

### R-004 — zero-copy feasibility

Investigate whether PS4 decoder surfaces can be imported into the GLES/Piglet renderer without a full CPU copy.

If zero-copy is impossible, design the fallback around an explicit NV12/P010 → GPU/CPU conversion path and measure its cost before committing to it.

---

## 16. Updated conclusion

The project remains technically plausible, but the detailed audit changes the order of attack.

**Do not start by copying the PS5 renderer or decoder.**

The first implementation milestone should instead be a **standalone PS4 graphics proof of concept plus a Kodi GLES capability audit**.

If that succeeds, the Kodi window-system/platform layer becomes the next implementation target.

In parallel, `libSceAvPlayer` should be investigated as the first PS4 hardware-video candidate, while preserving Kodi's existing codec/buffer architecture.

The PS5 port has now been validated as a **strong architectural reference**, but not as a codebase to transplant wholesale.


---

## 17. Vulkan investigation — 2026-09-30

The Vulkan question must remain open rather than being dismissed in favor of GLES.

### 17.1 New evidence: an actual PS4 Vulkan stack exists

The current PS4 homebrew ecosystem contains the **PS4-OpenGNM** graphics stack. Its published architecture describes:

- `opengnm`: a GNM/GPA compatibility layer;
- `opengnm-psbc`: SPIR-V → PS4 shader-binary compilation using Mesa NIR/ACO;
- `vulkan-ps4`: a Vulkan 1.0 ICD targeting PS4;
- example applications such as triangle/cube/glTF rendering.

The stack explicitly builds `libvulkan_ps4.so` for the OpenOrbis PS4 environment. This is substantially stronger evidence than the earlier generic statement that "PS4 Vulkan exists": there is now a concrete open-source implementation to study. citeturn0search13turn0search7

### 17.2 What this means for Kodi

Vulkan is now a **serious candidate for investigation**, but it is not automatically the correct first renderer.

There are two distinct questions:

1. **Can Vulkan run on PS4?**
   - Current public evidence: yes, via an independent PS4 Vulkan ICD/graphics stack.

2. **Can Kodi's current Vulkan renderer run on that implementation?**
   - Not yet demonstrated.
   - The ICD targets Vulkan 1.0, so Kodi's actual minimum Vulkan feature/extension requirements must be audited.
   - Kodi's renderer may rely on extensions/features that the PS4 ICD does not implement.
   - Video-frame interop is an additional problem independent of basic GUI rendering.

Therefore Vulkan should be treated as a **parallel research track**, not yet selected as the renderer.

### 17.3 Vulkan vs Piglet/GLES research tracks

We should now explicitly compare:

| Question | GLES/Piglet | Vulkan/OpenGNM |
|---|---|---|
| PS4 runtime exists | Yes | Yes |
| Open-source PS4 implementation | OpenOrbis ecosystem | PS4-OpenGNM ecosystem |
| API generation | GLES 2.0-era surface | Vulkan 1.0 |
| Kodi renderer compatibility | Unknown | Unknown |
| Existing PS4 renderer examples | Yes | Yes |
| Toolchain integration | OpenOrbis | OpenOrbis |
| Main uncertainty | Modern Kodi GLES feature requirements | Vulkan 1.0 feature/extension coverage + ICD maturity |
| Potential advantage | More direct Sony/Piglet path | Modern explicit API and potentially cleaner fit for modern Kodi |
| Main risk | ES2 limitations | Third-party ICD completeness/performance/maintenance |

The key point is that **Vulkan may actually be worth investigating before committing to GLES**, because the existence of `vulkan-ps4` changes the architecture options materially.

### 17.4 Revised renderer strategy

The project should not yet choose between GLES and Vulkan.

Instead:

**R-001A — GLES capability audit**
- Kodi GLES minimum API/version
- required extensions
- shader requirements
- FBO/texture requirements
- video texture paths
- Piglet limitations

**R-001B — Vulkan capability audit**
- Kodi Vulkan minimum version
- required extensions
- descriptor/resource requirements
- synchronization primitives
- swapchain/presentation assumptions
- shader model
- external-memory/video-frame interoperability
- compatibility with the public PS4 Vulkan ICD

**R-002A — GLES proof of concept**
- EGL context
- textured triangle/quad
- VideoOut presentation
- texture upload
- frame pacing

**R-002B — Vulkan proof of concept**
- instance/device creation
- required extensions
- swapchain/presentation
- SPIR-V shader
- textured triangle
- frame pacing

The first renderer should be selected **from evidence produced by these audits and POCs**, not by assuming that the older or newer API is inherently better.

### 17.5 Important architectural consequence

The Kodi platform layer should be designed so that the renderer backend is replaceable:

```
             Kodi
               |
        CWinSystemPS4
               |
       +-------+-------+
       |               |
   GLES/Piglet     Vulkan/ICD
       |               |
       +-------+-------+
               |
          PS4 VideoOut
```

This avoids making the entire PS4 port dependent on one graphics API before the hardware/software evidence is sufficient.

### 17.6 Current recommendation

**Do not implement either renderer yet.**

The next research action should be a **side-by-side capability audit of Kodi's current GLES and Vulkan renderers against the two PS4 implementations**.

This is now more valuable than investigating only GLES.

### 17.7 Evidence quality / caution

The PS4-OpenGNM project is an external community implementation, not an official Sony SDK and not part of OpenOrbis itself. Its existence demonstrates feasibility of a Vulkan path in the PS4 homebrew ecosystem, but it does not establish production maturity or compatibility with Kodi.

OpenOrbis itself still describes its GPU rendering support as an area of ongoing development, so the OpenOrbis toolchain should not be treated as proof that every graphics API path is equally complete. citeturn0search0turn0search1

---

## 18. Next action

The next audit is expanded from **R-001** to:

> **R-001 — PS4 graphics backend comparison: Kodi GLES/Piglet vs Kodi Vulkan/PS4-OpenGNM.**

Deliverable:

1. exact renderer requirements in the current Kodi source;
2. exact PS4 capabilities exposed by Piglet/OpenOrbis;
3. exact Vulkan 1.0 capabilities exposed/claimed by PS4-OpenGNM;
4. incompatibilities and missing features;
5. estimated adaptation surface;
6. recommendation based on evidence, without prematurely locking the architecture.

No Kodi code should be modified until this comparison is complete and the renderer direction has been validated.


---

## 19. Renderer audit correction — 2026-09-30

The first pass of the Vulkan investigation produced an important correction to the planned architecture.

### 19.1 Current Kodi does not provide a native application Vulkan renderer

The current official Kodi source exposes the application render-system selection around **GL/GLES**, and the rendering tree contains \`rendering/gl\` and \`rendering/gles\`. The current CMake documentation also describes application builds with \`APP_RENDER_SYSTEM=gl\` or \`APP_RENDER_SYSTEM=gles\`.

Kodi's public API does contain a Vulkan hardware-framebuffer context type for addons/Game API integration, but that is **not evidence of a native Kodi application Vulkan render backend**.

Therefore the previous wording "Kodi Vulkan renderer" was too strong and is corrected here.

### 19.2 Consequence for the PS4 project

There are now three distinct options, not two equivalent existing Kodi backends:

1. **Reuse/adapt Kodi's existing GLES renderer**
   - smallest conceptual divergence from Kodi;
   - requires proving compatibility with PS4 Piglet;
   - remains the first renderer to test.

2. **Introduce a new native Kodi Vulkan renderer**
   - technically possible to investigate using the PS4-OpenGNM Vulkan ICD;
   - would be a substantially larger Kodi change because Kodi does not currently expose an equivalent application renderer backend;
   - must not be selected merely because Vulkan is newer.

3. **Use Vulkan only for a standalone PS4 graphics POC**
   - useful to validate the PS4 Vulkan stack independently;
   - does not imply that Kodi itself should become Vulkan-based.

This makes the immediate research order clearer: **GLES/Piglet remains the lowest-change Kodi path, while Vulkan becomes a parallel feasibility experiment and a possible future backend.**

### 19.3 What the first Kodi test actually needs

The first Kodi build cannot realistically stop at "CMake compiles". A useful milestone must provide enough PS4 platform integration for Kodi to initialize its windowing/rendering stack.

The first Kodi milestone should therefore target:

    Kodi source
      |
    PS4 toolchain / CMake
      |
    PS4 platform selection
      |
    CWinSystemPS4 + EGL/GLES
      |
    Kodi CRenderSystemGLES
      |
    PS4 VideoOut presentation
      |
    TV

The following platform pieces will likely be required progressively for a real Kodi process:

- application entry point;
- PS4 platform identification and CMake integration;
- window system / EGL context;
- render-system registration;
- filesystem/path handling;
- timing/thread primitives where Kodi requires platform overrides;
- input integration sufficient to operate the application;
- audio integration as required by Kodi initialization;
- logging/runtime support;
- packaging and executable startup.

We should **not** implement every subsystem before the first boot. The objective is to identify the minimum dependency closure required for:

> **build → launch → initialize Kodi → initialize GPU → render Kodi UI → present to the TV.**

That is the first meaningful Kodi milestone.

### 19.4 Standalone GPU POC remains valuable

The standalone GPU POC comes before that milestone because it isolates the highest-risk graphics dependency.

The POC should test:

- EGL initialization with Piglet/GLES;
- basic shader compilation;
- vertex/texture upload;
- framebuffer/render target creation;
- presentation through VideoOut;
- synchronization/frame pacing.

A separate Vulkan POC can run in parallel:

- Vulkan instance/device creation;
- required Vulkan 1.0 features;
- command buffer and graphics pipeline;
- SPIR-V shader compilation;
- VideoOut-backed swapchain/presentation.

The Vulkan POC is therefore an **evidence-gathering experiment**, not yet a commitment to a Kodi Vulkan backend.

### 19.5 Updated implementation order

The implementation path is now:

1. **R-001A — GLES/Piglet capability audit**
2. **R-001B — Vulkan/PS4-OpenGNM feasibility audit**
3. **R-002A — standalone GLES/VideoOut POC**
4. **R-002B — standalone Vulkan/VideoOut POC**
5. **R-003 — minimal Kodi PS4 platform/bootstrap**
6. **R-004 — integrate the validated renderer**
7. **R-005 — input/audio/storage/network**
8. **R-006 — software video playback**
9. **R-007 — hardware video decoder and frame interop**
10. **R-008 — performance, synchronization, packaging and real-hardware validation**

This deliberately avoids spending weeks adapting unrelated Kodi subsystems before the GPU presentation path is proven.

### 19.6 Current renderer decision

**No renderer has been selected yet.**

Current evidence supports:

- **GLES/Piglet:** lowest-change path to an application renderer, but compatibility with modern Kodi remains unproven.
- **Vulkan/OpenGNM:** technically credible PS4 graphics path, but would require either a new Kodi application Vulkan backend or another integration strategy because current Kodi does not provide the equivalent native application renderer.
- **PS5 renderer:** remains a structural reference, not something to transplant.

The next technical task is therefore the **GLES/Piglet capability audit**, followed by the standalone POC. The Vulkan path remains active as a parallel research track.


---

## 20. R-001A — Kodi GLES vs PS4 Piglet capability audit — 2026-09-30

### 20.1 Upstream Kodi renderer baseline

The current official Kodi source has a dedicated GLES renderer in \`xbmc/rendering/gles\`, including:

- \`CRenderSystemGLES\`;
- \`CGLESShader\`;
- GUI composite shaders;
- GLES-specific screenshot handling;
- GLES GUI texture integration.

The build system enables this renderer when an \`OpenGLES\` target is available. Kodi's Linux build documentation explicitly supports \`APP_RENDER_SYSTEM=gles\`.

The shipped GUI shaders under \`system/shaders/GLES/2.0\` use **GLSL ES 1.00 / \`#version 100\`**, including the main vertex shader and standard GUI fragment shaders.

This is an important positive result: the core Kodi GUI shader language level is aligned with the documented PS4 Piglet baseline rather than requiring GLSL ES 3.x for the basic GUI renderer.

### 20.2 Basic API compatibility looks promising

Kodi's GLES renderer relies heavily on functionality already present in GLES 2.0:

- vertex attributes;
- GLSL ES 1.00 shaders;
- \`glUseProgram\`, uniforms and attributes;
- \`glViewport\` / \`glScissor\`;
- blending;
- depth testing;
- texture sampling;
- framebuffer rendering through the GLES abstraction;
- \`glGetString\` capability discovery.

The OpenOrbis Piglet sample documents Piglet as **OpenGL ES 2.0 + EGL 1.4**, and the official toolchain includes a working Piglet sample with packaged PS4 application structure.

Therefore the basic Kodi GUI rendering API is **not obviously blocked by the ES 2.0 baseline**.

### 20.3 Important compatibility finding: current Kodi already contains ES2 shader variants

This significantly reduces the concern raised in the first audit.

The current Kodi shader tree contains an explicit \`GLES/2.0\` set, and the core GUI shaders use \`#version 100\`. We therefore should not assume that modern Kodi automatically requires GLES 3.x merely because some newer features exist elsewhere.

The correct next question is now narrower:

> Which optional/current Kodi rendering paths actually execute GLES 3.x-only operations or depend on extensions absent from Piglet?

### 20.4 Identified GLES 2.0 pressure point: HDR GUI composite LUTs

Current Kodi's \`CGuiCompositeShaderGLES::CreateLUTTexture()\` prefers:

\`\`\`
GL_R16F + GL_RED + GL_FLOAT
\`\`\`

and falls back to:

\`\`\`
GL_LUMINANCE + GL_FLOAT
\`\`\`

The source explicitly comments that \`GL_R16F\` is a GLES 3.0 core format, while the fallback exists for GLES 2.0-style implementations.

This means the **basic GUI renderer can potentially remain GLES 2.0**, while newer HDR compositing needs careful runtime validation.

For PS4 Piglet, the first POC should therefore test both:

- normal SDR GUI rendering;
- the HDR/composite path separately.

We must not disable HDR globally yet; we first need to establish exactly what Piglet accepts.

### 20.5 Piglet-specific evidence

OpenOrbis's current Piglet sample explicitly identifies the implementation as GLES 2.0 / EGL 1.4 and demonstrates an application using Piglet. This provides a concrete PS4 target for the Kodi renderer rather than a purely theoretical API match.

A separate PS4 ioQuake3 port also reports successful use of a programmable GLES 2.0 renderer on Piglet, with GLSL ES 1.00 shader binaries. This is useful external evidence that the ES2 programmable pipeline is practical on real PS4 homebrew hardware, although it does not prove Kodi compatibility.

### 20.6 Current audit result

| Area | Kodi requirement | Piglet evidence | Assessment |
|---|---|---|---|
| EGL | required by PS4 window/context layer | EGL 1.4 documented | promising |
| GLES baseline | GLES renderer | GLES 2.0 documented | promising |
| GLSL | core GUI uses GLSL ES 1.00 | ES2 Piglet | promising |
| vertex attributes | used extensively | GLES2 core | compatible |
| uniforms/samplers | used extensively | GLES2 core | compatible |
| blending/scissor/depth | used | GLES2 core | compatible |
| FBO/render targets | used | must validate on Piglet | open |
| NPOT textures | used/expected | sample includes NPOT texture | promising |
| float/half-float textures | HDR path uses them | ES2 support is extension-dependent | **needs runtime test** |
| HDR GUI composite | current Kodi uses LUT textures + PQ/HLG shader | no Kodi-specific validation | **open** |
| video texture path | substantial Kodi-specific behavior | not audited yet | **open / high priority** |
| zero-copy video surfaces | platform-dependent | not audited | **open** |

### 20.7 What this changes

The GLES path is now more credible than after the first broad audit.

We **do not currently have evidence of a fundamental API mismatch** between Kodi's basic GLES GUI renderer and Piglet's ES2 baseline.

However, that does not mean Kodi will work unchanged. The remaining risk has moved from:

> "Kodi may fundamentally require newer GLES."

to:

> "Specific Kodi texture, FBO, video, HDR, extension and presentation paths may require capabilities or behavior that Piglet does not provide."

That is a much more tractable engineering problem.

### 20.8 Next POC requirements

The first PS4 graphics POC should therefore be designed to answer the remaining questions directly:

1. EGL 1.4 initialization;
2. GLES 2.0 context;
3. GLSL ES 1.00 shader compilation;
4. basic VBO/vertex-attribute rendering;
5. texture upload including NPOT;
6. FBO creation and render-to-texture;
7. float/half-float texture capability query;
8. VideoOut presentation and synchronization;
9. extension enumeration;
10. a minimal test of the Kodi-style shader/resource operations.

Only after this POC passes should we adapt the Kodi window system around the proven path.

### 20.9 Current R-001A conclusion

**Status: promising, not yet validated.**

The current evidence supports making **GLES/Piglet the primary first implementation path**.

This is not a permanent renderer decision. Vulkan remains a separate investigation because it could become valuable later for capabilities, performance, or a future renderer backend.

The next implementation step should be **R-002A — standalone GLES/Piglet + VideoOut POC**.

---

## 21. R-002A — standalone GLES/Piglet + VideoOut POC design — 2026-09-30

### 21.1 Objective

R-002A is a standalone graphics proof-of-concept. It remains independent from Kodi and establishes the minimum PS4 graphics/presentation chain required by the future Kodi port:

OpenOrbis application -> Piglet configuration -> EGL 1.4 -> GLES 2.0 -> precompiled Piglet shaders -> textures/FBOs/draw calls -> VideoOut presentation -> frame synchronization.

A passing POC does not prove that Kodi's complete GLES renderer is compatible. It proves that the underlying PS4 graphics and presentation primitives needed to continue the Kodi investigation are available and understood.

### 21.2 Important shader compilation correction

The POC must not depend on runtime GLSL compilation on a retail PS4. Public PS4 research documents that retail Piglet environments may lack the runtime shader compiler/Shacc component, while Piglet exposes a Sony-specific shader-binary path.

Therefore the intended model is: shader source -> reproducible host-side Piglet-compatible compilation -> precompiled shader binary -> PS4 application -> glShaderBinary -> program link.

The exact compiler/tool and binary format must be established from the OpenOrbis/Piglet sample and available tooling before implementation. Generic GLSL compiler output must not be assumed to be a valid Piglet binary.

### 21.3 Existing ecosystem evidence

OpenOrbis provides a dedicated Piglet application sample and includes EGL/GLES headers and PS4 graphics support. Its release history explicitly records the addition of the OpenGL/Piglet GPU rendering sample.

Independent PS4 research documents a working EGL 1.4 + OpenGL ES 2.0 Piglet path and identifies the PS4-specific shader-binary mechanism.

A public PS4 renderer implementation reports extensions including GL_SCE_piglet_shader_binary, GL_OES_texture_npot, GL_OES_texture_float, GL_OES_texture_half_float and GL_EXT_color_buffer_half_float. These are hypotheses for testing, not a substitute for querying the target console at runtime.

### 21.4 POC scope

Test A — runtime identification: log EGL version/vendor/extensions, GL version/renderer, GLSL version, GL extensions and relevant numeric limits.

Test B — EGL/GLES initialization: validate Piglet initialization, EGL display, EGL initialization, API binding, config selection, window surface, GLES 2.0 context and eglMakeCurrent. Every failure must identify the operation and error code.

Test C — precompiled shader path: create vertex and fragment shader objects, load Piglet-compatible binaries, check status, attach, link, validate and use the program. Preserve the shader binary as a reproducible/versioned build artifact and record the compiler/toolchain.

Test D — basic geometry: render a deterministic triangle or quad using vertex attributes, VBOs, uniforms, a simple fragment shader, viewport, clear and draw call.

Test E — texture upload: test RGBA 2D texture, NPOT texture, filtering, wrapping and sampling. Query float/half-float support instead of assuming it.

Test F — framebuffer object: create FBO, attach a color target, render to texture, check completeness, then sample the rendered texture in a second pass.

Test G — VideoOut presentation: establish the actual path from rendered image to physical display, including VideoOut opening, mode selection, framebuffer allocation, registration, flip/presentation, synchronization, ownership/lifetime and error handling. The exact API sequence must be taken from current OpenOrbis headers/samples and validated on hardware.

Test H — frame pacing: run a persistent loop and measure frame submissions, synchronization behavior, CPU frame duration, failed submissions and stability over an extended run. The goal is stable presentation, not peak performance.

Test I — Kodi-shaped resource operations: after the basic path works, test uniforms, multiple textures/samplers, scissor, blending, alpha blending, depth state, texture updates and FBO switching where relevant to the Kodi audit.

### 21.5 Diagnostic output

Every test should produce concise human-readable status and machine-readable status where practical. Suggested model:

[R-002A] EGL ........ PASS
[R-002A] GLES2 ...... PASS
[R-002A] Shader ..... PASS
[R-002A] Geometry ... PASS
[R-002A] Texture .... PASS
[R-002A] NPOT ....... PASS
[R-002A] FBO ........ PASS
[R-002A] VideoOut ... PASS
[R-002A] Sync ....... PASS
[R-002A] Kodi-like .. PASS

Failures are classified as BLOCKER, LIMITATION or UNKNOWN.

### 21.6 Proposed repository structure

Keep the POC isolated from future Kodi source changes:

poc/
  r-002a-gles-videoout/
    README.md
    build files
    include/
    src/
    shaders/
    tools/
    docs/

The exact build system should follow OpenOrbis sample conventions unless a concrete reason exists to introduce CMake immediately. The POC must be independently understandable without Kodi.

### 21.7 Acceptance criteria

R-002A succeeds when the target PS4 demonstrates:

1. EGL initialization;
2. a current GLES 2.0 context;
3. loading/linking of a Piglet-compatible precompiled shader pair;
4. basic primitive rendering;
5. texture upload and sampling;
6. NPOT texture handling;
7. FBO render-to-texture and second-pass sampling;
8. final presentation through the PS4 display path;
9. stable synchronization/frame pacing;
10. runtime capabilities logged and preserved as project evidence.

An optional feature failure must not be treated as total POC failure.

### 21.8 Explicit non-goals

The POC does not include Kodi source, Kodi CMake integration, Kodi window-system classes, input, audio, video decoding, hardware video surfaces, HDR implementation, Vulkan, or renderer optimization beyond basic frame pacing.

### 21.9 Expected outcomes

A strong pass permits progression toward Kodi integration. A partial pass identifies specific GLES/Piglet adaptations required. A fundamental blocker gives substantially more weight to the parallel Vulkan investigation. Renderer selection must follow evidence rather than API age.

### 21.10 Current R-002A status

Status: design complete, implementation not started.

The immediate prerequisite is R-002A.0 — establish the exact OpenOrbis Piglet sample/build conventions and the reproducible precompiled shader binary toolchain/format.

---

## 22. R-002A research update — shader binaries and current evidence — 2026-09-30

A fresh source review reinforces that precompiled shader binaries must be a first-class build artifact for this POC. OpenOrbis provides a Piglet sample and PS4 EGL/GLES support, while independent PS4 research documents that retail Piglet environments may lack runtime shader compilation and exposes a PS4-specific shader-binary mechanism.

Evidence quality: High confidence that OpenOrbis provides Piglet support; high confidence that Piglet has an implementation-specific shader-binary path; medium confidence that runtime compiler availability varies by environment; open question for the exact current host-side compiler and binary format.

### R-002A.0 — establish shader toolchain

Before implementing the renderer:

1. inspect the current OpenOrbis Piglet sample and shader-related files;
2. identify how its shaders are built and packaged;
3. identify the expected Piglet binary format;
4. identify whether OpenOrbis supplies a usable host-side compiler;
5. if not, identify a reproducible external/community tool;
6. create one known-good vertex/fragment binary;
7. verify that the binary can be loaded through the PS4 Piglet shader-binary API.

Only after R-002A.0 succeeds should the full POC implementation proceed.

---

## 23. R-002A.0 — OpenOrbis Piglet shader pipeline investigation — 2026-09-30

The current OpenOrbis Piglet sample was inspected in detail to determine whether it provides a reproducible shader compilation pipeline.

### 23.1 What the OpenOrbis sample actually provides

The sample is a complete GLES 2.0 / EGL 1.4 application and is directly useful as the reference implementation for the POC.

Its graphics initialization performs:

- `scePigletSetConfigurationVSH()`;
- `eglGetDisplay(EGL_DEFAULT_DISPLAY)`;
- `eglInitialize()`;
- `eglBindAPI(EGL_OPENGL_ES_API)`;
- an ES 2 renderable EGL configuration;
- a window surface;
- a GLES 2 context;
- `eglMakeCurrent()`.

The sample then queries the runtime GL vendor/version/renderer and renders through `eglSwapBuffers()`.

### 23.2 Critical shader discovery

The sample does **not** compile its shaders from source.

Instead it links against:

`-lScePrecompiledShaders`

and imports the exported `scePrecompiledShaderEntries[]` table. The sample looks up two entries:

- `texmap/v_2.vert`
- `texmap/f_2.frag`

and passes their raw byte ranges directly to:

`glShaderBinary(1, &shader, 0, binary, length)`

The sample explicitly documents that, on PS4, shader-binary format `0` is PSSL.

The OpenOrbis repository's `lib/` directory is only a generated-library placeholder; the repository does not contain a public shader compiler implementation or the source of `libScePrecompiledShaders`. The sample documentation describes these precompiled shaders as Sony WebKit shaders.

Therefore the OpenOrbis sample establishes a **known-good binary consumption path**, but it does **not** establish an open, reproducible GLSL/Piglet shader compiler.

### 23.3 Consequence for R-002A

This splits the shader problem into two independent questions:

1. **Can PS4 Piglet consume a valid precompiled shader binary?**  
   Yes at ecosystem/sample level: the OpenOrbis sample implements exactly this path.

2. **Can this project reproducibly generate its own shader binaries for Kodi's shader sources?**  
   Still open.

This distinction is important. We do not need to solve the entire shader-production problem before proving the EGL/GLES/VideoOut pipeline. The POC can initially use the OpenOrbis sample's known-good precompiled vertex/fragment pair to validate the runtime graphics path.

However, shader production remains a **required prerequisite for eventual Kodi integration**, because Kodi contains its own shader set and cannot depend on Sony's WebKit shader table.

### 23.4 Additional ecosystem evidence

Recent PS4 homebrew development continues to report Piglet applications using precompiled shader binaries through `glShaderBinary()`, while community reports also describe differences in shader-compiler/Shacc availability between retail firmware and development environments. This reinforces the decision not to make runtime shader compilation a dependency of the port. These reports are supporting evidence only; the OpenOrbis sample is the primary implementation reference.

### 23.5 Revised R-002A.0 result

**Status: partially complete / sufficient to proceed with the graphics POC.**

Established:

- exact OpenOrbis Piglet initialization sequence;
- exact GLES 2.0 context requirements;
- exact precompiled shader loading mechanism;
- shader binary format value used by the sample (`0`);
- existence of a known-good precompiled shader pair;
- absence of an open shader compiler in the OpenOrbis repository.

Still open:

- exact official Sony host compiler/tool for generating Piglet-compatible PSSL binaries;
- whether a clean-room/community tool can reproducibly generate the same class of binaries;
- how Kodi's GLSL ES 1.00 shader sources will be converted/compiled for Piglet;
- compatibility requirements for shader uniforms/attributes after compilation.

### 23.6 Immediate implementation strategy

Proceed with the standalone R-002A POC using the OpenOrbis sample's known-good precompiled shader pair as the initial shader fixture.

Do **not** copy the Sony/WebKit shader binaries into the Kodi project as if they were Kodi assets. They are a validation fixture for the POC only.

In parallel, keep shader production as a separate research track. The Kodi renderer cannot be considered integration-ready until a reproducible way of producing the required shader binaries has been established.

### Sources inspected

- OpenOrbis Piglet sample README and source.
- OpenOrbis Piglet sample Makefile/build script.
- OpenOrbis `Pigletv2VSH.h` / GLES headers.
- Public PS4 Piglet research and current community reports concerning precompiled shader binaries and Shacc availability.


---

## 24. R-002A.1 — SDK 4.50 and open-source shader pipeline investigation — 2026-09-30

This investigation follows the discovery of the official PS4 SDK 4.50 family and new open-source evidence about Piglet shader binaries.

### 24.1 Official PS4 SDK 4.50

The PS4 Developer wiki documents SDK version **4.508.021** as an official PS4 DevKit/TestKit software version. Public documentation confirms that the official SDK is a licensed/proprietary Sony development suite, so the Kodi repository must not redistribute SDK files or proprietary shader tools.

The exact contents of a locally available “PS4 SDK 4.50 Offline” installation have **not yet been inspected in this project**. In particular, the presence and behavior of tools such as `orbis-esslc`, `orbis-wave-esslc`, or Shacc/Piglet shader tooling remain unverified from the installation itself.

A current community report from a PS4 Piglet developer specifically asks which official tool produces native Piglet shader binaries and mentions `orbis-esslc` / `orbis-wave-esslc` as candidates. This is supporting evidence, not proof of the exact SDK 4.50 pipeline.

**Conclusion:** SDK 4.50 remains a valuable research reference, but we must inspect the actual installation before claiming that it solves Kodi shader production.

### 24.2 Major new evidence: ioQuake3-PS4

The open-source `ioQuake3-PS4` project provides a hardware-verified Piglet renderer using OpenOrbis and is directly relevant to Kodi.

Its documented renderer uses:

- GLES 2.0 through Piglet;
- GLSL ES 1.00 (`#version 100`);
- offline-compiled per-stage Piglet shader binaries;
- `glShaderBinary()` at runtime;
- no runtime shader compilation requirement for normal release builds.

The project reports **124 shader blobs / 62 programs / approximately 1.5 MB** of shader binaries shipped with the application. It also implements a debug capture path using the undocumented Piglet export `glPigletGetShaderBinarySCE`, resolved with `eglGetProcAddress`.

The captured blobs are stored in the application package and loaded directly from the package at runtime. This is strong evidence that a practical Piglet application can operate without requiring ShaccVSH during normal runtime.

### 24.3 Important shader-format nuance

There is an important discrepancy that must not be simplified away:

- the OpenOrbis Piglet sample calls `glShaderBinary()` with format `0` and documents this as PSSL;
- current ioQuake3-PS4 documentation reports that its capture path uses the format reported by the Piglet driver, with **0x9270** observed on its tested console.

Therefore the project must **not hard-code a guessed shader-binary format**. The exact binary container and accepted format value must be determined from the target Piglet environment and chosen production pipeline.

The OpenOrbis sample's shader pair is therefore a valid runtime fixture, but it is not enough by itself to define Kodi's eventual shader asset format.

### 24.4 What ioQuake3 does and does not prove

Established:

1. A real PS4 application can use a programmable GLES 2.0/Piglet renderer.
2. GLSL ES 1.00 sources can be turned into Piglet-native stage binaries offline.
3. Those binaries can be shipped with the application and loaded with `glShaderBinary()`.
4. Normal runtime operation does not need ShaccVSH.
5. Piglet-specific limitations can be worked around at the renderer level.

Not yet established:

1. Which exact host compiler produced ioQuake3's original shader binaries.
2. Whether that compiler is open-source.
3. Whether that compiler is part of the official SDK 4.50.
4. Whether the resulting pipeline can compile Kodi's complete shader set without source-level adaptation.

Therefore ioQuake3 is currently a **strong reference implementation**, not yet a complete open-source shader-production solution.

### 24.5 Relevant Piglet limitations discovered from ioQuake3

The project reports hardware-verified Piglet-specific limitations including:

- depth-only FBOs returning `GL_FRAMEBUFFER_UNSUPPORTED`;
- HDR being forced to RGBA8 because `GL_RGBA16F` is unavailable in its GLES 2 path;
- renderer-specific shader adaptations;
- runtime shader compilation removed from the normal release path.

These findings reinforce the R-002A requirement to test FBOs, float/half-float formats and HDR-related behavior rather than assuming generic GLES 2.0 support is sufficient.

### 24.6 Open-source alternative: OpenGNM / opengnm-psbc

The open-source `PS4-OpenGNM` stack now provides an OpenGNM library, `opengnm-psbc` and a Vulkan 1.0 PS4 ICD. `opengnm-psbc` uses Mesa NIR/ACO and supports PS4 base GFX7 and PS4 Pro GFX8/NEO targets. Its VS/PS output has been hardware-validated on PS4 FW 9.00.

This is highly relevant to the **future Vulkan/GNM research track**, but it does **not currently solve the Piglet shader-production problem**. Its output is the GNM shader-binary format consumed by `sceGnmSet*Shader`, not the Piglet shader-binary path consumed by `glShaderBinary()`.

### 24.7 Updated shader strategy

The shader problem is now divided into three independent paths:

```text
Path A — Piglet runtime validation
OpenOrbis known-good Piglet binary
        ↓
glShaderBinary()
        ↓
Piglet
```

```text
Path B — Piglet production for Kodi
Kodi GLSL ES 1.00
        ↓
??? reproducible host compiler
        ↓
Piglet-native shader binary
        ↓
glShaderBinary()
```

```text
Path C — future Vulkan/GNM research
SPIR-V
        ↓
opengnm-psbc
        ↓
GNM shader binary
        ↓
GNM / Vulkan-PS4
```

Path A is sufficiently established to proceed with R-002A. Path B remains the prerequisite for eventual Kodi renderer integration. Path C is a promising open-source alternative for a future Vulkan/GNM renderer and must not be conflated with Piglet.

### 24.8 Updated project assessment

The investigation increases confidence in the practical viability of GLES/Piglet. The strongest new evidence is the existence of a current open-source, hardware-verified PS4 application that uses the same GLES 2.0/Piglet family, GLSL ES 1.00, precompiled Piglet shader binaries and `glShaderBinary()`, without requiring ShaccVSH during normal runtime.

The remaining unknown is sharply defined:

> **What reproducible toolchain should this project use to transform Kodi's GLSL ES 1.00 sources into the same class of Piglet-native shader binaries?**

This is currently a build/toolchain problem, not evidence of a fundamental renderer blocker.

### 24.9 Next research action

Before writing a Kodi-specific shader compiler or adapting all Kodi shaders:

1. inspect the local PS4 SDK 4.50 installation, if available, for Piglet/ESSLC/Shacc tooling;
2. inspect ioQuake3's build/history and shader-generation provenance to identify how its initial binaries were produced;
3. compare the resulting binary format and `glShaderBinary()` format handling;
4. investigate whether a clean-room/open-source Piglet compiler exists or can be derived from documented/reverse-engineered formats;
5. only then define the long-term Kodi shader build pipeline.

R-002A runtime graphics work can proceed independently using a known-good shader fixture.

### Sources

- PS4 Developer wiki — SDK `4.508.021`.
- OpenOrbis Piglet sample and project documentation.
- `ioQuake3-PS4` renderer documentation and source.
- `PS4-OpenGNM/opengnm-psbc` documentation and hardware-validation notes.
- Community discussion concerning official Piglet shader compilation tooling.

---

## 25. R-002A.2 — shader compilation is a packaging prerequisite for a usable Kodi PKG — 2026-09-30

The previous distinction between the runtime graphics POC and long-term shader production is now clarified.

### 25.1 Important build distinction

A PS4 PKG can technically be assembled without compiling shader sources: the package tool can bundle the executable and whatever files are available.

However, that is **not sufficient to produce a usable Kodi graphics build**.

For a Piglet release path where runtime GLSL compilation is not available/reliable, the final application needs the precompiled Piglet shader binaries corresponding to the shader sources used by Kodi. Those binaries must be present in the PKG and successfully loaded through glShaderBinary().

Therefore:

- **C/C++ compilation of the application:** does not intrinsically require the Piglet shader compiler.
- **PKG assembly:** does not intrinsically require the shader compiler.
- **A functional Kodi PKG using the intended retail-safe Piglet path:** **does require Kodi's shader binaries to have been produced beforehand**.
- **Final end-to-end R-002A validation:** cannot be considered complete until at least one complete, project-owned shader production path exists, or a deliberately documented debug-only runtime compilation path is proven on the target environment.

This means shader production is not merely a later optimization/build convenience. It is part of the renderer's **release build pipeline**.

### 25.2 ioQuake3 evidence strengthens this conclusion

The current ioQuake3-PS4 implementation ships its Piglet shader blobs inside the application package and loads them at runtime. Its normal release path does not depend on ShaccVSH. This confirms the practical model we should target for Kodi: compile once on the host, ship the resulting binaries, load them on the PS4.

Its debug capture mechanism can help generate Piglet-native blobs on hardware when a source shader can still be compiled, but this is a **capture mechanism**, not a reproducible host-side compiler. It therefore cannot by itself solve Kodi's build pipeline.

### 25.3 Consequence for the R-002A plan

We should not block the first EGL/GLES/VideoOut experiments on having every Kodi shader compiled.

Instead, use a staged approach:

1. **Runtime POC:** use a known-good Piglet shader fixture to validate EGL/GLES/texture/FBO/VideoOut.
2. **Toolchain investigation:** identify the actual host-side Piglet compiler from the available SDK/toolchain or establish a clean-room alternative.
3. **Minimal project-owned shader:** compile one trivial project shader from source and load it with glShaderBinary().
4. **Kodi shader pilot:** compile a small representative subset of Kodi's GLES shaders and validate uniforms/attributes/program linking.
5. **Full shader inventory:** compile all shaders required by the chosen Kodi renderer configuration.
6. **Only then:** treat the Piglet renderer as ready for a production Kodi PKG.

### 25.4 Current blocker classification

The shader compiler is therefore a **release-pipeline blocker for a production Kodi Piglet PKG**, but it is **not a blocker for the standalone graphics POC**.

This distinction prevents us from either:
- falsely declaring Piglet production-ready without a shader pipeline, or
- unnecessarily postponing all graphics experiments while the compiler question remains open.

### 25.5 New immediate action

The next research target is now explicit: determine how the ioQuake3-PS4 project obtained its **initial** shader binaries and whether the provenance points to a publicly available compiler, an official SDK tool, or a hardware-capture/bootstrap process.

In parallel, if the local PS4 SDK 4.50 installation is accessible, inspect it directly for ESSLC/Piglet/Shacc tooling rather than inferring its contents from public reports.

---

## 26. R-002A.3 — ioQuake3 identifies the missing shader compiler as psbc — 2026-09-30

A new inspection of the current ioQuake3-PS4 repository materially narrows the shader-production question.

### 26.1 ioQuake3 explicitly credits psbc for shader compilation

The current ioQuake3-PS4 README lists psbc as the tool used for "Shader compilation". The same README states that its GLSL ES 1.00 sources are compiled offline into Piglet's native per-stage Shader Binary format and that 124 resulting blobs are shipped in the PKG.

This is the first direct evidence in the project investigation connecting the shipped ioQuake3 Piglet shader binaries to a named external compiler.

### 26.2 Important distinction: psbc vs OpenGNM opengnm-psbc

There are now at least two similarly named PS4 shader projects and they must not be conflated.

- ioQuake3's psbc is explicitly credited by ioQuake3 for its shader compilation.
- PS4-OpenGNM/opengnm-psbc is a separate project whose documented input is SPIR-V and whose output is the GNM shader binary consumed by sceGnmSet*Shader. It is therefore a GNM/Vulkan-track compiler, not evidence that it produces the Piglet glShaderBinary() payload required by this project.
- A separate current lateleite/psbc project also describes itself as a PS4 Shader Binary compiler based on Mesa, but its published interface is SPIR-V -> PlayStation Shader Binary and its public documentation is GNM-oriented. It must therefore not yet be assumed to be the exact Piglet compiler used by ioQuake3.

### 26.3 ioQuake3 build-system finding

The current ioQuake3 Makefile does not compile the shader binaries as part of the normal Makefile build. The repository already contains the generated fixes/shaderbin/ assets, while the Makefile packages those files.

Its normal build therefore has this structure:

existing shader binaries -> PKG packaging

rather than:

GLSL source -> compiler -> shader binaries -> PKG

This explains why simply reproducing the ioQuake3 Makefile does not reveal the original compilation command.

The renderer source confirms that the runtime loader reads each blob from /app0/fixes/shaderbin/, reads the captured format value stored alongside it, and passes the binary to glShaderBinary().

### 26.4 New hypothesis

The strongest current hypothesis is:

ioQuake3 GLSL ES 1.00 -> psbc -> Piglet native shader binaries

Confidence: medium-high that psbc is the named tool responsible for the ioQuake3 shader compilation workflow, because the project explicitly credits it. Confidence remains low-medium on the exact version, source repository state, command line and whether this psbc can compile arbitrary Kodi shaders.

### 26.5 Immediate next action

The next research step is no longer to search randomly for orbis-esslc first.

We should identify the exact psbc repository referenced by ioQuake3, inspect its source/history/documentation, and establish:

1. its input language(s);
2. whether it accepts GLSL ES 1.00 directly or requires an intermediate representation;
3. its output format;
4. whether its output is specifically compatible with Piglet glShaderBinary();
5. its license;
6. how ioQuake3 generated its original 124 blobs;
7. whether it can compile a minimal shader suitable for our POC;
8. whether it can become a reproducible Kodi build dependency.

Only after this investigation should we decide whether to adopt psbc, adapt it, or implement another compiler path.

### 26.6 Consequence for the project

The shader problem has moved from:

"unknown compiler"

to:

"identify and validate the exact psbc implementation used by ioQuake3."

This is a significant reduction in uncertainty and should be treated as the next concrete blocker-resolution task for the Piglet release pipeline.

---

## 27. R-002A.4 — exact ioQuake3 psbc repository identified — 2026-09-30

The previous research question has been narrowed further: the current ioQuake3-PS4 repository explicitly links the shader compiler credited in its README.

### 27.1 Exact repository reference

ioQuake3-PS4 credits:

**psbc — https://gitgud.io/veiledmerc/psbc — Shader compilation**

This is materially stronger than the previous generic evidence that a tool named psbc exists. The repository URL is now known from the ioQuake3 project's own source.

The current ioQuake3 README simultaneously states that:

- its renderer uses GLES 2.0 through Piglet;
- shader sources are GLSL ES 1.00;
- those sources are compiled offline into Piglet-native per-stage Shader Binary files;
- 124 blobs are shipped in the PKG;
- the normal runtime path loads those binaries through glShaderBinary().

Taken together, the project documentation establishes a direct provenance chain at the project level:

```text
ioQuake3 GLSL ES 1.00
        |
        v
psbc (gitgud.io/veiledmerc/psbc)
        |
        v
Piglet-native shader binaries
        |
        v
glShaderBinary()
        |
        v
PS4 runtime
```

The exact compiler repository is therefore no longer unknown.

### 27.2 What is still unverified

The GitGud repository itself could not be inspected through the currently available web fetch path, so the following details remain unverified from the compiler's own source:

1. exact source revision/version used by ioQuake3;
2. build instructions and host dependencies;
3. accepted input format;
4. exact output container/format;
5. command line used to produce the 124 ioQuake3 blobs;
6. whether the compiler accepts arbitrary GLSL ES 1.00 or requires a specific preprocessing/IR step;
7. license and redistribution terms;
8. reproducibility on a clean development machine;
9. compatibility with the shader requirements of Kodi.

This is an access limitation, not evidence that the repository is unavailable or unsuitable.

### 27.3 Important correction to confidence

Confidence is now **high** that the named psbc repository is the compiler project intended by ioQuake3's documentation, because the ioQuake3 README links directly to it under the explicit credit “Shader compilation”.

Confidence remains **medium** that we can immediately use it for Kodi. The missing information is implementation-level: input/output contract, exact revision, buildability and compatibility with Kodi's shaders.

### 27.4 Additional evidence from the surrounding PS4 ecosystem

The OpenGNM/freegnm ecosystem also references the original psbc project at the same GitGud URL, distinguishing it from the newer opengnm-psbc project. This confirms that gitgud.io/veiledmerc/psbc is a known project in the PS4 homebrew ecosystem rather than a typo or an ambiguous repository name.

This still does not establish that the newer GNM-oriented opengnm-psbc is equivalent to the original psbc. They remain separate until source-level comparison proves otherwise.

### 27.5 Next action

The next action is now focused and should be performed before any Kodi shader work:

1. obtain/inspect the exact veiledmerc/psbc source or an authoritative mirror;
2. identify its compiler frontend and shader input contract;
3. determine the generated Piglet binary format and format value expected by glShaderBinary();
4. locate ioQuake3's original shader-generation provenance, including the exact psbc revision and invocation if recoverable from history/artifacts;
5. build psbc independently;
6. compile one minimal GLSL ES 1.00 vertex/fragment pair;
7. compare its output characteristics with the ioQuake3 shipped blobs and, where possible, validate the generated pair on the R-002A PS4 POC.

No Kodi shader conversion should be implemented until this validation is complete.

### 27.6 Current blocker status

The release-pipeline blocker is now reduced to **tool acquisition and validation**, not compiler discovery.

R-002A can continue with the known-good shader fixture while this track is resolved. The eventual Kodi Piglet integration remains gated on a reproducible project-owned shader build path.
---

## 28. R-002A.5 — ioQuake3 history shows when the 124 shader binaries entered the project — 2026-09-30

The ioQuake3 repository history provides an important additional clue about shader provenance.

### 28.1 The 124 blobs were introduced together with the precompiled-shader transition

Commit e265104cb90b844daa4e5e93586e76fadf812c2a, dated 2026-07-21 and titled **“Ditching Piglet + Shacc”**, changes the renderer from runtime shader compilation/cache handling to the shipped per-stage shader-binary model.

The commit simultaneously:

- adds ps4_shaderbin.c/.h;
- changes the renderer to load per-stage binaries;
- removes the old glGetProgramBinaryOES cache;
- makes ShaccVSH optional/fallback-only;
- adds the fixes/shaderbin/ package directory;
- packages the shaderbin directory;
- and contains **exactly 124 shader binary blobs**, totalling about 1.17 MB of raw Git blob data at that revision.

This is strong historical evidence that the 124 production shader binaries were generated before or during this transition and then committed as release assets. The normal Makefile does not regenerate them.

### 28.2 What this history tells us

The project did not arrive at the current release pipeline by compiling shaders as part of every PKG build.

The historical transition is effectively:

```text
Piglet + ShaccVSH runtime compilation
              |
              v
capture/produce native shader binaries
              |
              v
commit 124 generated blobs
              |
              v
release builds package the blobs
              |
              v
runtime uses glShaderBinary()
```

This reinforces the conclusion that the host-side compiler/capture step is an **offline asset-generation stage**, separate from the ordinary C/C++ + PKG build.

### 28.3 What the history still does not reveal

The transition commit itself does not identify the compiler invocation. The current README later credits the exact GitGud psbc repository, but the historical commit that introduced the blobs does not expose a compiler command in the Makefile.

Therefore the missing information is now very specific:

> Which psbc revision/command was used to generate the 124 blobs before they were committed?

That is the most valuable remaining provenance question.

### 28.4 Consequence for Kodi

This gives us a concrete model for Kodi:

1. get the exact psbc source;
2. reproduce one ioQuake3-style shader compilation offline;
3. prove the resulting binary can be loaded by Piglet;
4. build a small Kodi shader conversion layer only if psbc requires Kodi-specific preprocessing;
5. generate Kodi's complete shader asset set as a separate build step;
6. make the normal Kodi PKG build consume those generated assets rather than invoking a compiler on the PS4.

We should **not** copy ioQuake3's 124 binaries into Kodi. They are useful as provenance/format references only.

### 28.5 Updated confidence

- **High:** the exact psbc project referenced by ioQuake3 is gitgud.io/veiledmerc/psbc.
- **High:** ioQuake3's release architecture uses precompiled Piglet stage binaries and does not regenerate them in its normal Makefile.
- **High:** the 124 blobs were already part of the project at the July 21 “Ditching Piglet + Shacc” transition.
- **Medium:** psbc directly produced those exact 124 blobs rather than another intermediate tool/capture process being used before packaging.
- **Low-medium:** exact psbc revision, invocation, and reproducibility remain unverified.

### 28.6 Next research action

The next step is therefore to obtain the GitGud psbc source itself or an authoritative mirror. If that cannot be fetched directly, search the PS4 homebrew ecosystem for mirrors, forks, packages, or references containing the same project history.

Only after recovering the source should we decide whether psbc can be built and used directly for Kodi.
---

## 29. R-002A.6 — psbc provenance: original project is referenced by the freegnm ecosystem — 2026-09-30

Further cross-repository research confirms that gitgud.io/veiledmerc/psbc is not an isolated reference from ioQuake3.

The current PS4-OpenGNM/freegnm-examples documentation explicitly distinguishes the original psbc project at gitgud.io/veiledmerc/psbc from the newer opengnm-psbc project. It describes opengnm-psbc as a SPIR-V-to-PS4 Shader Binary compiler while still listing the original psbc as a supported library/compiler.

This is useful because it confirms that the ioQuake3 credit points to a historically established PS4 shader project, and that the newer OpenGNM compiler should not be silently substituted for it.

### 29.1 Important limitation

The original GitGud repository remains inaccessible through the available web fetch path. No source-level claim about its implementation, input format, output format, license, or exact revision is therefore made yet.

### 29.2 Consequence

The research path is now:

1. recover the original veiledmerc/psbc source through a mirror/archive or local SDK/project copy;
2. compare it with references from the freegnm ecosystem;
3. identify whether ioQuake3 used the original compiler directly or a derivative/toolchain around it;
4. only then attempt a reproducible Kodi shader compilation.

The current evidence continues to support treating opengnm-psbc as a **different GNM-oriented compiler**, not as a replacement for Piglet shader compilation.

No Kodi code was changed in this research step.

## 30. R-002A.7 — authoritative open-source psbc source recovered via GitHub mirror — 2026-09-30

The previous blocker was the inaccessible GitGud repository veiledmerc/psbc. A new GitHub repository, **bizkut/psbc**, exposes source code and history for a project named **psbc** whose implementation and historical commits match the PS4 shader-binary research we need to investigate.

### 30.1 What the recovered source proves

The recovered bizkut/psbc project is a host-side shader compiler built on Mesa NIR/ACO. Its documented CLI accepts **SPIR-V**, not GLSL ES source directly:

```
SPIR-V -> NIR -> ACO -> PlayStation Shader Binary
```

Its output writer explicitly constructs a PsslBinaryHeader, a GnmShaderFileHeader, stage-specific GnmVsShader/GnmPsShader structures, GCN ISA shader code, GnmShaderBinaryInfo, and PsslBinaryParamInfo.

The output is therefore a **PSSL/GNM-family shader binary**, not an implementation of a GLSL-to-Piglet frontend.

This is an important correction to the previous assumption that the recovered source might immediately solve Kodi's GLSL ES 1.00 -> Piglet pipeline.

### 30.2 Historical evidence is particularly valuable

The repository history contains commits from 2023 that explicitly discuss compatibility with official Sony shader tooling:

- `92261464dbdfa32cac4912cd587129ee7ecb8afb` — `pssl: export VS semantics starting at 15`, stating that this should improve compatibility with shaders produced by the official SDK.
- `54814297c1a42090a83a1ef325e5e5ec9a03c3e4` — `pssl: attempt to make header sizes correct`, noting compatibility with the official SDK's `sb-dump`.
- `593dba4994b6817e649397d3e1242f2cee545a6e` — `add BinaryShader crc32 and fix its offsets`, after which the official shader dumper reportedly works with shaders produced by psbc.

This makes the repository highly relevant as a **clean-room/reverse-engineered PSSL/GNM shader-binary implementation**, but it does not by itself prove that the exact binary it produces is the same object consumed by Piglet's glShaderBinary().

### 30.3 Current buildability evidence

The repository includes a complete Makefile and documents host requirements: C11 with GNU extensions, C++17, GNU Make, Python 3 with py3-mako, and libgnm headers.

A later commit, `e21e69960f387121428521988237744f6111f13f`, explicitly added native macOS build support for the shader compiler. This is useful evidence that the compiler is intended to be reproducibly built on a host rather than being a proprietary runtime-only component.

### 30.4 Important distinction from opengnm-psbc

This finding does **not** justify replacing the original psbc investigation with opengnm-psbc.

The recovered source is itself a psbc implementation and shares the same broad Mesa/NIR/ACO architecture, but its current documented input/output contract is still GNM/PSSL-oriented:

```
SPIR-V -> PSSL/GNM Shader Binary
```

The newer PS4-OpenGNM/opengnm-psbc follows the same broad architecture and explicitly targets sceGnmSet*Shader, while the original ioQuake3 use case is Piglet + glShaderBinary().

The remaining question is therefore narrower and testable:

> **Can a PSSL/GNM shader binary produced by this psbc implementation be accepted by Piglet, and if so under which glShaderBinary() format value?**

### 30.5 New highest-value experiment

Before attempting to write or find another compiler, the most efficient experiment is now:

1. build bizkut/psbc on the host;
2. compile a trivial vertex/fragment SPIR-V pair for PS4 base/GFX7;
3. load those generated binaries through the R-002A Piglet POC using glShaderBinary();
4. test the documented binary format and the format reported by Piglet where applicable;
5. compare the generated binary header/layout against an existing known-good Piglet blob from OpenOrbis/ioQuake3;
6. record whether Piglet accepts it and whether the resulting program links and renders.

A successful result would potentially remove the need to recover a separate proprietary/unknown Piglet compiler. A failure would still be valuable because it cleanly establishes that the GNM/PSSL compiler output is insufficient for Piglet.

### 30.6 Current confidence

- **High:** a usable source tree for a PS4 psbc implementation has been recovered.
- **High:** this implementation generates PSSL/GNM-family shader binaries from SPIR-V.
- **High:** it contains historical work specifically aimed at compatibility with official Sony PSSL shader tooling.
- **Medium:** it may be related to or descended from the veiledmerc/psbc project referenced by ioQuake3; source-level provenance between the GitHub mirror and GitGud project is not yet formally established.
- **Low-medium:** its output is directly consumable by Piglet through glShaderBinary(); this requires the R-002A hardware experiment.

### 30.7 Project impact

The shader investigation is no longer blocked on source acquisition.

The next blocker is now an **empirical format-compatibility test** between the recovered psbc PSSL output and Piglet's glShaderBinary() path.

No Kodi source was modified in this research step. The next implementation-relevant work remains the standalone R-002A graphics POC, with shader compatibility as the immediate experimental focus.

## 31. R-002A.8 — direct inspection of accessible opengnm-psbc — 2026-09-30

The project now has direct access to the public **PS4-OpenGNM/opengnm-psbc** repository. Its current README and plan remove an important ambiguity.

### 31.1 What opengnm-psbc actually provides

opengnm-psbc is a complete open-source SPIR-V -> PS4/PS5 shader compiler based on Mesa NIR + ACO.

It supports PS4 base **GFX7**, PS4 Pro **GFX8**, and PS5 **GFX10.3**. Its documented output is explicitly the GNM shader-binary container consumed by the `sceGnmSet*Shader` stage APIs.

The project reports hardware validation on a real PS4 FW 9.00: vertex + pixel shaders compiled for GFX7 rendered a triangle for 600 frames at 60 FPS through the GNM command-buffer path.

### 31.2 Source-level confirmation

Inspection of `libpsbc/psbc_compile.c` confirms that its binary builder constructs PsslBinaryHeader, GnmShaderFileHeader, stage-specific GNM shader structures, GCN machine code, GnmShaderBinaryInfo, and PsslBinaryParamInfo.

This is therefore not merely a structural-format experiment: it is an actual SPIR-V -> GCN -> GNM compiler with real PS4 execution validation.

### 31.3 Consequence for the Piglet investigation

This **does not solve the current Piglet shader problem**.

Piglet is consumed through the OpenGL ES/EGL path and `glShaderBinary()`. The OpenOrbis Piglet sample and ioQuake3 use precompiled Piglet shader blobs, whereas opengnm-psbc explicitly targets the GNM `sceGnmSet*Shader` API.

Therefore we must not assume that an `.sb` generated by opengnm-psbc can be passed to Piglet's `glShaderBinary()` merely because both ultimately execute GCN machine code.

The most useful role for opengnm-psbc in the current project is instead:

1. a proven open PS4 shader compiler for a future Vulkan/OpenGNM renderer;
2. a reference for PS4 GFX7 ACO code generation and shader-binary metadata;
3. a possible research aid when comparing GNM binaries against Piglet binaries.

It should **not** be adopted as the Piglet compiler without an actual hardware compatibility experiment.

### 31.4 R-002A decision update

The preferred immediate path remains:

```
GLSL ES 1.00 / Kodi shader
        -> Piglet-compatible offline compilation
        -> Piglet Shader Binary
        -> glShaderBinary()
        -> GLES2 program
```

The opengnm-psbc path is recorded separately:

```
SPIR-V
   -> Mesa NIR
   -> ACO
   -> PS4 GNM Shader Binary
   -> sceGnmSet*Shader
```

These are currently two distinct rendering pipelines.

### 31.5 Implementation constraint discovered

The repository is currently a research/documentation repository rather than a checked-in Kodi/OpenOrbis build tree. The R-002A POC therefore cannot yet be hardware-verified from this repository alone.

The OpenOrbis sample gives us the concrete EGL/Piglet initialization sequence, including `scePigletSetConfigurationVSH`, EGL 1.4 initialization, an ES2 context, and a native window structure. The next implementation should reproduce only that minimal path and keep shader binaries as externally supplied test fixtures rather than redistributing Sony-provided shader assets.

No Kodi source was changed in this step.


## 32. R-002A.9 — direct byte-level inspection of a known-good Piglet shader asset — 2026-09-30

The ioQuake3-PS4 repository exposes its shipped shader binaries through GitHub, which allows us to inspect the actual bytes rather than relying only on source comments.

### 32.1 The file contains the driver format value followed by the Piglet binary

A representative shipped asset, `fixes/shaderbin/11979310.bin`, is 1,895 bytes long. Its first bytes decode as:

```
70 92 00 00 71 bc 91 e8 ...
```

Interpreted little-endian, this is:

```
0x9270          -> GLenum format stored by the capture tool
0xE891BC71      -> Piglet Shader Binary magic
```

This exactly matches the current ioQuake3 capture implementation:

1. call the undocumented `glPigletGetShaderBinarySCE`;
2. receive both a binary blob and the driver's `GLenum format`;
3. write the format as a 4-byte prefix;
4. write the returned Piglet binary unchanged;
5. later read the prefix and pass that exact value to `glShaderBinary()`.

The same `0x9270` prefix is also visible in another representative asset, `2e57d5b2.bin`, confirming that this is not an isolated artifact.

### 32.2 This gives us a real Piglet binary fixture

We now have a concrete, independently inspectable binary format reference:

```
ioQuake3 asset
    |
    +-- uint32_t GLenum format = 0x9270
    |
    +-- Piglet binary
          |
          +-- magic = 0xE891BC71
          +-- embedded GLSL ES source
          +-- compiled PS4 shader data
```

The embedded source in the inspected vertex shader begins with `#version 100`, matching the project's documented GLSL ES 1.00 renderer.

This is significantly stronger evidence than merely knowing that Piglet accepts “some precompiled binary”: we can now identify the exact outer packaging used by a hardware-verified Piglet application and the beginning of the inner binary format.

### 32.3 Important consequence for the psbc experiment

The recovered `psbc` / `opengnm-psbc` family currently builds PSSL/GNM shader containers whose documented consumer is `sceGnmSet*Shader`.

The known-good Piglet asset instead begins with the Piglet-specific magic `0xE891BC71` and is consumed through `glShaderBinary()`.

Therefore, before attempting to feed an `opengnm-psbc` output into Piglet, we can now perform a deterministic host-side comparison:

- check whether the generated output begins with the Piglet magic;
- inspect whether it contains the Piglet container structure;
- compare its header/section layout with the known-good ioQuake3 fixture;
- only if the structures are plausibly compatible should a PS4 `glShaderBinary()` experiment be attempted.

If the generated file is instead only a PSSL/GNM container with the GNM magic/layout, that is strong evidence that it is the wrong binary family for Piglet and avoids an unnecessary hardware experiment.

### 32.4 New blocker reduction

The Piglet shader investigation has therefore progressed from:

```
“we know Piglet needs precompiled shaders”
```

to:

```
“we have an actual Piglet binary fixture, its format value,
its magic, and the exact capture/load packaging used by a
hardware-verified PS4 application.”
```

The remaining major unknown is now the **production path that generates this specific Piglet binary family from GLSL ES 1.00**.

### 32.5 Next action

The next research step should be to recover the original `veiledmerc/psbc` source/provenance more precisely and compare its generated binary header against the known-good Piglet fixture.

In parallel, if a local legitimate OpenOrbis/SDK installation is available, the most valuable inspection is the SDK's Piglet/ESSLC/Shacc tooling. We should inspect the actual installed toolchain rather than infer proprietary tool names from community discussions.

No Kodi source was modified in this step.
