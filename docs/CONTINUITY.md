# Kodi PS4 — Continuity / Handoff

> Durable handoff for resuming the Kodi PS4 port in a new conversation. GitHub and the repository are the source of truth; this document is continuity context, not a substitute for inspecting the repo.

## New-conversation prompt

You are taking over the **Kodi PS4 port** in `Nabouna32/kodi-ps4-test`.

Read `docs/CONTINUITY.md` first, then verify everything against the real GitHub repository.

### Working rules

- GitHub/repository state is the source of truth for implementation state.
- Work directly on `main` for normal work; no feature branches/PRs unless explicitly requested.
- Before intervention: inspect current `main`, `AGENTS.md`, relevant docs, and actual code.
- Keep documentation updated after every meaningful discovery, decision, implementation, validation, blocker, correction, and next-action change.
- One step at a time: objective → analysis → validation for important decisions → implementation → tests → related fixes → docs → diff audit → commit → push → verification.
- Never silently broaden scope.
- Challenge fragile approaches; prefer root-cause, maintainable solutions.
- Never claim a PS4 component works without real validation.
- No proprietary Sony SDKs, dumps, binaries, or other non-public artifacts.
- Keep host Linux and PS4 target boundaries explicit. `HOST_CAN_EXECUTE_TARGET=FALSE` remains mandatory.
- Porting research methodology is mandatory:
  **official Kodi → PS5 reference → PS4/OpenOrbis evidence → explicit comparison → minimal PS4 adaptation → validation**.
- Prefer online inspection of Kodi/PS5/OpenOrbis repositories over large local inspection commands.
- Commands given for local execution should normally begin with:

```bash
cd ~/projects/kodi-ps4-test

echo "=== SYNC LOCAL WITH GITHUB ==="
git status --short --branch
git fetch origin
git reset --hard origin/main

echo
echo "=== VERIFY ==="
git status --short --branch
git log --oneline -5
```

Do not blindly delete untracked `build/` data or submodule working trees.

When an implementation is completed: update docs, inspect diff, commit, push, and verify GitHub. Do not consider a required validation complete while it is still running.

## Project objective

Port **official Kodi** to PS4 homebrew using public OpenOrbis/GoldHEN-compatible technology.

Architecture target: official Kodi + minimal PS4 adaptation. `references/kodi-ps5` is a technical reference, not a source to copy wholesale.

Planned progression:
1. process startup
2. Kodi initialization
3. graphics
4. controller
5. audio
6. filesystem/network
7. video
8. optimization

Initial graphics direction:
`Kodi GLES renderer → EGL/GLES2 → Piglet → PS4 VideoOut`

Vulkan/OpenGNM is later, not the first target.

Video target:
`CDVDVideoCodecPS4 → PS4 decoder API → CVideoBufferPS4 → renderer`

## Documentation

Current structure:

```text
docs/
├── README.md
├── STATUS.md
├── DECISIONS.md
├── BUILD.md
├── ARCHITECTURE.md
├── RESEARCH.md
├── PORTING.md
└── CONTINUITY.md
```

Responsibilities:
- `STATUS.md`: validated state, blockers, next action.
- `BUILD.md`: WSL/OpenOrbis/LLVM/CMake/Ninja/build system/host tools.
- `RESEARCH.md`: external evidence, experiments, open questions.
- `DECISIONS.md`: durable decisions.
- `ARCHITECTURE.md`: platform/graphics/video architecture.
- `PORTING.md`: compact continuity index.
- `CONTINUITY.md`: handoff for a new conversation.

The systematic research rule was formalized in commit:
`003bfcc1bf5974810ee2598f0483353d88f02c27`.

## Current repository / Kodi state

Repository: `Nabouna32/kodi-ps4-test`  
Branch: `main`  
Current main HEAD at this handoff preparation: `5b134fdb932443377d8309e830dc7e853f1085f2` (`chore: remove obsolete native host bootstrap`). Always verify the current GitHub HEAD before relying on historical hashes.

Known pinned Kodi submodule commit:
`9c3e7f4d7b3ff314cd2f19a291766555e0346024`

Known pinned PS5 reference commit:
`0ea36e36d738aa045c1b8ed63c24a0314c7f72a5`

