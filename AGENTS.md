# AGENTS.md

## Scope

This repository is the Kodi PS4 port project. Keep each change focused on the
current validated task and do not silently broaden the scope.

The mandatory operational procedure is defined in docs/WORKFLOW.md. It is part
of the project's working rules, not optional guidance.

## Mandatory startup

Before any repository modification in a new conversation, the agent MUST:

1. read AGENTS.md;
2. read docs/WORKFLOW.md;
3. read docs/CONTINUITY.md;
4. read docs/STATUS.md;
5. read docs/BUILD.md;
6. read the other documentation relevant to the task;
7. independently verify the current GitHub main state and relevant source;
8. report the verified state before proposing implementation.

Reading AGENTS.md alone is not sufficient. Reading CONTINUITY.md alone is not
sufficient. No modification may begin before this startup verification and
user validation of the proposed step.

## Source of truth

Use the following hierarchy:

1. Git state and checked-in files: what is actually implemented.
2. Official Kodi source: upstream Kodi behavior and interfaces.
3. This repository's documentation: validated project decisions and continuity.
4. references/kodi-ps5/: concrete PS5 integration reference.
5. External research: evidence that must be recorded with its source and confidence.

When sources disagree, do not silently rewrite one source to match another.
Record the discrepancy and resolve it at the appropriate project level.

The repository state always takes precedence over stale continuity text. If the
state can be reconstructed, update the documentation. If an important decision
is required, stop and ask the user.

## Git and workflow

GitHub main is the remote source of truth.

Normal development does NOT commit directly to main. After the user validates a
step, create an appropriate branch from the current origin/main and open a PR
targeting main.

Branch naming is defined by docs/WORKFLOW.md. Do not merge a PR without explicit
user approval.

The complete startup, step-validation, branching, testing, documentation,
commit, PR, CI, and merge procedure is defined in docs/WORKFLOW.md and MUST be
followed.

## Documentation map

Use docs/README.md for the documentation map and maintenance rules.

The principal documents are:

- docs/WORKFLOW.md — mandatory operational development workflow.
- docs/STATUS.md — current state, blockers and next action.
- docs/DECISIONS.md — durable project decisions.
- docs/BUILD.md — host environment, toolchain and build workflow.
- docs/ARCHITECTURE.md — architecture and technical boundaries.
- docs/RESEARCH.md — investigations, experiments and evidence.
- docs/PORTING.md — compact continuity index.
- docs/CONTINUITY.md — canonical cross-conversation handoff.
- docs/WSL-HOST-DEPENDENCIES.md — host package inventory and evidence.

Documentation is part of implementation, not final cleanup. Update the
appropriate document after every meaningful discovery, decision,
implementation result, validation result, blocker, correction, environment
change, or changed next action.

Do not accumulate obsolete history indefinitely. Current documents should
describe current state; obsolete facts should be removed or consolidated when
they stop being useful.

## Reference repositories

The project pins two external repositories as Git submodules:

- references/kodi/ — official Kodi, xbmc/xbmc.
- references/kodi-ps5/ — VivaLaVent/kodi-ps5.

The Kodi repository has its own AGENTS.md. When analysing or proposing changes
intended to be contributed upstream, read and follow that file.

references/kodi/ is immutable for this project and must never be manually
modified as part of PS4 port work.

references/kodi-ps5/ is a technical reference only. Do not copy code, libraries,
binaries, or platform assumptions blindly from it.

## Comparative platform research

For any non-trivial PS4 porting question where another implementation can
provide useful evidence, the methodology in docs/WORKFLOW.md is mandatory:

Official Kodi → PS5 reference → current PS4/OpenOrbis evidence → explicit
comparison → smallest justified PS4 adaptation → executable validation.

Do not skip official Kodi or PS4 evidence because the PS5 reference appears to
offer an obvious solution. Do not treat an untested hypothesis as a confirmed
capability.

Important external evidence must be recorded in docs/RESEARCH.md.

## PS4 constraints

Do not assume that PS5 APIs, OpenGL capabilities, shader formats, memory
layouts, decoder surfaces, or synchronization mechanisms exist on PS4.

Current graphics direction is EGL/GLES2/Piglet first. Vulkan/OpenGNM is a
separate future/research path unless a later decision changes this.

Do not add Sony proprietary SDK files, dumps, binaries, or other non-public
artifacts to this repository.

## Host WSL dependencies

For host-native Linux build tools, normal Ubuntu/WSL development packages are
an expected and supported dependency mechanism. Do not introduce project-local
replacements, vendored host libraries, fake prefixes, or build-system
workarounds merely to avoid installing a required host development package.

When an official Kodi native recipe requires a host library, install the normal
Ubuntu development package and document it in docs/WSL-HOST-DEPENDENCIES.md.

This rule applies only to the host. It must not blur the target boundary: a
Linux/WSL package must never be used as a substitute for a PS4 target library.
PS4 target dependencies remain built for the OpenOrbis/FreeBSD target and live
in the target dependency prefix.

When a dependency is optional for the current bring-up milestone, classify it
first and avoid installing it only to unblock an unnecessary feature.

## Source inspection

When the information needed to diagnose or implement a change already exists
in checked-in source, inspect the actual file or repository source directly
(GitHub/online source or the checked-out file).

Do not ask the user to run broad grep searches to discover source-code behavior
that we can inspect ourselves. Prefer direct file inspection and targeted
source retrieval.

Local shell commands remain appropriate for generated build artifacts, runtime
state, toolchain/environment validation, and concrete reproduction. Prefer
targeted commands over broad recursive searches.

## Quality and review

Prefer small, verifiable commits.

A validated step is not complete until the implementation is within approved
scope, appropriate validation has run, failures caused by the change are
resolved, relevant documentation is current, the final diff is audited, the
branch is pushed, the PR and available CI are checked, and the user has been
informed.

Do not silently evolve the product, architecture, platform strategy,
dependency policy, or other important project direction. Important decisions
require explicit user validation.

For the detailed procedure, validation levels, self-hosted CI policy,
cross-conversation handoff rules, and completion criteria, follow
docs/WORKFLOW.md.
