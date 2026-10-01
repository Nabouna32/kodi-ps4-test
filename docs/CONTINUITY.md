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
\n## Latest validation result — 2026-10-01 CMake bootstrap succeeded\n\nThe unchanged official Kodi native CMake recipe was rerun after installing the required WSL host package `libcurl4-openssl-dev`. The bootstrap now succeeds:\n\n- system CURL is found: libcurl 8.18.0;\n- CMake completes its initial configuration and generation;\n- the native CMake root `Makefile` is generated;\n- no Kodi upstream source was modified.\n\nThis closes the previously documented host-CURL blocker. The remaining validation is to let Kodi's official native dependency recipes build the explicit host tools they actually require, then validate the target HarfBuzz path.\n\n**Immediate next step:** run the native dependency targets for CMake, Ninja, Meson, Python, NASM, TexturePacker and JsonSchemaBuilder from Kodi's `tools/depends/native`, using the generated `x86_64-linux-gnu-native` prefix. Do not start the full Kodi build yet.\n