**Always verify the current GitHub HEAD before relying on historical hashes.**

Kodi is materialized from `references/kodi` into:
`build/ps4/kodi-source`

using `git archive`, then the repository-owned PS4 overlay is applied. `references/kodi` must remain clean.

Legacy PS4 overlays were removed from the Kodi submodule:
- `references/kodi/cmake/platform/ps4`
- `references/kodi/cmake/scripts/ps4`
- `references/kodi/xbmc/platform/ps4`

## Toolchain

Primary environment: WSL2/Linux.

Known environment:
- Ubuntu 26.04.1 LTS
- x86_64
- CMake 4.2.3
- Ninja 1.13.2
- GCC/G++ 15.2
- Clang/LLVM 21.1.8
- LLD 21.1.8
- Meson 1.10.1
- pkg-config 2.5.1
- Python 3.14.x

OpenOrbis:
`~/opt/OpenOrbis/PS4Toolchain`

```bash
export OO_PS4_TOOLCHAIN="$HOME/opt/OpenOrbis/PS4Toolchain"
export PATH="/usr/lib/llvm-21/bin:$OO_PS4_TOOLCHAIN/bin/linux:$PATH"
```

Target triple:
`x86_64-pc-freebsd12-elf`

Repository toolchain:
`cmake/toolchains/openorbis-ps4-kodi.cmake`

Use generic compiler names (`clang`, `clang++`, `llvm-ar`, `llvm-ranlib`, `ld.lld`); do not hard-code LLVM 21 paths in the repo.

A minimal target was successfully compiled, linked with OpenOrbis/LLD, and passed through `create-fself`, producing `hello.oelf` and `eboot.bin`.

This validates:
`Clang 21 → PS4 target → LLD/OpenOrbis → FSELF`

It does **not** validate Kodi runtime, GP4/PKG, graphics, audio, video, or GoldHEN execution.

## PS4 overlay

File:
`cmake/platform/ps4/ps4.cmake`

Important settings:
- `CORE_SYSTEM_NAME=ps4`
- `CORE_PLATFORM_NAME=ps4`
- `APP_RENDER_SYSTEM=gles`
- `TARGET_POSIX`
- `TARGET_FREEBSD`
- `TARGET_PS4`
- `HOST_CAN_EXECUTE_TARGET=FALSE`

Do not change the host/target execution boundary without an explicit architectural decision.

## Current build script

File:
`scripts/build-ps4-kodi.sh`

Flow:
1. validate `OO_PS4_TOOLCHAIN`;
2. materialize pinned Kodi;
3. apply PS4 overlay;
4. bootstrap/configure Kodi `tools/depends`;
5. build Kodi's official native dependency graph into `x86_64-linux-gnu-native`;
6. build native `JsonSchemaBuilder`;
7. build only the target HarfBuzz dependency path;
8. configure Kodi with OpenOrbis;
9. stop after configure when `CONFIGURE_ONLY=1`;
10. otherwise build Kodi.

Important configure options include:

```text
-DNATIVEPREFIX=...
-DWITH_TEXTUREPACKER=...
-DWITH_JSONSCHEMABUILDER=...
-DINTERNAL_TEXTUREPACKER_INSTALLABLE=FALSE
-DENABLE_PYTHON=OFF
-DENABLE_TESTING=OFF
...
```

The build entrypoint is executable (`100755`).

## Host dependencies already installed

Normal WSL packages installed for TexturePacker:

```text
libgif-dev
libjpeg-dev
liblzo2-dev
libpng-dev
```

Do not create a custom dependency bootstrap or vendor host libraries into the repo. Install normal Ubuntu packages when genuinely required.

## TexturePacker — validated

Official Kodi research showed `FindTexturePacker.cmake` supports an externally supplied host executable through `WITH_TEXTUREPACKER`.

For PS4:
- build TexturePacker natively on WSL;
- pass its directory through `WITH_TEXTUREPACKER`;
- keep `HOST_CAN_EXECUTE_TARGET=FALSE`;
- set `INTERNAL_TEXTUREPACKER_INSTALLABLE=FALSE`.

TexturePacker is built from:
`tools/depends/native/TexturePacker/src`

