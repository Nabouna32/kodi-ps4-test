# GLES/Piglet POC notes — 2026-09-30

The first POC design exposed an important retail-firmware constraint.

OpenOrbis's Piglet sample initializes EGL/GLES 2 but loads precompiled Piglet shader binaries through the PS4 precompiled-shader module. It does not rely on ordinary GLSL source compilation for its demonstrated rendering path.

The POC therefore reuses the OpenOrbis Piglet bootstrap and precompiled-shader mechanism, then adds capability probes for NPOT textures, FBOs, float/half-float textures, extensions and presentation through eglSwapBuffers.

Firmware-dependent modules must remain external to this public repository unless their redistribution status is explicitly established.

The POC source is a build harness, not target-hardware evidence. Runtime validation remains pending.
