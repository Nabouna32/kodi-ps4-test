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

The first configure-only validation after the native TexturePacker audit did not reach CMake: WSL reported Permission denied when invoking ./scripts/build-ps4-kodi.sh. The repository mode was 100644 even though the file is an executable shell-script entry point.

The mode was corrected locally to 100755 and is now being committed to main. No Kodi build logic changed.

The previous Lzo2 blocker is resolved. This validation rebuilt and installed the native TexturePacker successfully, then reached Kodi's real PS4 cross-configuration. Kodi now stops because the native JsonSchemaBuilder executable is missing from the supplied native prefix.

The validated host-tool model now includes a concrete requirement for both host executables:
- TexturePacker is compiled for WSL/Linux;
- JsonSchemaBuilder must also be compiled for WSL/Linux;
- Kodi PS4 receives both through WITH_TEXTUREPACKER and WITH_JSONSCHEMABUILDER;
- HOST_CAN_EXECUTE_TARGET remains false;
- no PS4-target host build tools are built or shipped.

## Next action

The next implementation step is to extend the focused native host-tool bootstrap to build Kodi's official JsonSchemaBuilder source alongside TexturePacker. The PS5 reference independently uses this exact two-tool host model, while official Kodi's FindJsonSchemaBuilder.cmake confirms that WITH_JSONSCHEMABUILDER expects an existing executable during cross-compilation.

After that implementation is validated, rerun:

    CONFIGURE_ONLY=1 ./scripts/build-ps4-kodi.sh

Do not start a full Kodi build until configuration succeeds.

## Major runtime risks

1. Kodi GLES renderer compatibility with PS4 Piglet's actual GLES 2.0/extension surface.
2. Kodi-compatible ownership/lifetime of hardware-decoded PS4 frames.
3. Efficient or zero-copy transfer of NV12/P010 decoder surfaces into the renderer.

No PS4 runtime/platform implementation is currently claimed as working.