and installed under:
`build/ps4/build/x86_64-linux-gnu-native/bin/TexturePacker`

The previous helper was:
`scripts/build-ps4-native-texturepacker.sh`

It has been **actually validated**:
- Lzo2 found
- ZLIB found
- PNG found
- GIF found
- JPEG found
- TexturePacker compiled and installed
- Kodi then reached the real PS4 cross-configure

## Current configure state

The native host-tools bootstrap is now validated for both required tools:
- TexturePacker: ✅
- JsonSchemaBuilder: ✅ as `JsonSchemaBuilder`, accepted by the pinned Kodi finder

The configure-only run reached the real PS4 cross-configuration:
- `Cross-Compiling: TRUE`
- `System type: FreeBSD`
- `Core system type: ps4`
- `ARCH x86_64-ps4`

The next blocker was Kodi's optional Bluray dependency. Its internal libbluray configuration attempted to find target LibXml2. Blu-ray is not required for the first bring-up milestone, so the project deliberately does **not** install a host LibXml2 package to satisfy it. The PS4 overlay now:
- excludes `Bluray` from optional platform dependencies;
- forces `ENABLE_BLURAY=OFF`.

The following configure run then entered Kodi's optional `XSLT` dependency and failed through the internal libxslt path because LibXml2 was unavailable. The pinned Kodi source confirms that `XSLT` is in `optional_deps`, while its internal build path requires LibXml2. XSLT is not required for the first bring-up milestone, so the project deliberately does **not** install `libxml2-dev` for this optional feature. The PS4 overlay now excludes `XSLT` from optional platform dependencies.

This establishes the current bring-up policy: start with only what is required for Kodi GUI + GLES/EGL + PS4 controller input, then re-enable additional Kodi subsystems one at a time with separate validation.

## JsonSchemaBuilder research

Relevant official Kodi files:
- `cmake/modules/buildtools/FindJsonSchemaBuilder.cmake`
- `tools/depends/native/JsonSchemaBuilder/src/CMakeLists.txt`
- `tools/depends/native/JsonSchemaBuilder/Makefile`

The exact files were verified at the pinned Kodi commit `9c3e7f4d7b3ff314cd2f19a291766555e0346024`. Kodi's finder accepts both `kodi-JsonSchemaBuilder` and `JsonSchemaBuilder`. CMake 4.2.3 produced the latter, so the helper accepts the upstream-supported name without a rename workaround.

## PS5 reference

Online reference:
`VivaLaVent/kodi-ps5` at pinned commit `0ea36e36d738aa045c1b8ed63c24a0314c7f72a5`

Its `10-build-host-tools.sh` explicitly builds:
- TexturePacker
- JsonSchemaBuilder

using focused native CMake builds with:
- `KODI_SOURCE_DIR`
- `APP_NAME_LC=kodi`
- `ARCH_DEFINES=-DTARGET_POSIX;-DTARGET_LINUX;-D_GNU_SOURCE`

The PS5 script also creates `Toolchain-Native.cmake` for other native tools.

**Do not copy the complete PS5 script blindly.** Use it only as supporting evidence for the focused host-tool architecture.

## Native dependency bootstrap correction

### Implementation

The previous project-specific `scripts/build-ps4-native-host-tools.sh` bootstrap has been removed from the build flow.

The main script now:
- configures Kodi `tools/depends`;
- runs the official `tools/depends/native` graph;
- explicitly builds the official `JsonSchemaBuilder` recipe;
- uses the generated `x86_64-linux-gnu-native` prefix for all subsequent host tools;
- builds only the target HarfBuzz dependency path after native tools are available.

This removes the duplicate `build/native` abstraction and the incorrect `x86_64-pc-linux-gnu-native` compatibility path.

### Validation — pending

The previous WSL run proved that the failure occurred because target FreeType/HarfBuzz setup invoked:

    build/x86_64-linux-gnu-native/bin/cmake

before that official native prefix had been populated.

The implementation is now aligned with Kodi's own dependency ordering. The authoritative WSL validation is still required:
1. native CMake/Ninja/Meson/Python/pkg-config/NASM are installed under `x86_64-linux-gnu-native`;
2. TexturePacker and JsonSchemaBuilder are installed there;
3. target `freetype2-noharfbuzz` configures and builds;
4. target HarfBuzz configures and builds;
5. Kodi CMake configuration proceeds.

