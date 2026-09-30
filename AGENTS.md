# AGENTS.md

## Scope

This repository is the Kodi PS4 port project. Keep each change focused on the
current validated task and do not silently broaden the scope.

## Source of truth

Use the following hierarchy:

1. Git state and checked-in files: what is actually implemented.
2. Official Kodi source: upstream Kodi behavior and interfaces.
3. This repository's documentation: validated project decisions and continuity.
4. `references/kodi-ps5/`: concrete PS5 integration reference.
5. External research: evidence that must be recorded with its source and confidence.

When sources disagree, do not silently rewrite one source to match another.
Record the discrepancy and resolve it at the appropriate project level.

## Reference repositories

The project pins two external repositories as Git submodules:

- `references/kodi/` — official Kodi, `xbmc/xbmc`.
- `references/kodi-ps5/` — `VivaLaVent/kodi-ps5`.

Initialize them with:

```bash
git submodule update --init --recursive
```

Do not modify files inside these submodules as part of this repository's
implementation. Changes to upstream Kodi or the PS5 reference belong in their
own repositories.

The Kodi repository has its own `AGENTS.md`. When analysing or proposing
changes intended to be contributed upstream, read and follow that file. It is
not the instruction set for this repository.

## Practical development rule

This project must progress from research to executable validation as soon as
the required environment exists.

Prefer this order:

1. reproduce or build the smallest relevant experiment;
2. observe the real result;
3. record the result in `docs/PORTING.md`;
4. only then generalize the architecture or implement the Kodi integration.

Do not treat an untested hypothesis as a confirmed capability.

## PS4 constraints

Do not assume that PS5 APIs, OpenGL capabilities, shader formats, memory
layouts, decoder surfaces, or synchronization mechanisms exist on PS4.

Current graphics direction is EGL/GLES2/Piglet first. Vulkan/OpenGNM is a
separate future/research path unless a later decision changes this.

Do not add Sony proprietary SDK files, dumps, binaries, or other non-public
artifacts to this repository.

## Documentation continuity

Update `docs/PORTING.md` after meaningful discoveries, decisions,
implementation results, tests, blockers, or changes in next actions.

A future agent must be able to resume the project from the repository and
documentation without relying on chat history.

## Quality and review

Prefer small, verifiable commits. Before considering a task complete:

- inspect the resulting diff;
- run appropriate validation;
- fix failures caused by the change;
- verify the final repository state;
- record relevant results in the continuity documentation.

Avoid unrelated cleanup, speculative refactors, and changes outside the
validated task.
