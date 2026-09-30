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

## Native TexturePacker host tool

TexturePacker is a **host build tool**. For the PS4 cross-build it must be compiled for WSL/Linux and available as a host executable before Kodi's target configuration/build uses it.

The repository builds Kodi's pinned TexturePacker source with the normal WSL host compiler and installs the resulting executable into:

    build/ps4/build/native/bin/TexturePacker

The PS4 configure receives that host tool through `WITH_TEXTUREPACKER`. `HOST_CAN_EXECUTE_TARGET` remains false, and `INTERNAL_TEXTUREPACKER_INSTALLABLE=FALSE` prevents Kodi from trying to build/package a target-side TexturePacker.

This is intentionally limited to the host/target build boundary. No PS5 platform code is copied for this purpose.

### Host dependencies

The TexturePacker host build uses the normal Ubuntu development packages for the libraries required by the pinned Kodi source:

- `liblzo2-dev`
- `libpng-dev`
- `libgif-dev`
- `libjpeg-dev`

These are **WSL host dependencies**, not PS4 target dependencies. No project-local replacement or dependency workaround is used for them.

The packages were installed and verified on the current Ubuntu 26.04.1 WSL environment on 2026-10-01:

    libgif-dev:amd64        5.2.2-1ubuntu3.2
    libjpeg-dev:amd64       8c-2ubuntu12
    liblzo2-dev:amd64       2.10-3build2
    libpng-dev:amd64        1.6.57-1

The actual TexturePacker build and subsequent Kodi configure still require validation after these packages are installed.

## Build workflow

scripts/build-ps4-kodi.sh:
1. validates OO_PS4_TOOLCHAIN;
2. materializes the pinned Kodi commit;
3. applies the PS4 overlay to the generated source tree;
4. configures Kodi with the PS4 toolchain;
5. builds with Ninja.

The next build-system change is the dedicated native TexturePacker bootstrap. Configure-only validation must pass before the full build is attempted.


Native TexturePacker bootstrap

The PS4 build now materializes Kodi first, then builds Kodi's TexturePacker source natively with the WSL host compiler (/usr/bin/cc and /usr/bin/c++). The tool is installed into the existing native prefix at build/ps4/build/native/bin/TexturePacker. The cross-configure receives WITH_TEXTUREPACKER and WITH_JSONSCHEMABUILDER from that same prefix and explicitly sets INTERNAL_TEXTUREPACKER_INSTALLABLE=FALSE so a PS4-target TexturePacker is not built or shipped. This follows Kodi's actual FindTexturePacker host/target boundary and the PS5 reference without copying PS5-specific platform code.

The implementation has been committed to main, but configure-only validation on the WSL checkout is still required. The next local test must start by synchronizing with origin/main, then run scripts/build-ps4-kodi.sh far enough to observe native TexturePacker configuration and Kodi cross-configuration.