### Scope boundary

No Vulkan/OpenGNM, renderer, controller, audio, video, GP4/PKG, GoldHEN runtime, self-hosted CI, broad CMake refactoring, or new custom dependency bootstrap was added. The change deliberately removes the previous custom native-tool bootstrap in favor of Kodi's official mechanism.

## Current native dependency bootstrap state

HarfBuzz remains a required dependency. The previous failure was before HarfBuzz compilation: target FreeType attempted to invoke Kodi's generated native CMake path, `build/x86_64-linux-gnu-native/bin/cmake`, before our project-specific bootstrap had populated that prefix.

The build orchestration has now been corrected:
- the custom `build/native` host-tool abstraction is removed;
- Kodi's official `tools/depends/native` graph builds the native toolchain;
- the official `JsonSchemaBuilder` recipe is built after native CMake is available;
- target HarfBuzz is built only after the native prefix is populated;
- no Kodi upstream source is modified.

### Validation pending

The authoritative WSL validation is:

```bash
cd ~/projects/kodi-ps4-test
git fetch origin
git reset --hard origin/main
export OO_PS4_TOOLCHAIN="$HOME/opt/OpenOrbis/PS4Toolchain"
export PATH="/usr/lib/llvm-21/bin:$OO_PS4_TOOLCHAIN/bin/linux:$PATH"
CONFIGURE_ONLY=1 ./scripts/build-ps4-kodi.sh
```

The run must confirm:
1. native CMake/Ninja/Meson/Python/pkg-config/NASM are installed under `x86_64-linux-gnu-native`;
2. TexturePacker and JsonSchemaBuilder are installed there;
3. `freetype2-noharfbuzz` configures/builds;
4. HarfBuzz configures/builds;
5. Kodi CMake configuration proceeds.

Do not start a full Kodi build until this validation succeeds. If a new blocker appears, classify it against the minimal GUI/GLES/controller milestone before changing the dependency surface.
## Milestones

A — Host tools: previously validated; native bootstrap architecture corrected, revalidation pending  
B — Kodi configure: `tools/depends` cross-configuration completed; target dependency bootstrap revalidation pending  
C — Kodi compilation: not yet validated  
D — Kodi ELF/FSELF: not yet validated  
E — real PS4 runtime: not yet validated  
F — graphics: not yet validated

## Historical commits to verify, not blindly trust

Known recent commits from the previous conversation:
- `003bfcc1bf5974810ee2598f0483353d88f02c27` — formalize Kodi/PS5/PS4 research workflow
- `66269fb3c33717db5b1b6b02c89496957103cf94` — mark PS4 build entrypoint executable
- `067070b75506df4dddfc6c4679c7de06bf8efde7` — document JsonSchemaBuilder configure blocker

Always verify current GitHub HEAD first.

## Final continuity rule

After every meaningful step, update the appropriate docs in the repository so a future conversation can resume from Git + documentation without relying on chat history. `docs/CONTINUITY.md` is the canonical cross-conversation handoff and must be refreshed whenever a handoff is prepared or its documented state becomes stale.

The authority order is:

1. actual GitHub repository state;
2. `AGENTS.md`;
3. current project docs;
4. actual source/configuration;
5. official/reference external repositories;
6. this handoff;
7. old chat memory.
## Latest handoff state — 2026-10-01 native CMake bootstrap

Verified current GitHub main before this documentation update: the previous implementation/documentation state is at or after `d4b4385e1db3d589758d73efea4f9068527b2ab`; subsequent documentation commits record the current host-bootstrap investigation.

### New validated discovery

The official Kodi native CMake recipe was reproduced directly from the materialized pinned source. It invokes CMake with `--system-curl`. The bootstrap executable compiled and entered the initial CMake configuration, but the root Makefile was not generated because CMake stopped with:

    CMAKE_USE_SYSTEM_CURL is ON but a curl is not found!

This was identified as a missing **WSL host development dependency**, not a PS4/OpenOrbis or target-dependency failure.

The host remediation was performed with the normal Ubuntu package:

    libcurl4-openssl-dev

