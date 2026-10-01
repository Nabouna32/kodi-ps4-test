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

## Latest validation result — host CMake bootstrap succeeded

The exact pinned Kodi CMake recipe was rerun unchanged after installing the WSL host development package `libcurl4-openssl-dev`. The bootstrap now completes successfully:

- CURL is found through the system installation (8.18.0);
- CMake configuration and generation complete;
- the native CMake root `Makefile` is present.

The previous host-CURL blocker is therefore resolved.

### Next action

Validate the explicit Kodi native dependency targets against the generated `x86_64-linux-gnu-native` prefix. The target set must cover the host tools needed by the cross-build (CMake, Ninja, Meson, Python, NASM, TexturePacker and JsonSchemaBuilder). Do not start the full Kodi build until this native-tool stage and the subsequent target HarfBuzz bootstrap are validated.


## Latest validation — 2026-10-01 native CMake bootstrap succeeded

The unchanged official Kodi native CMake bootstrap was rerun after installing the required WSL host package `libcurl4-openssl-dev`. It now succeeds: system CURL 8.18.0 is found, CMake completes configuration and generation, and the native CMake root `Makefile` is generated. The previous host-CURL blocker is resolved.

**Next action:** validate Kodi's explicit native dependency targets (CMake, Ninja, Meson, Python, NASM, TexturePacker and JsonSchemaBuilder) in the generated `x86_64-linux-gnu-native` prefix. Do not start the full Kodi build yet.



## Latest handoff — 2026-10-01 — PS4 Meson linker flag correction

The target HarfBuzz bootstrap reached Meson but failed during linker detection because the PS4 overlay generated:

    -fuse-ld=ld.lld

with the WSL Clang 21 toolchain, which reports that linker name as invalid for `-fuse-ld`. Direct inspection of pinned Kodi `tools/depends/configure.ac` confirmed that its generated `cross-file.meson` forwards `platform_ldflags` into Meson's `c_link_args` and `cpp_link_args`. The source of the bad flag was therefore our repository-owned PS4 overlay, not Meson itself.

The minimal correction was committed to `main`:

    943f8cbf895ffcf69743d73ff1ecb4ba300c2618

    fix: use lld driver for PS4 Meson linker

The PS4 overlay now uses:

    -fuse-ld=lld

while preserving the OpenOrbis PS4 target, `link.x`, sysroot, CRT and PS4 libraries unchanged.

The fix is implemented but **not yet runtime/build-validated on WSL**.

### Immediate next step

Run the configure-only build from a clean current `main` and inspect the generated native/target state. The critical verification is that the generated HarfBuzz cross-file contains `-fuse-ld=lld`, then Meson passes linker detection and HarfBuzz configuration/build proceeds.

Do not change any additional linker/toolchain flags unless this validation demonstrates a separate failure.


## Latest validation — 2026-10-01 — HarfBuzz reaches C++ compilation

The `-fuse-ld=lld` correction successfully moved the build past the previous Meson linker-detection blocker. HarfBuzz now starts compiling for:

    x86_64-pc-freebsd12-elf

The new blocker is the OpenOrbis C++/C math-header interface:

    include/c++/v1/cmath:341:9: error: no member named 'abs' in the global namespace

with OpenOrbis:

    include/math.h:295:13: note: 'fabs' declared here

The same error occurs across many HarfBuzz C++ translation units, so it is a shared target-header/toolchain compatibility issue rather than an individual HarfBuzz source failure.

OpenOrbis release history records previous fixes for BSD/MUSL header discrepancies and C++ `cmath` handling. Therefore the installed OpenOrbis toolchain revision must be established and compared against the upstream fixed state before introducing a Kodi-side workaround.

### Current blocker

OpenOrbis target header/libc++ compatibility.

No repository workaround has been implemented yet.

### Next action

Inspect the installed OpenOrbis revision and the exact `cmath` / `math.h` sections, then compare with OpenOrbis upstream/release sources. Do not modify Kodi or HarfBuzz until the root cause is established.


## Latest validation — 2026-10-01 — LLVM 18 installed for OpenOrbis v0.5.4 experiment

The current external target toolchain is OpenOrbis v0.5.4. The active build blocker remains the OpenOrbis C/C++ math-header interface:

    include/c++/v1/cmath:341:9: error: no member named 'abs' in the global namespace

The host was previously using LLVM/Clang/LLD 21.1.8. LLVM/Clang/LLD 18.1.8 has now been installed in parallel through Ubuntu packages. Installation was verified successfully.

