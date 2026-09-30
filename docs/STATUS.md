# Kodi PS4 Port — Current Status

Repository: Nabouna32/kodi-ps4-test
Branch: main
Primary development environment: WSL2/Linux
Current phase: build/toolchain validation

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

The JsonSchemaBuilder blocker is addressed in the build scripts: the native host-tools bootstrap now builds both TexturePacker and JsonSchemaBuilder from the pinned Kodi source and installs them into the shared native prefix.

The implementation has **not yet been validated in the WSL checkout**. Until configure-only validation runs successfully:
- TexturePacker: previously validated ✅
- JsonSchemaBuilder: implementation added, validation pending ⏳
- Kodi PS4 cross-configuration: previous blocker was JsonSchemaBuilder
- CCache/ClangFormat warnings: non-blocking at this stage
- Do not start a full Kodi build until configure succeeds.

## Next action

Synchronize the WSL checkout with origin/main and run:

    CONFIGURE_ONLY=1 ./scripts/build-ps4-kodi.sh

Verify that:
1. both native host tools build and install;
2. Kodi accepts both supplied host executables;
3. PS4 configuration completes successfully.

If configuration reveals a new blocker, document it and make it the next focused step.

## Major runtime risks

1. Kodi GLES renderer compatibility with PS4 Piglet's actual GLES 2.0/extension surface.
2. Kodi-compatible ownership/lifetime of hardware-decoded PS4 frames.
3. Efficient or zero-copy transfer of NV12/P010 decoder surfaces into the renderer.

No PS4 runtime/platform implementation is currently claimed as working.