Verification:
- libcurl 8.18.0 is visible through pkg-config;
- pkg-config provides `-lcurl` and the multiarch include path;
- the runtime linker exposes libcurl;
- the exact `/usr/include/curl/curl.h` path is not required on Ubuntu 26.04 because of multiarch layout.

### Important boundary reaffirmed

Normal Ubuntu development packages are allowed and expected for native Linux build tools when the official Kodi recipes require them. This does not change the target boundary:

    WSL/Linux packages -> host build tools
    OpenOrbis/Kodi target depends -> PS4 target libraries

Do not use a host Linux library to satisfy a PS4 target dependency.

### Immediate next step

Rerun the **unchanged official CMake bootstrap** with the previously documented environment and verify that the native root `Makefile` is generated.

Do not start the full Kodi build yet.

A separate Makefile audit also established that `make native JsonSchemaBuilder` does not automatically mean “build every native tool”. After CMake bootstrap is validated, explicitly validate the native CMake/Ninja/Meson/Python/NASM/TexturePacker/JsonSchemaBuilder dependency targets against Kodi's real dependency graph before changing the orchestration.

This handoff supersedes the older statement that the native dependency correction was merely pending without a known cause: the current known blocker is specifically the missing WSL system CURL development package, which has now been installed; bootstrap revalidation remains pending.
## WSL host dependency inventory

See [`WSL-HOST-DEPENDENCIES.md`](WSL-HOST-DEPENDENCIES.md) for the evidence-based list of Ubuntu/WSL packages installed or explicitly required by the host build. This is the source to use when recreating the WSL environment; it deliberately separates direct project prerequisites from APT-resolved transitive packages.

## Latest validation result — 2026-10-01 CMake bootstrap succeeded

The unchanged official Kodi native CMake recipe was rerun after installing the required WSL host package `libcurl4-openssl-dev`. The bootstrap now succeeds:

- system CURL is found: libcurl 8.18.0;
- CMake completes its initial configuration and generation;
- the native CMake root `Makefile` is generated;
- no Kodi upstream source was modified.

This closes the previously documented host-CURL blocker. The remaining validation is to let Kodi's official native dependency recipes build the explicit host tools they actually require, then validate the target HarfBuzz path.

**Immediate next step:** run the native dependency targets for CMake, Ninja, Meson, Python, NASM, TexturePacker and JsonSchemaBuilder from Kodi's `tools/depends/native`, using the generated `x86_64-linux-gnu-native` prefix. Do not start the full Kodi build yet.


## Latest handoff — 2026-10-01

The previously documented WSL host-CURL blocker is resolved. The **unchanged official Kodi native CMake bootstrap** now succeeds after installing `libcurl4-openssl-dev`: system libcurl 8.18.0 is found, configuration/generation complete, and the native CMake root `Makefile` exists.

### Current state

- Official pinned Kodi commit: `9c3e7f4d7b3ff314cd2f19a291766555e0346024`.
- PS5 reference: `0ea36e36d738aa045c1b8ed63c24a0314c7f72a5`.
- OpenOrbis toolchain: `~/opt/OpenOrbis/PS4Toolchain`.
- Native prefix: `build/ps4/build/x86_64-linux-gnu-native`.
- Target prefix: `build/ps4/build/x86_64-pc-freebsd12-release`.
- Host/target boundary remains strict; `HOST_CAN_EXECUTE_TARGET=FALSE`.
- No proprietary Sony SDK/dumps/binaries are used.
- `references/kodi` remains the clean upstream source; PS4 adaptations are repository-owned overlay changes only.

### Validated discovery

The exact Kodi CMake recipe uses `--system-curl`. Installing the normal WSL host development package `libcurl4-openssl-dev` was the correct fix. No Kodi CMake workaround was introduced.

### Immediate next step

**One step only:** validate the explicit Kodi native dependency targets for CMake, Ninja, Meson, Python, NASM, TexturePacker and JsonSchemaBuilder in the generated native prefix. Inspect the real result before modifying `scripts/build-ps4-kodi.sh`.

Do not start the target HarfBuzz build or full Kodi build until this native-tool stage is validated.

### Handoff procedure

