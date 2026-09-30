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

## Native host tools

Kodi native build tools are **host tools**. For the PS4 cross-build they must be compiled for WSL/Linux and made available before Kodi's target configuration/build uses them.

The repository builds the currently required Kodi host tools from the pinned source with the normal WSL host compiler:
- TexturePacker
- JsonSchemaBuilder

They are installed into:

    build/ps4/build/native/bin/

The PS4 configure receives that directory through:
- WITH_TEXTUREPACKER
- WITH_JSONSCHEMABUILDER

The host/target boundary remains explicit: HOST_CAN_EXECUTE_TARGET is false, and no PS4-target host tools are built or shipped.

### TexturePacker

TexturePacker is built from:

    tools/depends/native/TexturePacker/src

and installs as:

    build/ps4/build/native/bin/TexturePacker

Its WSL host dependencies are:
- liblzo2-dev
- libpng-dev
- libgif-dev
- libjpeg-dev

These are host dependencies, not PS4 target dependencies.

### JsonSchemaBuilder

JsonSchemaBuilder is built from:

    tools/depends/native/JsonSchemaBuilder/src

with APP_NAME_LC=kodi, so Kodi installs:

    build/ps4/build/native/bin/kodi-JsonSchemaBuilder

This is the executable expected by the pinned Kodi FindJsonSchemaBuilder.cmake during cross-compilation.

### Shared bootstrap

The focused bootstrap is:

    scripts/build-ps4-native-host-tools.sh

It uses:
- the pinned Kodi source tree;
- WSL host /usr/bin/cc and /usr/bin/c++;
- Ninja;
- KODI_SOURCE_DIR;
- APP_NAME_LC=kodi;
- ARCH_DEFINES=-DTARGET_POSIX;-DTARGET_LINUX;-D_GNU_SOURCE.

It intentionally does not bootstrap Kodi's full native dependency graph or vendor host libraries.

The previous specialized TexturePacker-only helper has been removed.

## Build workflow

scripts/build-ps4-kodi.sh:
1. validates OO_PS4_TOOLCHAIN;
2. materializes the pinned Kodi commit;
3. applies the PS4 overlay to the generated source tree;
4. configures Kodi with the PS4 toolchain;
5. builds with Ninja.

The native host-tools bootstrap is now shared by TexturePacker and JsonSchemaBuilder. The implementation is committed to main; WSL configure-only validation is still required. Do not start the full Kodi build until configuration succeeds.

## Native TexturePacker mechanism audit

The pinned Kodi source provides two levels of native-tool support. The complete `tools/depends/native/Makefile` builds TexturePacker as part of Kodi's native dependency graph and expects a configured `NATIVEPREFIX/share/config.site`. The dedicated TexturePacker Makefile then invokes the official TexturePacker CMake project with the host-build variables.

For the PS4 cross-build we currently use the latter CMake project directly, matching the focused host-tool strategy used by the PS5 reference. This is not a replacement implementation: the source remains Kodi's own `tools/depends/native/TexturePacker/src`. The choice avoids bootstrapping Kodi's entire native-dependency graph just to obtain one host executable. The decision is revisitable if the broader Kodi depends/cmakebuildsys path later becomes necessary for additional native tools.
