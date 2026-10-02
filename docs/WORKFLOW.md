# Kodi PS4 — Development Workflow

This document defines the mandatory operational workflow for repository work.
It is normative: an agent working on this project must follow it unless a
higher-priority instruction explicitly overrides it.

Mandatory startup documents:
- AGENTS.md
- docs/WORKFLOW.md
- docs/CONTINUITY.md
- docs/STATUS.md
- docs/BUILD.md

Then read the other documentation relevant to the task, especially
ARCHITECTURE.md, RESEARCH.md, DECISIONS.md, PORTING.md, and
WSL-HOST-DEPENDENCIES.md when applicable.

## 1. Mandatory startup verification

A new conversation must complete this sequence before modifying the repository:

1. Read AGENTS.md.
2. Read this docs/WORKFLOW.md.
3. Read docs/CONTINUITY.md.
4. Read docs/STATUS.md.
5. Read docs/BUILD.md.
6. Read the other relevant project documentation.
7. Inspect the current GitHub main state.
8. Verify the current main HEAD and relevant pinned external commits.
9. Inspect the relevant source/configuration directly.
10. Compare the documentation with the actual repository state.
11. Identify and report discrepancies instead of silently reconciling them.
12. Establish the currently completed step, blocker, validated facts,
    unresolved hypotheses, and relevant environment/toolchain state.
13. Present that verified state to the user before proposing implementation.

Reading AGENTS.md alone is not sufficient. Reading the continuity document
alone is not sufficient. The startup sequence is mandatory.

No repository modification is allowed before this verification and before the
user validates the proposed step.

## 2. One validated step at a time

Every work phase has exactly one explicit objective.

Before implementation, state:
- the objective;
- why it is needed;
- what is inside scope;
- what is explicitly outside scope;
- known facts;
- hypotheses and unknowns;
- relevant risks/dependencies;
- the validation that will determine success.

Then wait for user validation.

After validation:
1. create the appropriate branch from the current origin/main;
2. implement only the validated step;
3. run the appropriate validation;
4. fix failures caused by that step;
5. update the relevant documentation;
6. inspect the complete diff;
7. commit;
8. push the branch;
9. open/update the PR;
10. wait for CI where available;
11. report the result and remaining issues;
12. ask the user whether to merge.

Do not automatically begin the next step after completing one.

## 3. Important decisions

The agent may choose ordinary implementation details inside a validated step.

The agent must stop and ask the user before making a decision that materially
changes:
- architecture;
- platform strategy;
- graphics/backend direction;
- dependency policy;
- feature scope;
- build-system strategy;
- security model;
- repository workflow;
- long-term project direction.

When presenting such a decision, explain the options, consequences, evidence,
and recommendation without implementing it first.

## 4. Out-of-scope discoveries

If implementation reveals a problem that is outside the validated step:
1. stop before integrating it;
2. explain what was discovered;
3. explain why it is outside scope;
4. identify the available options and consequences;
5. ask the user whether to create a new step.

A directly related defect that can be fixed without changing scope or making a
new architectural/product decision may be fixed as part of the current step.

## 5. Facts, hypotheses, decisions and validation

Keep these categories distinct:
- Fact — directly verified by source, repository state, experiment, or
  authoritative evidence.
- Hypothesis — plausible but not yet verified.
- Decision — explicitly accepted project direction.
- Proposed action — what should be done next, pending validation.
- Validation result — the concrete outcome of a test or experiment.

Never describe a hypothesis as a fact merely because it is plausible or because
the PS5 reference implements something similar.

When evidence is missing, say that it is unknown and investigate when useful.

## 6. Git synchronization and branches

GitHub main is the remote source of truth.

Before starting local work:
- inspect the local state first;
- never destroy intentional uncommitted changes;
- synchronize with origin/main when it is safe to do so;
- verify the resulting commit.

For a clean checkout, the normal synchronization is:

    cd ~/projects/kodi-ps4-test
    git fetch origin
    git switch main
    git reset --hard origin/main

Normal development does NOT commit directly to main.

After the user validates a step, create a branch from the current origin/main.
Use:
- feat/<short-description>
- fix/<short-description>
- build/<short-description>
- research/<short-description>
- docs/<short-description>
- refactor/<short-description>

Open a PR targeting main. Do not merge it without explicit user approval.

Before local validation, switch to the actual working branch so that tests run
against the code being proposed.

## 7. Validation levels

Always distinguish:
1. Local WSL validation — development/build/environment validation.
2. CI validation — reproducible automated validation in the configured CI
   environment.
