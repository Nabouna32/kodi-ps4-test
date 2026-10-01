# Kodi PS4 Port — Research and Validation

This file records investigations and evidence. It deliberately distinguishes validated results from hypotheses.

## R-001 — Kodi GLES/Piglet compatibility

Status: open.

Kodi GLES requirements have not yet been fully compared with the PS4 Piglet GLES 2.0/extension surface.

Required audit: shader language/version, framebuffer objects, texture formats, NPOT textures, float/half-float support, sampler requirements, shader precision, extensions used by Kodi, YUV/video texture paths, GUI compositor and render-to-texture requirements.

## R-002 — PS4 graphics/presentation proof of concept

Status: harness exists; real PS4 runtime validation pending.

Target chain: OpenOrbis -> Piglet -> EGL 1.4 -> GLES 2.0 -> shaders -> textures/FBOs -> VideoOut.

The POC is intentionally independent from Kodi.

## R-003 — PS4 hardware video / libSceAvPlayer

Status: open.

Public PS4 homebrew evidence reports hardware H.264/H.265 playback through libSceAvPlayer and NV12 frames. This establishes ecosystem-level capability only.

Still unknown: module/initialization requirements, supported containers, decoded-frame access, pixel formats, frame ownership/lifetime, timestamps and seeking, buffering/synchronization, GPU-friendly surface access, and Kodi CVideoBufferPS4 compatibility.

## R-004 — Zero-copy feasibility

Status: open.

The project has not proven direct import of PS4 decoder surfaces into Piglet/GLES. If zero-copy is impossible, an explicit NV12/P010 conversion path must be measured before committing to an architecture.

## R-004.5 — Windows OpenOrbis FSELF smoke test

Status: validated.

Native Windows testing validated compilation, PS4-targeted ELF linkage and FSELF conversion. GP4/PKG generation and real hardware execution remain unvalidated.

## R-004.6 — OpenOrbis CMake toolchain

Status: validated.

The repository toolchain uses the OpenOrbis FreeBSD target triple, libc++ headers, OpenOrbis linker script, target libraries and PIE settings consistent with the validated smoke test.

## R-004.7 — Kodi overlay application

Status: validated concept.

The repository-owned PS4 overlay is applied to a generated Kodi source tree before configuration.

## R-004.8 / R-004.9 — Native prefix corrections

Status: validated.

Kodi native build tools require a dedicated absolute NATIVEPREFIX. The prefix is kept separate from the PS4 target installation prefix.

## R-004.10 / R-004.11 — WSL2 + LLVM 21

Status: validated.

WSL2/Linux with LLVM/LLD 21.1.8 can compile, link and FSELF-package a minimal PS4 executable. The LLVM 21 tool suite is exposed through the development environment without hard-coding the path into the repository toolchain.

## R-004.12 — Clean Kodi submodule staging

Status: validated.

The build materializes the pinned Kodi commit into build/ps4/kodi-source and applies the overlay there. The pinned references/kodi submodule remains clean.

## R-004.13 — PS5 host-tool reference

Status: validated as build-system evidence.

The online PS5 reference builds TexturePacker and JsonSchemaBuilder natively, then supplies them to the cross-configure through WITH_TEXTUREPACKER, WITH_JSONSCHEMABUILDER and NATIVEPREFIX.

This confirms the host/target separation required for the PS4 build. It does not justify copying unrelated PS5 platform or packaging logic.

## R-004.14 — Native TexturePacker integration

**Status:** host prerequisites installed; build/configure validation pending.

The pinned Kodi `FindTexturePacker.cmake` was inspected at the exact pinned Kodi commit. It confirms that `WITH_TEXTUREPACKER` is a host executable/path used during cross-compilation, while FreeBSD normally enables `INTERNAL_TEXTUREPACKER_INSTALLABLE`. Therefore the PS4 build supplies a native TexturePacker and explicitly sets `INTERNAL_TEXTUREPACKER_INSTALLABLE=FALSE` rather than changing `HOST_CAN_EXECUTE_TARGET`.

The native tool is built from `tools/depends/native/TexturePacker/src` with `KODI_SOURCE_DIR` pointing at the materialized Kodi tree, `APP_NAME_LC=kodi`, POSIX/Linux architecture defines, and the WSL host compilers `/usr/bin/cc` and `/usr/bin/c++`. It installs into the existing native prefix.

The first synchronized configure-only validation reached native TexturePacker configuration but failed because `LZO2_LIBRARY` and `LZO2_INCLUDE_DIR` were missing. This was a host dependency issue, not a PS4 toolchain failure.

The following Ubuntu 26.04.1 host packages are now installed and verified:

    liblzo2-dev
    libpng-dev
    libgif-dev
    libjpeg-dev

