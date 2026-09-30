# AGENTS.md

## Scope

This repository is the Kodi PS4 port project. Keep each change focused on the
current validated task and do not silently broaden the scope.

## Source of truth

Use the following hierarchy:

1. Git state and checked-in files: what is actually implemented.
2. Official Kodi source: upstream Kodi behavior and interfaces.
3. This repository's documentation: validated project decisions and continuity.
4. references/kodi-ps5/: concrete PS5 integration reference.
5. External research: evidence that must be recorded with its source and confidence.

When sources disagree, do not silently rewrite one source to match another.
Record the discrepancy and resolve it at the appropriate project level.

## Reference repositories

The project pins two external repositories as Git submodules:

- references/kodi/ — official Kodi, xbmc/xbmc.
- references/kodi-ps5/ — VivaLaVent/kodi-ps5.

The Kodi repository has its own AGENTS.md. When analysing or proposing changes
intended to be contributed upstream, read and follow that file.

## Git synchronization and online-first research

The GitHub main branch is the remote source of truth for the project state.
Before each local work phase, synchronize the checkout with origin/main and
verify the resulting state. Do not assume an old local checkout is current.

For external repositories, prefer inspecting the online repository directly
(GitHub/API) rather than performing broad local greps or cloning/copying large
amounts of external source merely for research. Use local commands only when a
small targeted check is needed to identify a remote, validate the environment,
or reproduce a concrete build/runtime result.

Standard local synchronization:

    cd ~/projects/kodi-ps4-test
    git fetch origin
    git reset --hard origin/main

Do not use this while intentional uncommitted project changes need preserving.

## Git workflow

This project is developed directly on main. For normal work, commit directly
to main; do not create feature/research/fix branches or pull requests as the
normal workflow.

## Documentation continuity

Documentation is part of implementation, not final cleanup.

Use the specialized documentation map:

- docs/README.md — documentation map and maintenance rules.
- docs/STATUS.md — current state, blockers and next action.
- docs/DECISIONS.md — durable project decisions.
- docs/BUILD.md — host environment, toolchain and build workflow.
- docs/ARCHITECTURE.md — architecture and technical boundaries.
- docs/RESEARCH.md — investigations, experiments and evidence.
- docs/PORTING.md — compact continuity index.

After every meaningful response/work phase that establishes a discovery,
decision, implementation result, test result, blocker, correction, or changed
next action, update the appropriate specialized document before considering
that phase complete.

Do not rely on chat history for project continuity. A new agent or conversation
must be able to understand the current state from Git and these documents.

## Practical development rule

Progress from research to executable validation as soon as the required
environment exists:

1. reproduce or build the smallest relevant experiment;
2. observe the real result;
3. record the result in the appropriate specialized document;
4. only then generalize the architecture or implement Kodi integration.

Do not treat an untested hypothesis as a confirmed capability.

## PS4 constraints

Do not assume that PS5 APIs, OpenGL capabilities, shader formats, memory
layouts, decoder surfaces, or synchronization mechanisms exist on PS4.

Current graphics direction is EGL/GLES2/Piglet first. Vulkan/OpenGNM is a
separate future/research path unless a later decision changes this.

Do not add Sony proprietary SDK files, dumps, binaries, or other non-public
artifacts to this repository.

## Quality and review

Prefer small, verifiable commits. Before considering a task complete:

- inspect the resulting diff;
- run appropriate validation;
- fix failures caused by the change;
- verify the final repository state;
- record relevant results in the appropriate specialized document.

Avoid unrelated cleanup, speculative refactors, and changes outside the
validated task.