A new conversation must first read this file, `AGENTS.md`, `docs/STATUS.md`, `docs/BUILD.md`, `docs/DECISIONS.md`, `docs/RESEARCH.md` and `docs/PORTING.md`, then verify current `main` and the actual repository state. Historical hashes in this document are context only; GitHub `main` is authoritative.


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


## Latest validation result — 2026-10-01 — HarfBuzz C++ header incompatibility

The Meson linker correction was validated far enough to pass the previous linker-detection blocker: HarfBuzz now reaches actual C++ compilation with the PS4 target.

The new blocker is repeated in all failing HarfBuzz translation units:

    /home/benjamin/opt/OpenOrbis/PS4Toolchain/include/c++/v1/cmath:341:9:
    error: no member named 'abs' in the global namespace; did you mean 'fabs'?

The referenced OpenOrbis target header is:

    /home/benjamin/opt/OpenOrbis/PS4Toolchain/include/math.h

and the compiler reports that header exposes `fabs` at the referenced location but not the global `abs` declaration expected by the installed libc++ `cmath`.

This is **not a HarfBuzz source error** and is not another linker failure. It indicates an incompatibility in the OpenOrbis C/C++ headers/toolchain version being used with the current LLVM/libc++ environment. OpenOrbis release history documents prior fixes specifically for BSD/MUSL header discrepancies and C++ `cmath` handling, so the installed toolchain revision must be identified before any repository workaround is considered.

No repository code or toolchain headers have been modified for this blocker.

### Immediate next step

Inspect the installed OpenOrbis toolchain revision and the exact relevant sections of:

    $OO_PS4_TOOLCHAIN/include/c++/v1/cmath
    $OO_PS4_TOOLCHAIN/include/math.h

Then compare them with the corresponding OpenOrbis upstream/release state. Do not patch Kodi, HarfBuzz, or the repository overlay until that comparison establishes whether the local OpenOrbis installation is stale/incompatible or whether a separate compatibility adaptation is actually required.


## Latest handoff state — 2026-10-01 — OpenOrbis v0.5.4 / LLVM 18 compatibility experiment

### Actual current state

- Repository: Nabouna32/kodi-ps4-test, normal development on main.
- Pinned Kodi commit: 9c3e7f4d7b3ff314cd2f19a291766555e0346024.
- OpenOrbis target toolchain: v0.5.4, installed at ~/opt/OpenOrbis/PS4Toolchain.
- Previous host compiler environment: LLVM/Clang/LLD 21.1.8.
- New host compiler environment: LLVM/Clang/LLD 18.1.8 installed in parallel; not yet used to validate Kodi.
- The repository does not currently pin a host LLVM version.
- references/kodi remains the clean upstream source; no Kodi/HarfBuzz/OpenOrbis headers were modified for the current blocker.

### Latest validated blocker

The Meson linker correction (-fuse-ld=lld) moved the build past linker detection and into real HarfBuzz C++ compilation. Compilation then fails repeatedly at:

    OpenOrbis/include/c++/v1/cmath:341:9
    error: no member named 'abs' in the global namespace; did you mean 'fabs'?

The referenced OpenOrbis math.h region declares fabs, fabsf and fabsl but not the global abs expected by libc++ cmath.

This is classified as a target-header/libc++ compatibility issue, not a HarfBuzz source issue and not a linker issue.

### What changed in the host since the previous handoff

LLVM/Clang/LLD 18.1.8 were installed through Ubuntu packages without removing LLVM/LLD 21.1.8. The purpose is to test the OpenOrbis v0.5.4 compatibility hypothesis.

### Immediate next step — one experiment

Do not modify repository source yet. Verify LLVM 18 generic tool resolution, then run the existing configure-only build with LLVM 18 first in PATH:

    cd ~/projects/kodi-ps4-test
    export OO_PS4_TOOLCHAIN="$HOME/opt/OpenOrbis/PS4Toolchain"
    export PATH="/usr/lib/llvm-18/bin:$OO_PS4_TOOLCHAIN/bin/linux:$PATH"
    command -v clang
    command -v clang++
    command -v llvm-ar
    command -v llvm-ranlib
    command -v ld.lld
    clang --version
    clang++ --version
    ld.lld --version
    CONFIGURE_ONLY=1 ./scripts/build-ps4-kodi.sh

