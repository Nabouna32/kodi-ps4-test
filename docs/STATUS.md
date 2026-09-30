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

The HarfBuzz dependency integration is implemented in the PS4 build overlay, but it has not yet been executed successfully in the WSL environment. Two consecutive WSL attempts stopped before target dependency configuration because the repository-owned unified-diff patch was malformed. The first correction fixed one set of hunk counts; the second WSL run exposed another malformed hunk around the Android/FreeBSD case boundary; inspection then found a third incorrect hunk count in `Toolchain.cmake.in`. The patch was rebuilt rather than incrementally patched. Direct inspection of the exact pinned Kodi source showed the previous version had inconsistent hunk positions and line counts. The new patch uses three exact insertion points with zero-context hunks, and an automated structural audit against the pinned source verified every hunk count. The resulting patch commit is `e991e0894016903f4d9713102306958814a67926`. The container environment could not execute `patch` because external DNS/network access is unavailable; WSL execution remains the authoritative validation.

No HarfBuzz build result has been obtained yet. The next validation must first confirm that the current patch applies cleanly, then observe the target dependency bootstrap. Do not install Ubuntu `libharfbuzz-dev` as a workaround.

The intended sequence is:
1. apply the corrected Kodi target-dependency patch;
2. initialize the smallest Kodi target-dependency environment needed by HarfBuzz;
3. build the official `freetype2-noharfbuzz` bootstrap dependency and HarfBuzz for the PS4 target;
4. stage the resulting static library, headers and pkg-config/CMake metadata in the target dependency prefix already searched by Kodi;
5. rerun `CONFIGURE_ONLY=1` and verify that HarfBuzz is discovered as a PS4 target library;
6. stop again at the next blocker rather than broadening the dependency surface.

## Major runtime risks

1. Kodi GLES renderer compatibility with PS4 Piglet's actual GLES 2.0/extension surface.
2. Kodi-compatible ownership/lifetime of hardware-decoded PS4 frames.
3. Efficient or zero-copy transfer of NV12/P010 decoder surfaces into the renderer.

No PS4 runtime/platform implementation is currently claimed as working.

## HarfBuzz implementation phase

The PS4 overlay extends Kodi's `tools/depends/configure.ac` for the Autoconf host `x86_64-pc-freebsd12` / `--with-platform=ps4`, while the generated target toolchain passes the OpenOrbis LLVM target `x86_64-pc-freebsd12-elf`. The build script bootstraps that generated configure system, builds only the official target dependency path needed by HarfBuzz (`freetype2-noharfbuzz` → HarfBuzz), and passes the resulting target prefix to Kodi CMake through `DEPENDS_PATH`. Host Meson/Ninja/pkg-config/Python/CMake are exposed through the existing native prefix rather than rebuilt as new project-specific tools.

This remains an implementation-only phase until the WSL configure-only run successfully applies the overlay and reaches the target dependency bootstrap.