This does not yet prove that LLVM 18 fixes the blocker. LLVM 18 is the next controlled experiment; LLVM 21 remains installed and the repository has not been changed to pin either version.

### Immediate next action

Use LLVM 18 explicitly for one clean configure-only run by placing /usr/lib/llvm-18/bin before the existing OpenOrbis path in PATH. First verify that generic clang, clang++, llvm-ar, llvm-ranlib and ld.lld resolve to LLVM 18. Then run the existing CONFIGURE_ONLY=1 ./scripts/build-ps4-kodi.sh workflow.

Do not modify Kodi, HarfBuzz, the OpenOrbis headers, or the repository toolchain file before this experiment produces a result.

## Latest validation — 2026-10-01 — LLVM 18 does not resolve the HarfBuzz header blocker

The controlled LLVM 18 compatibility experiment has now been executed with:

    /usr/lib/llvm-18/bin/clang++
    Ubuntu Clang/LLD 18.1.8

The build still fails at exactly the same shared target-header boundary:

    OpenOrbis/include/c++/v1/cmath:341:9
    error: no member named 'abs' in the global namespace; did you mean 'fabs'?

The compiler still points at OpenOrbis:

    OpenOrbis/include/math.h:295:13
    note: 'fabs' declared here

The failure occurs across many HarfBuzz C++ translation units and the build stops in the official Kodi HarfBuzz target dependency.

### Conclusion

The hypothesis that LLVM 21 alone was incompatible with the OpenOrbis v0.5.4 C++ headers is not supported by this experiment. LLVM 18 reproduces the same failure.

Therefore:
- LLVM 18 is not a fix for the current blocker;
- LLVM 21 remains installed and remains the validated standalone PS4 smoke-test compiler;
- the repository must not pin LLVM 18 based on this experiment;
- no Kodi/HarfBuzz/OpenOrbis header patch has been introduced.

### Next action

Inspect the exact OpenOrbis v0.5.4 libc++/math header integration and compare the expected upstream OpenOrbis/LLVM configuration before modifying the repository. The next step remains diagnosis of the target header interface, not a workaround in HarfBuzz.

## Latest investigation — 2026-10-01 — OpenOrbis header root cause identified

The LLVM 18 experiment reproduced the same failure as LLVM 21, so the host LLVM version is not the sufficient cause.

Direct inspection of the OpenOrbis forked libc++ source identified the actual integration issue: the PS4 build currently puts the OpenOrbis C header directory before the OpenOrbis libc++ header directory.

Current order:

    -isystem $OO_PS4_TOOLCHAIN/include
    -isystem $OO_PS4_TOOLCHAIN/include/c++/v1

OpenOrbis libc++ cmath includes <math.h> and then performs using ::abs. OpenOrbis' libc++ math.h wrapper is designed to include the target C math.h with #include_next and includes <stdlib.h> for C++, which supplies abs.

With the current search order, <math.h> resolves directly to the target C header and bypasses the libc++ wrapper. The target C header exposes fabs but not the required global abs, producing the observed error.

### Current status

Root cause identified, repository fix not yet applied.

### Next action

Validate the hypothesis with a minimal standalone <cmath> compile using the current include order and then the corrected order. Do not modify HarfBuzz or OpenOrbis headers. If the corrected order compiles, change only the PS4 C++ include ordering and rerun the configure-only Kodi build.

## Latest validation — 2026-10-01 — OpenOrbis C++ header order confirmed

The minimal standalone cross-compilation test confirmed the exact root cause of the HarfBuzz failure:

- SDK C headers first reproduces the `cmath` / global `abs` error.
- OpenOrbis libc++ headers first compiles the same test successfully.

The blocker is therefore a repository/toolchain integration include-order issue. No repository source has been changed for it yet.

**Next step:** inspect the repository's generated target C++ flags and make the smallest justified ordering correction, then rerun the configure-only validation. Do not patch HarfBuzz or OpenOrbis headers.

## Latest implementation — 2026-10-01 — C++ header ordering corrected

The experimentally validated OpenOrbis libc++ include-order fix is now implemented in:

- `overlay/tools/depends/0001-openorbis-ps4-target-depends.patch`
- `cmake/toolchains/openorbis-ps4-kodi.cmake`

Both changes are one-line ordering corrections. The standalone test already proved the ordering itself; the remaining validation is the real Kodi configure-only workflow.

Do not start a full Kodi build until that configure-only run is evaluated.
