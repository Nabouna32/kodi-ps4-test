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
- docs/CONTINUITY.md — canonical cross-conversation handoff.

After every meaningful response/work phase that establishes a discovery,
decision, implementation result, test result, blocker, correction, or changed
next action, update the appropriate specialized document before considering
that phase complete.

Do not rely on chat history for project continuity. A new agent or conversation
must be able to understand the current state from Git and these documents.

### Cross-conversation continuity rule

`docs/CONTINUITY.md` is the canonical handoff document for starting or resuming work in a new conversation.

When a conversation reaches a handoff point, or when a new conversation is explicitly being prepared, update `docs/CONTINUITY.md` before handing over. The handoff must describe the actual repository state at that moment, including:

- current GitHub `main` HEAD;
- relevant pinned external commits;
- validated facts and their validation status;
- current blocker;
- important decisions and scope boundaries;
- the exact next step proposed;
- any important commands or validation procedure needed to resume.

The handoff is continuity context, not a replacement for verification. A new conversation must read it first, then independently verify its claims against GitHub, `AGENTS.md`, the relevant project documentation, and the actual source/configuration before changing anything.

If the repository state changes after the handoff is written, update `docs/CONTINUITY.md` again before the next conversation handoff. Do not leave a known stale handoff as the documented current state.

## Comparative platform research rule

For any non-trivial PS4 porting question where another implementation can provide useful evidence, use this research sequence systematically:

1. **Official Kodi** — establish the upstream behavior, interfaces, build mechanism, constraints, and intended extension points.
2. **PS5 reference** — inspect the corresponding implementation in `VivaLaVent/kodi-ps5` to identify concrete PlayStation/Kodi integration patterns, workarounds, and build-system choices.
3. **PS4 information** — research the PS4/OpenOrbis ecosystem online using current, public sources to establish what the PS4 platform actually provides and what remains unknown.
4. **Comparison** — explicitly compare the three sources and separate common Kodi/PlayStation concepts from PS5-specific assumptions and PS4-specific constraints.
5. **Adaptation** — derive the smallest justified PS4 implementation from that comparison. Do not copy PS5 code merely because it exists there, and do not invent a PS4 equivalent without evidence.
6. **Validation** — turn the resulting hypothesis into the smallest reproducible experiment or build validation available before treating it as confirmed.

This sequence is the default methodology for platform, graphics, input, audio, filesystem, networking, video, packaging, build-system, and similar porting questions. Use authoritative/primary sources first and record important external evidence and its source in `docs/RESEARCH.md`.

Do not skip the official Kodi or PS4 evidence because the PS5 reference appears to offer an obvious solution. The PS5 repository is a reference, not an authority for PS4 behavior.

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
