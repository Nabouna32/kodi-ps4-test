# R-002A — GLES/Piglet capability probe

This directory contains the standalone runtime graphics probe for the first PS4 renderer investigation. It deliberately does not vendor Piglet modules or shader binaries.

## Why this uses the OpenOrbis sample

The OpenOrbis Piglet sample already provides the complete PS4-specific bootstrap:
- loads Piglet and PrecompiledShaders modules;
- configures Piglet;
- creates an EGL display/surface/context;
- uses an ES 2 context;
- loads precompiled shader blobs;
- presents with eglSwapBuffers.

The probe extends that sample rather than duplicating or guessing those platform details.

## Probe cases

After PigletApplication::Init() succeeds, the probe runs:
1. GL version/vendor/renderer/GLSL version and extensions;
2. NPOT RGBA texture upload;
3. RGBA8 1280x720 texture attached to an FBO;
4. float texture upload when the advertised extension is present;
5. capability detection for half-float and related extensions;
6. the existing Piglet sample's precompiled-shader/render/presentation path.

Runtime GLSL compilation is intentionally not part of this probe.

## Expected result

The experiment is successful only if the application boots on target PS4 hardware, the existing Piglet shader path links/renders, presentation succeeds, and the probe results are captured from the target runtime.

A source-level build is useful but is not hardware validation.

## Repository rule

Do not commit libScePiglet*.sprx, libScePrecompiledShaders*.sprx, SDK-derived binaries, or other firmware/proprietary artifacts.

The public repository contains only source, build logic and documentation.

## Upstream reference

Keep the POC synchronized conceptually with the OpenOrbis Piglet sample rather than copying the sample wholesale.