3. PS4 runtime validation — execution on actual PS4 hardware/software.

A successful local build is not evidence of successful PS4 execution.
A successful CI build is not evidence of successful PS4 runtime behavior.

Until the self-hosted OpenOrbis runner exists, local WSL validation remains the
available build validation for PS4-targeted work.

## 8. PS4 porting research methodology

For every non-trivial PS4 porting question where comparative evidence is useful,
follow this sequence:
1. Official Kodi — establish upstream behavior, interfaces, build mechanism,
   constraints, and intended extension points.
2. PS5 reference — inspect the corresponding integration in
   VivaLaVent/kodi-ps5.
3. PS4/OpenOrbis evidence — research current public evidence for what PS4
   actually provides.
4. Comparison — explicitly separate common Kodi/PlayStation concepts,
   PS5-specific assumptions, and PS4-specific constraints.
5. Adaptation — derive the smallest justified PS4 implementation.
6. Validation — reproduce the smallest relevant experiment or build test.

The PS5 repository is evidence, not authority for PS4 behavior. Do not copy its
code merely because it exists there.

Important external evidence must be recorded in docs/RESEARCH.md with its
source and confidence.

## 9. Source inspection

When the required information exists in checked-in source, inspect the actual
file/repository directly.

Prefer GitHub/API or targeted local file inspection over broad recursive
searches. Do not ask the user to run broad grep searches to discover behavior
that can be inspected directly.

Local commands are appropriate for generated build artifacts, environment
state, toolchain validation, and concrete reproduction. Use targeted commands.

## 10. Host/target dependency boundary

For host-native Linux build tools, normal Ubuntu/WSL development packages are
the supported dependency mechanism. Do not create project-local replacements,
fake prefixes, or vendored host libraries merely to avoid a required host
package.

Document host dependencies in docs/WSL-HOST-DEPENDENCIES.md.

This does not apply to PS4 target dependencies. A Linux/WSL package must never
be used as a substitute for a PS4 target library.

When a dependency is optional for the current bring-up milestone, classify it
first and do not install it merely to unblock an unnecessary feature.

## 11. Self-hosted PS4 CI

The project intends to use a self-hosted GitHub runner for reproducible
OpenOrbis/PS4-target build validation.

Until it exists:
- do not pretend GitHub-hosted CI can reproduce the OpenOrbis environment;
- use local WSL for the available build validation;
- keep commands reproducible so they can later be automated by the runner.

When the runner exists, CI should validate reproducible build/dependency paths
where practical. It does not replace local interactive debugging or actual PS4
runtime validation.

CI failures must be classified as:
- caused by the current change;
- infrastructure/environment related;
- flaky or unrelated/pre-existing.

Do not modify project code merely to hide infrastructure failures.

## 12. Documentation continuity

Documentation is part of implementation, not final cleanup.

After every meaningful phase that establishes a discovery, decision,
implementation result, validation result, blocker, correction, environment
change, or changed next action, update the appropriate specialized document.

Use the documentation map in docs/README.md.

Keep current state in STATUS.md, durable decisions in DECISIONS.md, build
knowledge in BUILD.md, architecture in ARCHITECTURE.md, investigations and
evidence in RESEARCH.md, and compact continuity in PORTING.md.

Do not turn every historical event into permanent current-state prose. When
facts become obsolete, remove or consolidate them rather than accumulating a
chronological memory dump.

## 13. Cross-conversation handoff

docs/CONTINUITY.md is the canonical handoff document.

At a handoff, it must describe the actual repository state, including:
- current GitHub main HEAD;
- relevant pinned external commits;
- validated facts and validation level;
- current blocker;
- important decisions and scope boundaries;
- exact next proposed step;
- relevant commands/validation procedure.

The handoff is context, not a substitute for verification.

A new conversation must read it and then independently verify its claims against
GitHub, AGENTS.md, this workflow, the relevant project documentation, and the
actual source/configuration.

If the repository state changes after the handoff is written, update the
handoff before the next handoff. Never knowingly leave a stale handoff as the
documented current state.

## 14. Completion criteria

A validated step is complete only when:
- the implementation is limited to the approved scope;
- appropriate validation has been performed;
- failures caused by the change are resolved;
- relevant documentation is current;
- the final diff has been audited;
- the branch has been pushed;
- the PR exists and its available CI has been checked;
- the user has been informed of the result;
- the user has explicitly approved merging before merge.

Do not silently change project direction to make an implementation fit the
documentation. If documentation and implementation diverge, identify the
divergence and resolve it deliberately.
