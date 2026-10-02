# Kodi PS4 Port — Current Status

Repository: `Nabouna32/kodi-ps4-test`
Current branch: `main`
Current `main` state must be verified independently from `origin/main` at startup.
Primary environment: WSL2/Linux
Phase: build/toolchain validation / minimal bring-up

## Verified state

- Official Kodi is the upstream base.
- Kodi pin: `9c3e7f4d7b3ff314cd2f19a291766555e0346024`.
- PS5 reference pin: `0ea36e36d738aa045c1b8ed63c24a0314c7f72a5`.
- `references/kodi` remains immutable.
- The build materializes Kodi into `build/ps4/kodi-source` before applying the repository-owned PS4 overlay.
- OpenOrbis + LLVM/LLD 21.1.8 can compile, link and FSELF-package a minimal PS4 executable under WSL2.
- That smoke test does not validate Kodi or actual PS4 runtime execution.
- Initial runtime milestone: Kodi GUI + GLES/EGL presentation + PS4 controller input.
- Graphics direction: GLES/EGL/Piglet first; Vulkan/OpenGNM later.

## Build/toolchain facts

- OpenOrbis: `$HOME/opt/OpenOrbis/PS4Toolchain`.
- Target triple: `x86_64-pc-freebsd12-elf`.
- Native prefix: `build/ps4/build/x86_64-linux-gnu-native`.
- PS4 target prefix: `build/ps4/build/x86_64-pc-freebsd12-release`.
- C++ flags put OpenOrbis libc++ headers before SDK C headers.
- C flags explicitly expose the OpenOrbis SDK C include directory.
- Target pkg-config is restricted to target `lib/pkgconfig` and `libdata/pkgconfig`.

## Dependency state

- Blu-ray/libbluray and XSLT/libxslt are excluded for the initial bring-up.
- HarfBuzz, FriBidi and Fontconfig are staged as required ASS/libass target dependencies.
- The repository-owned zlib recipe adds only `-DZLIB_BUILD_TESTING=OFF`; the target zlib library remains enabled.
- The Iconv issue was classified as CMake/OpenOrbis C-header visibility, not a missing libiconv dependency.
- LLVM 18 was tested against the OpenOrbis `cmath` issue and did not resolve it; no LLVM pin was introduced.

## Current implementation

`scripts/build-ps4-kodi.sh` now:

1. materializes pinned Kodi;
2. applies the PS4 overlay and target-dependency patch;
3. bootstraps/configures Kodi `tools/depends`;
4. builds Kodi native dependencies;
5. builds native `JsonSchemaBuilder`;
6. verifies native tools;
7. stages `fribidi harfbuzz fontconfig`;
8. configures Kodi with the OpenOrbis toolchain.

The Fontconfig/zlib changes are implemented but have not yet been validated by a fresh WSL configure-only run from the recovered current state.

## Current blocker / boundary

The latest configure-only run progressed through the OpenSSL OpenOrbis-specific patches and then stopped in OpenSSL 3.5.7 at `providers/implementations/rands/seeding/rand_unix.c` because OpenOrbis does not provide `sys/sysctl.h`. The next investigation is to compare the FreeBSD random-seeding path against current OpenOrbis and the pinned public `references/ps4sdk` evidence.

`references/ps4sdk` is now available as a historical/public PS4 reference. It is not used by the build.

## Next action

For current `main`:

```bash
cd ~/projects/kodi-ps4-test
git fetch origin
git switch main
git reset --hard origin/main
export OO_PS4_TOOLCHAIN="$HOME/opt/OpenOrbis/PS4Toolchain"
export PATH="/usr/lib/llvm-21/bin:$OO_PS4_TOOLCHAIN/bin/linux:$PATH"
CONFIGURE_ONLY=1 ./scripts/build-ps4-kodi.sh
```

For a future approved change, switch to its task branch before local validation.

Do not start a full Kodi build until configure-only succeeds.

## Validation levels

- Local WSL: current interactive OpenOrbis validation environment.
- GitHub-hosted CI: not a reproduction of the OpenOrbis environment yet.
- Self-hosted OpenOrbis runner: planned.
- PS4 runtime: separate and not yet validated.


## Randomness blocker investigation

The sys/sysctl.h failure is now classified as a FreeBSD compatibility-path mismatch, not yet as a missing header that should be copied from the historical PS4SDK.

OpenSSL 3.5.7 can use sysctl(KERN_ARND) on the FreeBSD path, but OpenOrbis exposes no indexed sys/random.h, getrandom() or getentropy() interface. OpenOrbis does declare sceRandomGetRandomNumber, although the checked-in prototype is incomplete. Historical ps4dev/ps4sdk provides sysctl.h/KERN_ARND and syscall metadata, but is too old to prove current OpenOrbis support.

Current implementation boundary: no compatibility header has been copied and OpenSSL has not yet been modified to use the native SCE random API.
