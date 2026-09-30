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
Current main HEAD: `e0855e77f3e1467863eb9107d0f798462671533e` (Autoconf PS4 host-triplet correction). Always verify the current GitHub HEAD before relying on historical hashes.

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
4. build native host tools;
5. configure Kodi with OpenOrbis;
6. stop after configure when `CONFIGURE_ONLY=1`;
7. otherwise build Kodi.

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
`build/ps4/build/native/bin/TexturePacker`

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

## Step 5 — Native host-tools bootstrap

### Implementation completed

The specialized TexturePacker-only helper was replaced by:

    scripts/build-ps4-native-host-tools.sh

The helper now builds both currently required Kodi host tools from the pinned source:
- TexturePacker
- JsonSchemaBuilder

It uses the WSL host compilers, Ninja, KODI_SOURCE_DIR, APP_NAME_LC=kodi, and the validated host ARCH_DEFINES, then installs both into the shared native prefix.

The main build script now invokes this shared helper. The old:

    scripts/build-ps4-native-texturepacker.sh

was removed.

The implementation is committed to main.

### Validation — host tools and cross-configure

WSL validation after the host-tool correction confirmed:
1. TexturePacker builds/installs;
2. JsonSchemaBuilder builds/installs as `JsonSchemaBuilder`;
3. the pinned Kodi finder accepts that executable;
4. Kodi enters PS4 cross-configuration.

The next configure blockers were optional Bluray/libbluray and optional XSLT/libxslt, both entering LibXml2-dependent paths. The PS4 overlay now excludes both from the minimal bring-up profile.

Required next validation:

```bash
cd ~/projects/kodi-ps4-test
git fetch origin
git reset --hard origin/main

CONFIGURE_ONLY=1 ./scripts/build-ps4-kodi.sh
```

Two consecutive WSL runs stopped at the overlay application step with `patch: **** malformed patch`; these were repository patch-format defects, not HarfBuzz/toolchain results. The first correction fixed one set of hunk counts; the second exposed another malformed hunk at the Android/FreeBSD case boundary. Inspection then found a third incorrect hunk count in `Toolchain.cmake.in`. The previous patch correction `14a0ba05e8b7dce99234c7c3dea8339cd395499a` fixed the Toolchain.cmake hunk, but WSL still reported `patch: **** malformed patch at line 19`. Direct inspection against the exact pinned Kodi source then identified one remaining incorrect hunk header in `configure.ac`: the hunk contained four original context lines, not five. That final patch-format defect was corrected in commit `abe4c8d3fdcdb0222e5e57cd0cc97cc8ddbc2124`. WSL then reported both hunks as failed despite the corrected counts. Direct line-number inspection of the exact pinned Kodi source showed the hunk start locations were also off by one: `configure.ac` context begins at line 263, while `Toolchain.cmake.in` context begins at line 35. These locations were corrected in commit `a7f530b758e926c9b5650bd8c44e11d22ea9cacd`. The patch still requires WSL execution after this latest correction.

Verify that:
1. native host tools remain available;
2. Bluray/libbluray and XSLT/libxslt are no longer configured;
3. Kodi proceeds to the next dependency or completes configuration;
4. the host/target boundary remains intact.

Do not start a full Kodi build until configure succeeds. If a new blocker appears, first classify whether it belongs to the minimal GUI/GLES/controller milestone or to an optional feature that can remain disabled.

### Scope boundary

No Vulkan/OpenGNM, renderer, controller, audio, video, GP4/PKG, GoldHEN runtime, self-hosted CI, broad CMake refactoring, or custom dependency bootstrap was added.

## Current HarfBuzz blocker

The latest configure-only run reaches required ASS/libass and fails because target HarfBuzz libraries are not available. This is a required dependency, not an optional feature to disable.

Audit completed against the exact pinned Kodi commit, the pinned PS5 reference, and public OpenOrbis information:
- Kodi's `FindHarfBuzz.cmake` searches the target dependency prefix and does not itself build HarfBuzz.
- Kodi provides an official target recipe at `tools/depends/target/harfbuzz` for HarfBuzz 14.2.0, built statically with Meson.
- The official target dependency graph uses `freetype2-noharfbuzz` to bootstrap the FreeType/HarfBuzz cycle, then builds HarfBuzz and normal FreeType.
- PS5 uses target-side HarfBuzz in its pacbrew/sysroot; that establishes the dependency architecture but its PS5 binaries are not reusable for PS4.
- OpenOrbis does not provide Kodi's third-party HarfBuzz target library.

Do **not** install Ubuntu `libharfbuzz-dev`; the missing artifact is the PS4 target library.

### Proposed next implementation step

Integrate the smallest part of Kodi's official target dependency mechanism needed for HarfBuzz into the PS4/OpenOrbis build:
1. initialize the required target-dependency build environment;
2. build `freetype2-noharfbuzz` and HarfBuzz for PS4;
3. stage the target library/headers/metadata in the dependency prefix Kodi already searches;
4. rerun configure-only and validate target-side discovery;
5. stop at the next blocker.

The smallest integration is now implemented in the repository overlay. It applies a minimal patch to Kodi's target dependency configuration for the OpenOrbis FreeBSD target, reuses the official `freetype2-noharfbuzz` and HarfBuzz recipes, adds the required FreeBSD target toolchain behavior, and stages the result in the target dependency prefix consumed by Kodi CMake.

The WSL configure-only run confirmed that this overlay patch applies cleanly. It then failed in the target dependency bootstrap because the build script passed `--host=x86_64-pc-freebsd12-elf`; Autoconf rejects that tuple, while the LLVM/OpenOrbis compiler target legitimately remains `x86_64-pc-freebsd12-elf`. The durable correction is now committed in `e0855e77f3e1467863eb9107d0f798462671533e`: Autoconf uses `x86_64-pc-freebsd12`, and the target dependency prefix is consequently `build/ps4/build/x86_64-pc-freebsd12-release`. WSL configure-only validation after this correction is pending.

## Milestones

A — Host tools: TexturePacker ✅, JsonSchemaBuilder ✅  
B — Kodi configure: cross-configuration reached; configure completion pending  
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
