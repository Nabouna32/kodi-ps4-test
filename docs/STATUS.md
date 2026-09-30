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

## Current blocker

The previous configure attempt stopped while configuring the native TexturePacker host tool because Lzo2 was not installed on the WSL host.

That host dependency is now installed. The next validation must rebuild the native TexturePacker and continue into Kodi cross-configuration.

The intended model remains:
- TexturePacker is compiled for WSL/Linux;
- Kodi PS4 receives it through `WITH_TEXTUREPACKER`;
- `HOST_CAN_EXECUTE_TARGET` remains false;
- no PS4-target TexturePacker is built or shipped.

## Next action

Synchronize the checkout with `origin/main`, rerun:

    CONFIGURE_ONLY=1 ./scripts/build-ps4-kodi.sh

Then record the first real result. Do not start a full Kodi build until configuration succeeds.

## Major runtime risks

1. Kodi GLES renderer compatibility with PS4 Piglet's actual GLES 2.0/extension surface.
2. Kodi-compatible ownership/lifetime of hardware-decoded PS4 frames.
3. Efficient or zero-copy transfer of NV12/P010 decoder surfaces into the renderer.

No PS4 runtime/platform implementation is currently claimed as working.
