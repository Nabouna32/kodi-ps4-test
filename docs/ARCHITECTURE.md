# Kodi PS4 Port — Architecture

## Source and platform boundary

The project uses official Kodi as the base and keeps PS4-specific integration outside the pinned Kodi submodule where practical.

    Official Kodi
        |
        +-- upstream/common Kodi
        |
        +-- repository-owned PS4 overlay/toolchain
              +-- PS4 platform layer
              +-- EGL/GLES integration
              +-- VideoOut presentation
              +-- scePad input
              +-- sceAudioOut audio
              +-- storage/network adapters
              +-- PS4 video codec/buffer integration

The PS5 port is a structural reference, not a codebase to transplant.

## Graphics

Current first renderer direction:

    Kodi GLES renderer
        |
    PS4 EGL
        |
    Piglet / GLES
        |
    PS4 presentation / VideoOut

This is an architectural hypothesis, not a runtime validation claim.

The principal graphics question is compatibility between Kodi GLES requirements and PS4 Piglet's actual GLES 2.0 feature/extension surface.

A standalone GLES/Piglet + VideoOut proof of concept is required before deep Kodi renderer integration.

Vulkan/OpenGNM remains a separate later path and is not the current first implementation target.

## Video

Intended Kodi boundary:

    Kodi CDVDVideoCodecPS4
        |
    PS4 decoder API
        |
    CVideoBufferPS4
        |
    PS4-compatible renderer

libSceAvPlayer is the first hardware-decoding candidate to investigate. Public PS4 homebrew evidence establishes ecosystem-level hardware H.264/H.265 playback, but not yet Kodi-compatible frame ownership, synchronization or zero-copy behavior.

A high-level player API must not replace Kodi's codec/buffer architecture.

## Other platform layers

Expected adapters:
- input: Kodi input -> scePad*
- audio: Kodi audio sink -> sceAudioOut
- filesystem/network: platform-specific Kodi adapters
- presentation: EGL/GLES output -> PS4 VideoOut

These are architectural targets, not completed implementations.
