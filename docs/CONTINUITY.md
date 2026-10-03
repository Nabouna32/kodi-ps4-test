# Kodi PS4 — Continuity / Handoff

This is the compact cross-conversation handoff. GitHub and checked-in files are the source of truth; this document must be independently verified at every startup.

## Mandatory startup

Read, in order:

1. `AGENTS.md`
2. `docs/WORKFLOW.md`
3. `docs/CONTINUITY.md`
4. `docs/STATUS.md`
5. `docs/BUILD.md`
6. other documentation relevant to the task

Then independently verify current `origin/main`, pinned submodules, relevant source/configuration, and the documented state before proposing work.

Normal work uses a branch and PR. Never commit directly to `main`, and never merge without explicit user approval.

## Repository state

- `main` is the authoritative current repository state; verify `origin/main` independently at startup.
- Kodi pin: `9c3e7f4d7b3ff314cd2f19a291766555e0346024`.
- PS5 reference pin: `0ea36e36d738aa045c1b8ed63c24a0314c7f72a5`.
- `references/kodi/` is immutable.
- `references/kodi-ps5/` is a technical reference only.
- `references/ps4sdk/` is a historical/public PS4 technical reference only, pinned to `4df9d001b66ae4ec07d9a51b62d1e4c5e270eecc`.

## Project direction

- Base: official Kodi with a repository-owned PS4 overlay/toolchain.
- Initial runtime milestone: Kodi GUI + GLES/EGL presentation + PS4 controller input.
- Graphics: GLES/EGL/Piglet first; Vulkan/OpenGNM later.
- PS5 code is evidence, not proof of PS4 compatibility.
- No proprietary Sony SDK artifacts, dumps or binaries.
- Host Linux and PS4 target dependencies remain strictly separated.
- Self-hosted OpenOrbis CI is planned; actual PS4 runtime validation remains separate.

## Current build architecture

`scripts/build-ps4-kodi.sh`:

1. materializes pinned Kodi;
2. applies repository-owned overlays;
3. bootstraps/configures Kodi `tools/depends`;
4. builds the official native dependency graph;
5. builds native `JsonSchemaBuilder`;
6. verifies native tools;
7. stages target `fribidi`, `harfbuzz`, and `fontconfig`;
8. runs the Kodi PS4 CMake configure;
9. optionally stops with `CONFIGURE_ONLY=1`.

Native tools: `build/ps4/build/x86_64-linux-gnu-native`.

PS4 target dependencies: `build/ps4/build/x86_64-pc-freebsd12-release`.

## Validated toolchain constraints

- Target triple: `x86_64-pc-freebsd12-elf`.
- OpenOrbis sysroot and `link.x` are used for PS4.
- Validated Meson linker spelling: `-fuse-ld=lld`.
- C++ target headers: OpenOrbis libc++ first, then SDK C headers.
- C target flags explicitly expose the OpenOrbis SDK C include directory.
- Target pkg-config is limited to the PS4 dependency prefix.

## Dependency state

- Blu-ray and XSLT are intentionally excluded from initial bring-up.
- HarfBuzz, FriBidi and Fontconfig are target dependencies for the current ASS/libass path.
- zlib is built with `-DZLIB_BUILD_TESTING=OFF`; the target library remains enabled.
- Iconv detection was fixed as a CMake/OpenOrbis C-header visibility issue; no libiconv dependency was added.
- LLVM 18 did not resolve the OpenOrbis `cmath`/global-`abs` issue; no LLVM pin was introduced.

## Current validation boundary

The latest configure-only run completed OpenSSL 3.5.7 and then stopped at Kodi's FFmpeg discovery because the target prefix did not yet contain FFmpeg. The repository now stages FFmpeg 9.0.2 through the official Kodi target dependency recipe. Fresh WSL validation of that target build is pending.

Do not start a full Kodi build before configure-only succeeds.

## Current blocker

FFmpeg 9.0.2 is now the active build boundary. No OpenOrbis-specific FFmpeg incompatibility has yet been observed, so no FFmpeg source adaptation is justified at this point.

## Exact next action

Validate the approved implementation branch `fix/ps4-cmake-dependency-root`:

```bash
cd ~/projects/kodi-ps4-test
git fetch origin
git switch fix/ps4-cmake-dependency-root
git pull --ff-only
export OO_PS4_TOOLCHAIN="$HOME/opt/OpenOrbis/PS4Toolchain"
export PATH="/usr/lib/llvm-21/bin:$OO_PS4_TOOLCHAIN/bin/linux:$PATH"
CONFIGURE_ONLY=1 ./scripts/build-ps4-kodi.sh
```

When validating an approved implementation branch, switch to that branch before running the test and report the branch explicitly.

Keep this file concise: Git history contains chronology; this file contains only the current handoff.


## Randomness investigation result

The OpenSSL blocker was a FreeBSD compatibility-path mismatch. OpenSSL 3.5.7 selects `sysctl(KERN_ARND)` on older FreeBSD paths and `getrandom()` on sufficiently new FreeBSD paths. Current OpenOrbis v0.5.4 actually provides `<sys/random.h>` with `getrandom(void *, size_t, unsigned)` and the symbol is linkable with the same PS4 target linkage used by Kodi.

The historical references/ps4sdk contains sys/sysctl.h, KERN_ARND, and SYS___sysctl, but it is a 2017 reference and does not expose sceRandomGetRandomNumber. Therefore we must not copy its header merely to make OpenSSL compile.



## Current FFmpeg blocker

The latest verified configure-only run completed the repository-owned OpenSSL 3.5.7 build, then stopped because the target prefix did not contain a suitable FFmpeg installation. The pinned Kodi revision requires FFmpeg 9.0.2 for the depends-build path.

Source inspection of the pinned Kodi `tools/depends/target/ffmpeg` shows an official cross-compilation recipe using FFmpeg 9.0.2, the existing target toolchain, target pkg-config, NASM, and the repository's three Kodi FFmpeg source patches. The clean next implementation is therefore to stage `ffmpeg` through Kodi's target dependency Makefile before top-level CMake configuration.

Implementation: `scripts/build-ps4-kodi.sh` now builds `fribidi harfbuzz fontconfig ffmpeg` before Brotli/OpenSSL and Kodi CMake configuration.

Validation status: implementation committed on `fix/ps4-cmake-dependency-root`; fresh WSL validation of the FFmpeg target build is still pending.

Do not force `ENABLE_INTERNAL_FFMPEG=ON` as a workaround. If the official FFmpeg recipe fails on an OpenOrbis-specific incompatibility, investigate that concrete failure as the next scoped adaptation.
\n\nThe first post-implementation validation showed that FFmpeg was not actually invoked. Exact pinned Kodi source inspection explains why: `tools/depends/target/Makefile` adds `dav1d ffmpeg` only inside the `OS=linux` block. PS4 uses `OS=freebsd`, so an explicit `make ... ffmpeg` could resolve without invoking the directory recipe. The repository now adds `dav1d ffmpeg` to `DEPENDS` only when `TARGET_PLATFORM=ps4`, through a dry-run-validated overlay patch. This keeps Linux/other FreeBSD behavior unchanged.

Next validation: rerun `CONFIGURE_ONLY=1 ./scripts/build-ps4-kodi.sh`. The expected new boundary is actual dav1d/FFmpeg configuration or compilation; any failure there is the next concrete blocker.\n