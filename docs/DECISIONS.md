# Kodi PS4 Port — Decisions

## D-001 — Official Kodi remains the base

The port is based on official Kodi. The PS5 port is not the project's upstream.

Reason: preserve upstream maintainability and isolate PS4-specific integration.

## D-002 — PS5 port is a reference

VivaLaVent/kodi-ps5 is used for architecture, build-system and platform-integration research. Its PS5-specific implementation is not copied wholesale.

## D-003 — Prefer a PS4 platform layer and overlay

PS4-specific functionality is isolated in repository-owned platform/overlay code where practical. The pinned Kodi submodule remains clean.

## D-004 — GLES/EGL/Piglet first

GLES/EGL/Piglet is the first graphics path to validate. Vulkan/OpenGNM remains a later research/implementation path unless evidence changes the decision.

## D-005 — Preserve Kodi's video pipeline

A PS4 decoder must integrate through Kodi's codec and video-buffer boundaries. A high-level Sony player API must not replace Kodi's pipeline.

## D-006 — Host tools are distinct from PS4 target tools

TexturePacker, JsonSchemaBuilder and similar build-time utilities execute on the host. They must be built for the host and supplied explicitly to the PS4 cross-configure.

HOST_CAN_EXECUTE_TARGET=TRUE is not an acceptable workaround.

## D-007 — Clean-source staging

The pinned Kodi submodule is materialized with git archive HEAD into build/ps4/kodi-source; the PS4 overlay is applied only there.

This keeps the external source clean and makes the generated build input explicit.


## D-008 — Build TexturePacker as a host tool

TexturePacker is treated as a native host executable, not as a PS4 target executable. The PS4 build must provide the native executable through WITH_TEXTUREPACKER and must not set HOST_CAN_EXECUTE_TARGET to true. Because Kodi's FreeBSD logic otherwise marks its internal TexturePacker as installable, the PS4 configure explicitly disables INTERNAL_TEXTUREPACKER_INSTALLABLE.

Reason: Kodi's own FindTexturePacker.cmake establishes this host/target boundary, and the PS5 reference confirms the same build model. This keeps the PS4 target free of an unnecessary host-only build tool.
