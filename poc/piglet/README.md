# R-002A Piglet POC

First executable PS4 slice of the Kodi port. It is intentionally independent
of Kodi so that the Piglet/GLES2 contract can be measured before touching the
Kodi window system.

The POC tests Piglet configuration, EGL/GLES2 context creation, capability
logging, external precompiled shader loading/linking, NPOT texture allocation,
a color FBO, and first presentation with `eglSwapBuffers`.

Shader assets are intentionally not committed. Provide
`/app0/assets/shaders/vertex.bin` and `fragment.bin`. Each begins with a
32-bit little-endian format value followed by the exact payload passed to
`glShaderBinary`. This avoids putting proprietary Sony artifacts in Git and
avoids assuming one shader format value is universal.

Build with OpenOrbis and LLVM after setting `OO_PS4_TOOLCHAIN`:
`make`.

This milestone is **not hardware-validated yet**. The repository currently has
no PS4 runner/toolchain environment available to execute the binary.