No project-local replacement for these libraries was introduced. The next validation is to rerun the native host-tool build and continue through Kodi cross-configuration.

## R-004.15 — Official Kodi native mechanism vs PS5 host-tool integration

**Status:** audit completed; no implementation change made from this audit alone.

The exact pinned Kodi source distinguishes two related mechanisms:

- Kodi's official `tools/depends/native/Makefile` treats TexturePacker as one member of the complete native-dependency graph and requires the configured native prefix to contain `share/config.site` generated by the Kodi depends configuration.
- The dedicated `tools/depends/native/TexturePacker/Makefile` is a thin wrapper around the same official TexturePacker CMake source. It invokes `CMAKE_FOR_BUILD`, passes `NATIVEPREFIX`, `KODI_SOURCE_DIR`, `ENABLE_STATIC=1` and Kodi's native architecture defines, then installs the host executable.
- The official Kodi Wiki documents the same native tool location and also documents building TexturePacker directly from `tools/depends/native/TexturePacker` after the Kodi build dependencies are prepared.

The PS5 reference uses a deliberate standalone CMake invocation of `tools/depends/native/TexturePacker/src` and `JsonSchemaBuilder/src`, installs them into a native prefix, then supplies those binaries to the Kodi cross-configure through `WITH_TEXTUREPACKER`, `WITH_JSONSCHEMABUILDER` and `NATIVEPREFIX`. This is structurally the same host/target boundary as the current PS4 integration.

The PS4/OpenOrbis information does not introduce a PS4-side requirement for TexturePacker: OpenOrbis provides the PS4 target toolchain and PS4/EGL/GLES headers, while TexturePacker is a build-time Linux executable.

### Comparison and conclusion

The current host-tools helper is **not** a bespoke replacement for Kodi's TexturePacker implementation: it builds the exact Kodi-provided CMake source with the host compiler. It does, however, bypass Kodi's complete `tools/depends` orchestration.

For this project that is currently justified because the PS4 cross-build needs only the host executable at this stage, while invoking the full Kodi depends graph would introduce a much larger dependency/bootstrap path solely to obtain a host utility. The PS5 reference independently uses the same focused host-tool strategy.

Therefore the current helper is retained for now. It should be treated as a small PS4 build integration around Kodi's official TexturePacker source, not as a new TexturePacker implementation. A later audit of the complete Kodi depends/cmakebuildsys cross-build path can replace it only if that path provides a concrete advantage without adding unnecessary host dependency work.

## R-004.16 — Minimal bring-up dependency policy / Blu-ray

**Status:** validated decision; configure-only validation pending after implementation.

The pinned Kodi source lists `Bluray>=0.9.3` as an optional dependency. The current configure failure entered Kodi's internal libbluray build and then failed to find target `LibXml2`. Blu-ray support is not part of the first bring-up objective (Kodi GUI, GLES/EGL presentation, and PS4 controller input), so installing a WSL host `libxml2-dev` package would solve the wrong class of problem and would unnecessarily expand the initial dependency surface.

The PS4 platform overlay therefore forces `ENABLE_BLURAY=OFF` and excludes `Bluray` from the optional platform dependency set. This keeps the first build focused on functionality required to reach the GUI. Features can be re-enabled one by one after the minimal runtime is validated.

## R-004.17 — Minimal bring-up dependency policy / XSLT

**Status:** validated decision; configure-only validation pending after implementation.

At the pinned Kodi commit `9c3e7f4d7b3ff314cd2f19a291766555e0346024`, `XSLT` is part of Kodi's `optional_deps`, not `required_deps`. Kodi's `FindXSLT.cmake` only requires LibXml2 while configuring/building the internal libxslt path. The configure failure therefore came from an optional feature entering its dependency path, not from a PS4 requirement for LibXml2.

For the first bring-up milestone (Kodi GUI + GLES/EGL + PS4 controller), XSLT is not required. Installing `libxml2-dev` solely to satisfy this optional target feature would unnecessarily widen the dependency surface.

The PS4 overlay now excludes `XSLT` from `PLATFORM_OPTIONAL_DEPS_EXCLUDE`. No explicit `ENABLE_XSLT` override was added because Kodi models that option through its AUTO/string optional-dependency mechanism; platform-level exclusion is the narrower adaptation.

Next validation is a fresh `CONFIGURE_ONLY=1` run. If another blocker appears, classify it against the minimal milestone before installing dependencies or disabling additional functionality.


## R-004.18 — Required HarfBuzz target dependency / Kodi depends path

**Status:** integration implemented; WSL validation pending.

