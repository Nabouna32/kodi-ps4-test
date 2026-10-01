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


## D-009 — Systematic three-source porting methodology

For non-trivial PS4 porting questions, the project follows a repeatable evidence chain: official Kodi first, the PS5 reference second, current public PS4/OpenOrbis information third, then an explicit comparison before adapting anything for PS4.

Reason: this preserves Kodi's upstream intent, exploits the PS5 port as a practical PlayStation/Kodi reference, and prevents PS5-specific assumptions from being mistaken for PS4 capabilities. The final PS4 implementation must be the smallest adaptation justified by the comparison and must be validated experimentally where possible.
## D-010 — Normal Ubuntu packages are valid for host-native Kodi tooling

Host-native Kodi build tools may use normal Ubuntu/WSL development packages when the official Kodi recipe requires them.

Reason: CMake, TexturePacker, JsonSchemaBuilder, Meson, Ninja and related build-time utilities execute on the Linux host. Avoiding normal host packages by introducing project-local substitutes would add unnecessary complexity. This does **not** permit host Linux libraries to satisfy PS4 target dependencies; target libraries remain separately built for the OpenOrbis/FreeBSD target.


## D-011 — Do not hard-code the host LLVM version before compatibility validation

The repository toolchain continues to select generic LLVM tool names (clang, clang++, llvm-ar, llvm-ranlib, ld.lld) rather than pinning an Ubuntu-specific LLVM path.

Reason: LLVM/LLD 18.1.8 is currently installed as a controlled compatibility experiment for OpenOrbis v0.5.4, while LLVM/LLD 21.1.8 remains the validated baseline for the standalone PS4 smoke test. The project must first demonstrate the actual Kodi/HarfBuzz build result with LLVM 18 before deciding whether a repository-level version requirement is justified.

## D-012 — Do not adopt LLVM 18 as the OpenOrbis header fix

The LLVM/Clang/LLD 18.1.8 experiment was executed against the real Kodi HarfBuzz target build and reproduced the same cmath/global-abs failure seen with LLVM 21.

Therefore LLVM 18 is not accepted as the fix for the current OpenOrbis v0.5.4 header mismatch.

The repository continues to avoid hard-coding an Ubuntu-specific LLVM version until a real compatibility requirement is demonstrated. LLVM 18 remains installed only as an available diagnostic baseline.

## D-013 — Preserve OpenOrbis libc++ header precedence over SDK C headers

The current HarfBuzz failure is caused by C++ header search order, not by a HarfBuzz source defect or a required LLVM version change.

OpenOrbis' forked libc++ provides a math.h wrapper that includes the SDK C math.h with #include_next and includes <stdlib.h> for C++. The libc++ cmath header expects that wrapper to be selected before the SDK C include directory.

Therefore, when validated, the PS4 C++ build must place:

    $OO_PS4_TOOLCHAIN/include/c++/v1

before:

    $OO_PS4_TOOLCHAIN/include

for C++ header lookup.

No OpenOrbis header copy, HarfBuzz patch, or compiler-version workaround is justified for this issue.

## D-014 — Preserve OpenOrbis libc++ header precedence for C++ target builds

**Status: validated decision.**

OpenOrbis libc++ wraps the SDK C headers and relies on its wrapper being found before the raw SDK header. A standalone PS4-targeted `<cmath>` test proves that the current repository order is broken and that libc++ first is sufficient to restore the expected global `abs` declaration.

Therefore the PS4 C++ target integration must use:

    -isystem $OO_PS4_TOOLCHAIN/include/c++/v1
    -isystem $OO_PS4_TOOLCHAIN/include

Only the ordering is to change. Target triple, sysroot, linker, CRT and libraries remain unchanged.
