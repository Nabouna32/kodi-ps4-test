# Kodi PS4 Port — Current Status

Repository: Nabouna32/kodi-ps4-test
Branch: main
Primary development environment: WSL2/Linux
Current phase: build/toolchain validation / minimal bring-up profile

## Validated

- Official Kodi is the upstream base; the PS5 port is a reference only.
- OpenOrbis + LLVM/LLD 21.1.8 can compile, link and FSELF-package a minimal PS4 executable under WSL2.
- The pinned references/kodi submodule remains clean during the normal overlay workflow.
- PS4 source is materialized to build/ps4/kodi-source before the repository-owned overlay is applied.
- Kodi native dependency discovery reaches flatc and JsonSchemaBuilder in the native prefix.
- The required Ubuntu host development packages for the pinned Kodi TexturePacker source are installed and verified:
  - liblzo2-dev
  - libpng-dev
  - libgif-dev
  - libjpeg-dev
- The PS4 configure entry script is versioned as executable (100755), so it can be invoked directly from a fresh checkout.

## Current blocker

The native host-tools bootstrap is validated for the currently required tools:
- TexturePacker: installed and accepted by Kodi
- JsonSchemaBuilder: installed as `JsonSchemaBuilder`, which the pinned Kodi finder accepts

Kodi now reaches the real PS4 cross-configuration, with `Cross-Compiling: TRUE`, `System type: FreeBSD`, `Core system type: ps4`, and `ARCH x86_64-ps4`.

The next configure blocker was libbluray: Kodi's optional `Bluray` dependency attempted to find target LibXml2 while configuring the internal libbluray build. Blu-ray playback is not required for the first bring-up milestone (Kodi GUI + GLES + PS4 controller), so the durable correction is to disable Blu-ray in the PS4 bring-up profile rather than install an unrelated host dependency.

The PS4 overlay now explicitly excludes Bluray from optional platform dependencies and forces `ENABLE_BLURAY=OFF`.

The following configure run then reached Kodi's optional `XSLT` dependency and failed through its internal libxslt path because LibXml2 was unavailable. The pinned Kodi source confirms that XSLT is listed under `optional_deps`, while its internal build path requires LibXml2. XSLT is not required for the first bring-up milestone, so the durable correction is to exclude `XSLT` from the PS4 optional dependency set rather than install `libxml2-dev` just to satisfy this optional feature.

The PS4 overlay now excludes `XSLT` from optional platform dependencies. No explicit `ENABLE_XSLT` cache override is used because Kodi models that option as an AUTO/string dependency switch; exclusion is the narrower platform-level adaptation.

Until the next configure-only validation succeeds:
- Native host tools: validated ✅
- Kodi PS4 cross-configuration entry: validated ✅
- Blu-ray/libbluray: intentionally disabled for bring-up ✅
- XSLT/libxslt: intentionally excluded for bring-up ✅
- CCache/ClangFormat warnings: non-blocking
- Full Kodi build: not started

## Next action

Synchronize the WSL checkout with origin/main and run:

    CONFIGURE_ONLY=1 ./scripts/build-ps4-kodi.sh

Verify that:
1. both native host tools remain available;
2. libbluray/LibXml2 and XSLT/LibXml2 are no longer entered into the dependency path;
3. Kodi proceeds to the next dependency or completes configuration;
4. the PS4 host/target boundary remains intact.

If configuration reveals a new blocker, document it and make that blocker the next focused step. Do not install a host package merely to satisfy a target dependency before checking whether the corresponding Kodi feature is needed for the bring-up profile.

## Major runtime risks

1. Kodi GLES renderer compatibility with PS4 Piglet's actual GLES 2.0/extension surface.
2. Kodi-compatible ownership/lifetime of hardware-decoded PS4 frames.
3. Efficient or zero-copy transfer of NV12/P010 decoder surfaces into the renderer.

No PS4 runtime/platform implementation is currently claimed as working.