The result must be classified before any repository workaround is introduced.

### Scope boundary

No new renderer, controller, audio, video, packaging, runtime, self-hosted CI, or broad build-system work is part of this step. If LLVM 18 does not resolve the header mismatch, the next action is to compare the exact OpenOrbis v0.5.4 libc++/math headers and their expected LLVM integration rather than patching Kodi blindly.

## Latest handoff — 2026-10-01 — LLVM 18 experiment completed

The controlled LLVM 18 compatibility experiment has been completed.

### Result

With:

    /usr/lib/llvm-18/bin/clang
    /usr/lib/llvm-18/bin/clang++
    /usr/lib/llvm-18/bin/llvm-ar
    /usr/lib/llvm-18/bin/llvm-ranlib
    /usr/lib/llvm-18/bin/ld.lld

selected through PATH, the existing CONFIGURE_ONLY=1 ./scripts/build-ps4-kodi.sh workflow still reaches HarfBuzz C++ compilation and fails at:

    $OO_PS4_TOOLCHAIN/include/c++/v1/cmath:341:9
    error: no member named 'abs' in the global namespace; did you mean 'fabs'?

The compiler still points to:

    $OO_PS4_TOOLCHAIN/include/math.h:295:13
    double fabs(double);

The same failure occurs across many HarfBuzz translation units.

### Interpretation

The LLVM 18 experiment did not resolve the blocker. The previous hypothesis that LLVM 21 was the primary incompatibility is therefore rejected as a sufficient explanation.

No Kodi source, HarfBuzz source, OpenOrbis header, or repository toolchain file was modified.

### Next step — one investigation

Directly compare the OpenOrbis v0.5.4 include/c++/v1/cmath and include/math.h pair with the corresponding upstream OpenOrbis source/release state and determine the intended compatibility mechanism for the C++ math declarations.

The investigation must answer:
1. Why cmath unconditionally performs using ::abs;
2. where OpenOrbis v0.5.4 is expected to provide that global declaration;
3. whether the installed header pair is internally consistent;
4. whether a required include/define/toolchain setting is missing from our integration.

Only after this comparison should a repository adaptation be considered.

### Scope boundary

Do not patch HarfBuzz, suppress the abs error, or modify OpenOrbis headers as a workaround before the header integration root cause is established. Renderer, controller, audio, video, packaging, runtime and self-hosted CI remain out of scope.

## Latest handoff — 2026-10-01 — OpenOrbis C++ header root cause identified

The LLVM 18 experiment did not change the failure. The investigation then compared the installed OpenOrbis v0.5.4 header behavior with the OpenOrbis libc++ fork.

### Root cause

OpenOrbis ships a forked libc++ (OpenOrbis/llvm-project). Its libcxx/include/cmath does:

    #include <math.h>
    ...
    using ::abs;

Its corresponding libcxx/include/math.h is a wrapper that:
- performs #include_next <math.h> to reach the SDK C math header;
- includes <stdlib.h> for C++;
- therefore provides the global abs declaration expected by cmath.

Our PS4 target flags currently put:

    -isystem $OO_PS4_TOOLCHAIN/include
    -isystem $OO_PS4_TOOLCHAIN/include/c++/v1

The first directory therefore wins when cmath asks for <math.h>, so it gets the raw SDK C math.h instead of libc++'s wrapper. That raw header exposes fabs but not abs, exactly matching the compiler diagnostic.

This also explains why changing LLVM 21 to LLVM 18 had no effect.

Independent OpenOrbis compatibility documentation confirms the required design: libc++'s directory must be ahead of the SDK C headers because libc++ wraps the C headers and relies on #include_next.

### Validation still required

Do not modify the repository yet. Run a minimal <cmath> cross-compile twice:
- current order: SDK C include first;
- corrected order: libc++ include first.

Expected:
- current order reproduces using ::abs;
- corrected order compiles.

If confirmed, the implementation should change only the PS4 C++ include ordering in the generated target flags/toolchain integration. No HarfBuzz or OpenOrbis header modification is planned.

### Scope boundary

Renderer, controller, audio, video, packaging, runtime and self-hosted CI remain out of scope.
