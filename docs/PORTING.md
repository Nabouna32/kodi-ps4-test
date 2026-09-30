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