The new configure blocker is fundamentally different from Blu-ray/XSLT. At the pinned Kodi commit `9c3e7f4d7b3ff314cd2f19a291766555e0346024`, `ASS>=0.15.0` and `HarfBuzz` are required dependencies. The pinned `FindASS.cmake` explicitly requires HarfBuzz, and the Kodi GUI also includes HarfBuzz headers directly. Therefore HarfBuzz cannot be removed from the minimal bring-up profile merely to avoid the dependency.

Kodi's `FindHarfBuzz.cmake` has no internal-build macro: unlike `FindASS.cmake`, it only searches the configured target dependency prefix via CMake config/pkg-config and then exposes the resulting target. The official Kodi target-dependency tree does, however, contain `tools/depends/target/harfbuzz`, version `14.2.0`, built with Meson as a static library. Its Makefile explicitly supports cross-compilation and installs into Kodi's target dependency prefix.

The official target dependency graph also documents the important bootstrap relationship:

- `harfbuzz` depends on `freetype2-noharfbuzz` and optional target `libiconv`;
- `freetype2-noharfbuzz` exists specifically to break the FreeType ↔ HarfBuzz circular dependency;
- normal `freetype2` depends on HarfBuzz and enables HarfBuzz support;
- `libass` depends on Fontconfig, FriBidi, HarfBuzz, FreeType and optional Iconv.

This means installing Ubuntu `libharfbuzz-dev` would be the wrong fix: the missing library is the **PS4 target** HarfBuzz, not a Linux host library.

### PS5 comparison

The pinned PS5 reference does not solve this through Kodi's CMake `FindHarfBuzz` module. Its toolchain points Kodi at a PS5 target sysroot populated by pacbrew packages. The PS5 repository explicitly treats HarfBuzz as a target payload dependency alongside FreeType, FriBidi and libass. This confirms the architectural pattern—target-side HarfBuzz must already exist in the target sysroot—but the PS5 payload package cannot be reused or assumed compatible with PS4.

### OpenOrbis comparison

OpenOrbis provides the PS4 compiler, target headers/stubs and linker/toolchain infrastructure; it does not provide Kodi's third-party HarfBuzz library. Public OpenOrbis documentation describes the toolchain as providing PS4 headers/library stubs and requiring application/library dependencies to be supplied separately. Therefore Kodi's HarfBuzz must be built for the PS4 target and staged in a target dependency prefix.

### Conclusion

The smallest clean direction is **not** a new HarfBuzz implementation and not a CMake hack that points Kodi at a host library. The repository now reuses Kodi's official `tools/depends/target/harfbuzz` recipe and its `freetype2-noharfbuzz` bootstrap dependency through a minimal PS4/OpenOrbis overlay patch. The patch teaches Kodi's depends configure system about `x86_64-pc-freebsd12-elf` / `ps4` and extends the generated target CMake toolchain for FreeBSD. The build script configures only this dependency path, stages it in the target dependency prefix, and passes that prefix to Kodi CMake.

Implementation is committed, but it has not yet been executed in the WSL environment. The next validation is therefore the configure-only build; any failure must be classified from the real output before further adaptation.

Before implementation, the remaining concrete question is how to initialize Kodi's official `tools/depends` configuration for the OpenOrbis toolchain without accidentally pulling the entire desktop dependency graph. The target dependency graph shows that HarfBuzz itself has a deliberately small bootstrap path, so the implementation should build only that path and then let the normal CMake discovery consume the resulting target prefix.
## R-004.19 — Kodi native CMake bootstrap and system CURL

**Status:** host dependency root cause identified; remediation installed; bootstrap revalidation pending.

The official pinned Kodi native CMake recipe was reproduced directly. It invokes CMake's bootstrap script with:

    --prefix=<x86_64-linux-gnu-native>
    --system-curl

The first bootstrap phase successfully compiled the bootstrap executable and entered CMake's initial configuration. The root `Makefile` was nevertheless absent because the second configuration phase failed while resolving system CURL:

    CMAKE_USE_SYSTEM_CURL is ON but a curl is not found!

This is important because the failure is entirely on the **WSL/Linux host-tool side**. It is not a missing PS4 library and does not justify adding a target dependency, changing the OpenOrbis toolchain, or modifying Kodi's CMake recipe.

The normal host remediation was used: Ubuntu `libcurl4-openssl-dev` was installed. Verification returned libcurl 8.18.0 through pkg-config and exposed the development link flag `-lcurl`. Ubuntu 26.04's multiarch layout also explains why `/usr/include/curl/curl.h` is not necessarily present at that exact path.

### Conclusion

For this project, host development packages are an accepted and expected part of the WSL build environment when an official native Kodi recipe requires them. The strict separation is:

- WSL packages → host executables/build tooling;
- OpenOrbis + Kodi target depends → PS4 libraries/executables;
- no host Linux library may satisfy a PS4 target dependency.

Next experiment: rerun the unchanged official CMake bootstrap and verify generation of the native root `Makefile`.
