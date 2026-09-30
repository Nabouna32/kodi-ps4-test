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
Current verified HEAD: `a26b3efdc9d092a1a036d6f9ed4f4300cd1e0c32`

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

## Current blocker — JsonSchemaBuilder

The same `CONFIGURE_ONLY=1` validation then failed:

```text
Could not find 'JsonSchemaBuilder' executable in
.../build/ps4/build/native/bin
supplied by -DWITH_JSONSCHEMABUILDER
```

Therefore:
- TexturePacker: ✅
- Kodi reached PS4 cross-configuration: ✅
- JsonSchemaBuilder host tool: ❌ current blocker
- CCache/ClangFormat warnings: non-blocking at this stage
- Do not start a full Kodi build until configure succeeds.

## JsonSchemaBuilder research

Relevant official Kodi files:
- `cmake/modules/buildtools/FindJsonSchemaBuilder.cmake`
- `tools/depends/native/JsonSchemaBuilder/src/CMakeLists.txt`
- `tools/depends/native/JsonSchemaBuilder/Makefile`

The known current Kodi implementation builds a small C++17 host executable and installs it with a name based on:
`APP_NAME_LC`, normally `kodi-JsonSchemaBuilder`.

The exact three files were re-fetched and verified at the pinned Kodi commit `9c3e7f4d7b3ff314cd2f19a291766555e0346024`. They confirm that Kodi expects a host executable named `kodi-JsonSchemaBuilder` (with `JsonSchemaBuilder` also accepted by the finder) and that the tool is a small C++17 native build.

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

## Immediate next step — Step 5

### Goal

Complete the native host-tools bootstrap by building both:
- `TexturePacker`
- `JsonSchemaBuilder`

### Proposed implementation

Replace the specialized:
`scripts/build-ps4-native-texturepacker.sh`

with a maintainable generic helper, likely:
`scripts/build-ps4-native-host-tools.sh`

It should:
- build only the currently required host tools;
- use official pinned Kodi source;
- use WSL host compilers;
- use Ninja;
- install into the existing `NATIVEPREFIX`;
- pass `KODI_SOURCE_DIR`;
- pass `APP_NAME_LC=kodi`;
- use the validated host `ARCH_DEFINES`;
- avoid custom dependency bootstrapping;
- keep host and PS4 target builds separate.

Main script should then conceptually invoke:

```bash
KODI_SRC="${KODI_SRC}" NATIVEPREFIX="${NATIVEPREFIX}" JOBS="${JOBS:-$(nproc)}"   bash "${ROOT}/scripts/build-ps4-native-host-tools.sh"
```

Then validate only:

```bash
CONFIGURE_ONLY=1 ./scripts/build-ps4-kodi.sh
```

Immediate objective: get Kodi configuration past JsonSchemaBuilder.

### Pre-implementation verification completed

The pre-implementation audit has now been completed against the current GitHub repository:
1. verified current `main`;
2. read `AGENTS.md` and the relevant project documentation;
3. confirmed the `JsonSchemaBuilder` configure blocker in the repository state and upstream mechanism;
4. fetched the three `JsonSchemaBuilder` files from pinned Kodi commit `9c3e7f4d7b3ff314cd2f19a291766555e0346024`;
5. compared the host-tool approach with the pinned PS5 reference;
6. confirmed the proposed Step 5 scope without beginning implementation.

The next conversation should repeat the normal source-of-truth verification before modifying anything, even though this audit is recorded here.

### Scope boundary

Do not add now:
- Vulkan/OpenGNM;
- PS4 renderer;
- controller;
- audio;
- video;
- GP4/PKG;
- GoldHEN runtime integration;
- self-hosted GitHub Actions;
- broad CMake refactoring;
- large custom dependency bootstrap.

If configure reveals a new blocker after JsonSchemaBuilder, document it and make it the next focused step.

## Milestones

A — Host tools: TexturePacker ✅, JsonSchemaBuilder ❌  
B — Kodi configure: not yet validated  
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
