# Kodi PS4 Port — Build and Toolchain

## Build architecture

The pinned Kodi submodule is never modified by the normal PS4 build workflow.

    references/kodi
        |
        | git archive HEAD
        v
    build/ps4/kodi-source
        |
        | apply repository-owned PS4 overlay
        v
    CMake configure/build

Generated build output lives under build/ and is ignored by Git.

## Host environment

Primary development is WSL2/Linux.

Validated environment:
- Ubuntu 26.04.1 LTS
- Clang/Clang++ 21.1.8
- LLD 21.1.8
- CMake 4.2.3
- Ninja 1.13.2
- Meson 1.10.1
- pkg-config 2.5.1
- OpenOrbis PS4 toolchain

The shell exposes LLVM 21 and OpenOrbis through PATH. The repository toolchain intentionally uses command names rather than hard-coding an Ubuntu LLVM path.

## OpenOrbis validation

Validated chain:

    Clang 21
      -> x86_64-pc-freebsd12-elf
      -> LLD + OpenOrbis link.x + crt1.o
      -> PS4-targeted ELF
      -> create-fself
      -> OELF + eboot.bin

This does not validate real PS4 execution, GP4/PKG generation, or the full Kodi build.

## Native dependency prefix

Kodi native build tools are separated from the PS4 target installation prefix.

Current native prefix:
    build/ps4/build/native

CMake already finds native flatc and JsonSchemaBuilder there.

## TexturePacker blocker

Kodi cross-configure reaches native flatc, native JsonSchemaBuilder and internal TexturePacker setup, then fails because TEXTUREPACKER_EXECUTABLE is missing.

The PS5 reference demonstrates the required host/target split: build TexturePacker natively, install it under the native prefix, and pass its location with WITH_TEXTUREPACKER. HOST_CAN_EXECUTE_TARGET must remain false.

The PS5 workflow is a reference for this build-system boundary only; PS5 packaging/platform changes must not be copied wholesale.

## Build workflow

scripts/build-ps4-kodi.sh:
1. validates OO_PS4_TOOLCHAIN;
2. materializes the pinned Kodi commit;
3. applies the PS4 overlay to the generated source tree;
4. configures Kodi with the PS4 toolchain;
5. builds with Ninja.

The next build-system change is the dedicated native TexturePacker bootstrap. Configure-only validation must pass before the full build is attempted.
