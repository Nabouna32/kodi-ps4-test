# Kodi PS4 Port — Documentation Map

This directory is the project's durable technical memory. Git is the source of truth for implementation; these documents record validated decisions, current state, build knowledge, architecture, and research.

## Mandatory startup

For every new conversation, read in this order:

1. AGENTS.md — repository-level mandatory rules.
2. WORKFLOW.md — mandatory operational workflow.
3. CONTINUITY.md — current cross-conversation handoff.
4. STATUS.md — current state and next action.
5. BUILD.md — host, toolchain, build workflow and blockers.
6. Other documents relevant to the task.

A new conversation must independently verify the handoff and documentation against
the current GitHub repository before modifying anything. WORKFLOW.md is normative:
it is not optional background documentation.

## Read order for project context

After the mandatory startup documents, consult:

- DECISIONS.md — durable project decisions.
- ARCHITECTURE.md — current architecture and boundaries.
- RESEARCH.md — investigations, evidence and open questions.
- PORTING.md — compact continuity index.
- WSL-HOST-DEPENDENCIES.md — host package inventory and evidence, when build work requires it.

## Documentation rules

- Record meaningful discoveries, decisions, implementation results, validation
  results, blockers, corrections, environment changes and changed next actions.
- Separate facts, hypotheses, decisions and experimental results.
- Never promote an unverified hypothesis to a fact.
- Keep current state in STATUS.md rather than burying it in a chronological log.
- Keep build/toolchain details in BUILD.md, architecture in ARCHITECTURE.md,
  durable decisions in DECISIONS.md, and investigations in RESEARCH.md.
- Keep PORTING.md as an index rather than a second copy of every document.
- Keep CONTINUITY.md as a concise handoff, not a permanent transcript of the
  conversation.
- When historical information becomes obsolete, remove or consolidate it
  instead of accumulating an ever-growing chronological memory.
- For non-trivial porting questions, follow the documented comparison workflow:
  official Kodi → PS5 reference → current PS4/OpenOrbis information → explicit
  comparison → minimal PS4 adaptation → executable validation.
- Treat PS5 code as evidence of an integration pattern, never as proof that the
  same API or behavior exists on PS4.
