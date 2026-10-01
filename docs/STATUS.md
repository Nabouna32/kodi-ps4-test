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

The current blocker is the generated native CMake path used by Kodi's target dependency Makefiles: Kodi expects `x86_64-linux-gnu-native`, while our script exposed the compatibility path as `x86_64-pc-linux-gnu-native`. The durable fix belongs in `scripts/build-ps4-kodi.sh`, not in Kodi or the dependency recipe.

The architecture correction is already validated by WSL. The remaining authoritative validation is the native-prefix correction. The authoritative validation command is:

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
