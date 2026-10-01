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

The required native host tools were previously validated:
- TexturePacker: installed and accepted by Kodi
- JsonSchemaBuilder: installed as `JsonSchemaBuilder`, which the pinned Kodi finder accepts

The orchestration has now been corrected to use Kodi's official native dependency graph and generated native prefix instead of the project-specific `build/native` bootstrap. This implementation change is not yet WSL-validated.

Kodi reaches and completes the real PS4 cross-configuration, with `Cross-Compiling: TRUE`, `System type: FreeBSD`, `Core system type: ps4`, and `ARCH x86_64-ps4`.

The earlier configure blocker was libbluray: Kodi's optional `Bluray` dependency attempted to find target LibXml2 while configuring the internal libbluray build. Blu-ray playback is not required for the first bring-up milestone (Kodi GUI + GLES + PS4 controller), so the durable correction is to disable Blu-ray in the PS4 bring-up profile rather than install an unrelated host dependency.

The PS4 overlay now explicitly excludes Bluray from optional platform dependencies and forces `ENABLE_BLURAY=OFF`.

The following configure run then reached Kodi's optional `XSLT` dependency and failed through its internal libxslt path because LibXml2 was unavailable. The pinned Kodi source confirms that XSLT is listed under `optional_deps`, while its internal build path requires LibXml2. XSLT is not required for the first bring-up milestone, so the durable correction is to exclude `XSLT` from the PS4 optional dependency set rather than install `libxml2-dev` just to satisfy this optional feature.

The PS4 overlay now excludes `XSLT` from optional platform dependencies. No explicit `ENABLE_XSLT` cache override is used because Kodi models that option as an AUTO/string dependency switch; exclusion is the narrower platform-level adaptation.

The next configure blocker was target-side HarfBuzz while configuring required ASS/libass. At the pinned Kodi commit, ASS and HarfBuzz are required dependencies, so this blocker cannot be handled by disabling an optional feature. Kodi's `FindHarfBuzz.cmake` expects a target HarfBuzz installation in the dependency prefix; the official Kodi `tools/depends/target/harfbuzz` recipe builds HarfBuzz 14.2.0 statically with Meson for the target. The PS5 reference uses the same architectural concept through its target sysroot/pacbrew dependency set, but its PS5 libraries cannot be reused for PS4.

Do not install Ubuntu `libharfbuzz-dev`: that would provide a host Linux library, not the missing PS4 target library.

Until the next configure-only validation succeeds:
- Native host tools: validated ✅
- Kodi PS4 cross-configuration entry: validated ✅
- Blu-ray/libbluray: intentionally disabled for bring-up ✅
- XSLT/libxslt: intentionally excluded for bring-up ✅
- CCache/ClangFormat warnings: non-blocking
- Full Kodi build: not started

## Next action

The exact pinned Kodi source remains at commit `9c3e7f4d7b3ff314cd2f19a291766555e0346024`. The repository-owned overlay now gets through Kodi's platform and target-architecture checks, and the latest WSL run confirmed that the `tools/depends` configure phase completes.

The build orchestration now uses Kodi's generated `x86_64-linux-gnu-native` prefix and invokes the official native dependency graph before building the target HarfBuzz dependency. This replaces the previous custom `build/native` bootstrap and removes the incorrect compatibility-prefix approach.

The authoritative validation command is:

```bash
cd ~/projects/kodi-ps4-test
git fetch origin
git reset --hard origin/main
export OO_PS4_TOOLCHAIN="$HOME/opt/OpenOrbis/PS4Toolchain"
export PATH="/usr/lib/llvm-21/bin:$OO_PS4_TOOLCHAIN/bin/linux:$PATH"
CONFIGURE_ONLY=1 ./scripts/build-ps4-kodi.sh
```

Do not start a full Kodi build until configure succeeds. If a new blocker appears, diagnose it before changing the dependency surface.


## Major runtime risks

1. Kodi GLES renderer compatibility with PS4 Piglet's actual GLES 2.0/extension surface.
2. Kodi-compatible ownership/lifetime of hardware-decoded PS4 frames.
3. Efficient or zero-copy transfer of NV12/P010 decoder surfaces into the renderer.

No PS4 runtime/platform implementation is currently claimed as working.

## HarfBuzz implementation phase

The PS4 overlay extends Kodi's `tools/depends/configure.ac` for the Autoconf host `x86_64-pc-freebsd12` / `--with-platform=ps4`, while the generated target toolchain passes the OpenOrbis LLVM target `x86_64-pc-freebsd12-elf`. The build script bootstraps that generated configure system, builds only the official target dependency path needed by HarfBuzz (`freetype2-noharfbuzz` → HarfBuzz), and passes the resulting target prefix to Kodi CMake through `DEPENDS_PATH`. Host Meson/Ninja/pkg-config/Python/CMake are exposed through the existing native prefix rather than rebuilt as new project-specific tools.

This remains an implementation-only phase until the WSL configure-only run successfully applies the overlay and reaches the target dependency bootstrap.
## Latest validation result — host CMake bootstrap

The previous native CMake bootstrap failure has been root-caused.

The pinned Kodi CMake recipe invokes `./bootstrap --system-curl`. Direct reproduction showed that the bootstrap reached its initial configuration and then stopped because the WSL host did not provide the libcurl development files:

    CMAKE_USE_SYSTEM_CURL is ON but a curl is not found!

This is a normal **host Linux dependency**. It does not indicate a PS4/OpenOrbis problem and does not weaken the host/target separation.

WSL remediation completed:
- `libcurl4-openssl-dev` installed;
- `pkg-config` resolves libcurl 8.18.0;
- `-lcurl` and the multiarch development include path are available.

### Current blocker

**Native CMake bootstrap has not yet been re-run after installing libcurl development files.**

The next step is only to rerun the official CMake bootstrap and verify that the root `Makefile` is generated. Do not start the complete Kodi build yet.

If CMake bootstraps successfully, the following step will validate/build the explicitly required Kodi native tools. An earlier Makefile inspection established that `make native JsonSchemaBuilder` does not mean “build every native tool”; the native targets for CMake, Ninja, Meson, Python, TexturePacker and JsonSchemaBuilder must be requested according to Kodi's actual dependency graph rather than assumed from the aggregate target name.
\n## Latest validation result — host CMake bootstrap succeeded\n\nThe exact pinned Kodi CMake recipe was rerun unchanged after installing the WSL host development package `libcurl4-openssl-dev`. The bootstrap now completes successfully:\n\n- CURL is found through the system installation (8.18.0);\n- CMake configuration and generation complete;\n- the native CMake root `Makefile` is present.\n\nThe previous host-CURL blocker is therefore resolved.\n\n### Next action\n\nValidate the explicit Kodi native dependency targets against the generated `x86_64-linux-gnu-native` prefix. The target set must cover the host tools needed by the cross-build (CMake, Ninja, Meson, Python, NASM, TexturePacker and JsonSchemaBuilder). Do not start the full Kodi build until this native-tool stage and the subsequent target HarfBuzz bootstrap are validated.\n