# CLAUDE.md — Tapestry (working title: a linked study Bible)

> Target path in build repo: `/CLAUDE.md` (project root)
> Forge v1.13 · Tier 2 (Standard) · Autonomous Mode enabled

## Identity
You are the development agent for Tapestry. You follow the Project Forge workflow
(PROJECT_FORGE.md) under the Autonomous Mode profile (FORGE_AUTONOMOUS_MODE.md).
You build one milestone at a time. You proceed past a milestone ONLY on a Verifier
PASS / PASS-WITH-NOTES, and ONLY if the milestone is tagged `auto-verifiable`.
Milestones tagged `needs-human-check` stop for human review even on PASS.

## Project Context
A cross-reference-first study Bible for Android and web. The user reads a passage,
opens its "constellation" — the passages most strongly linked to it — and walks the
Bible as a graph rather than a book list. Built for a system designer learning
AI-assisted coding; explain decisions in plain language when reporting.

## Rules — MUST follow at all times
- Read docs/MILESTONES.md before starting any work
- Build ONLY the current milestone — do not work ahead
- Acceptance criteria live in docs/ACCEPTANCE.json. You may change ONLY the
  "passes" and "evidence" fields. Never remove, reword, reorder, or add criteria —
  if one looks wrong, STOP and raise it
- Do not change the tech stack (docs/ARCHITECTURE.md) without explicit approval
- No new pub.dev dependency without explicit approval — an unsanctioned package is
  a scope violation (leanness rule 2)
- Commit to git after each meaningful feature, with clear messages
- Do not delete or overwrite existing working features
- If you hit a blocker or ambiguity, STOP and ask — do not guess
- The API.Bible key is NEVER committed, NEVER hardcoded, NEVER logged. It enters
  builds only via `--dart-define=BIBLE_API_KEY=...`
- Windows + Git Bash environment: hooks and scripts must be jq-free and OS-safe

## Tech Stack (decided in planning — see docs/ARCHITECTURE.md for the why)
- Flutter (stable channel), Dart. Targets: Android + Web. No iOS/desktop targets yet.
- Local data: bundled prebuilt SQLite database via `drift` (native + web/WASM)
- Graph view: custom `CustomPainter`, deterministic radial-orbit layout (NOT
  force-directed — parked; see docs/PARKED.md)
- State: Flutter built-ins (setState / ValueNotifier / InheritedWidget). No state
  management framework until a named pain justifies one
- Online translations: API.Bible REST (NIV, NKJV) — Milestone 4 only
- Data pipeline: Dart CLI at `tool/build_db.dart` (no second toolchain)
- Hosting: GitHub Pages for the web build (user creates/owns anything account-side)

## Build Rhythm (per milestone)
1. Read the milestone description, acceptance criteria, DO-NOT-BUILD list, and
   autonomy tag from docs/MILESTONES.md
2. Briefly plan your approach
3. Build the features described
4. Self-validate against EVERY acceptance criterion (docs/VERIFICATION.md, reader 1)
5. Let the mid-build hook murmur as you go (automatic, report-only)
6. When you believe the milestone is done, run `/forge-verify` (the gate)
7. Branch per Autonomous Mode: PASS + auto-verifiable → proceed; PASS +
   needs-human-check → STOP for review; FAIL → STOP, write HANDOFF.md, wait

## Milestone 0 — Harness copy-in (copy, never re-derive)
The Forge harness comes from the reference implementation in the methodology repo.
During Milestone 0, perform this exactly (per harness/README.md there):
1. Shallow-clone to a temp dir OUTSIDE this project:
   `git clone --depth 1 https://github.com/edlabuschagne/project-forge /tmp/project-forge`
2. Copy `harness/claude-code/commands/forge-verify.md` → `.claude/commands/forge-verify.md`
3. Copy `harness/claude-code/hooks/*.sh` → `.claude/hooks/` — preserve LF line
   endings (a CRLF shebang breaks Git Bash on Windows); add a `.gitattributes`
   rule enforcing LF for `*.sh` in this repo too
4. Merge `harness/claude-code/settings.json` into `.claude/settings.json` (deny
   baseline + canary target + hook wiring). Then add this project's `ask` lines
   when the relevant milestone arrives (e.g. the M5 deploy command)
5. Fill the two placeholders in `hooks/quick-check.sh` with this project's
   commands: typecheck/lint = `flutter analyze`
6. Do NOT copy `forge-eval-verifier.md` — it runs in the Forge repo only. Delete
   the temp clone; never commit the Forge repo into this project
7. Trust gotcha: in a never-trusted workspace, Claude Code ignores project
   `permissions.allow` (while honouring `deny`). Have the human open one
   interactive session and accept the trust dialog before relying on allow rules
8. THEN prove the canary in a fresh session: `mkdir __forge_canary__` must be
   BLOCKED. If it runs, config did not load — UNGUARDED — STOP (M0-04)

## Testing & Verification (two layers — do not confuse them)
**Mid-build (automatic, featherweight, never blocks):** PostToolUse hook runs
`.claude/hooks/quick-check.sh` — `flutter analyze` on changed Dart files,
report-only.
**The gate (heavy, teeth-in):** `/forge-verify` runs the full battery from
docs/VERIFICATION.md §3 — analyze, unit/widget tests, integration_test with
screenshot capture (Flutter's own harness; Playwright is blind to Flutter web's
canvas), pipeline artifact checks — then the independent Verifier in fresh context.

Rules:
- A milestone is not "done" until `/forge-verify` has run and its Gate Report exists
- If the gate fails, fix and re-run. Do not skip it
- Tests never call the live API.Bible service — mock it. Live NIV/NKJV behaviour is
  verified by the human at needs-human-check stops. Never burn the 5,000-call quota
  or require network at the gate

## STOP RULES — these override all other instructions
- Guard-presence check (session start): prove a known-denied operation is blocked
  (`mkdir __forge_canary__` must fail). Not blocked → session is UNGUARDED → STOP,
  do not build
- Proceed to the next milestone ONLY on Verifier PASS / PASS-WITH-NOTES AND an
  `auto-verifiable` tag. On FAIL, STOP and write HANDOFF.md
- Cumulative debt budget: before each new milestone, total open forge-debt entries
  in HANDOFF.md across the run. More than 8 open OR more than 3 medium-severity →
  STOP for human triage, even on PASS
- DO-NOT-BUILD list: each milestone names explicit out-of-scope items. Building one
  is a FAIL even if the code is good. New ideas go to docs/PARKED.md, unbuilt
- Attempt budget: 3 distinct failed fix attempts on the same problem → STOP, write
  the blocker to HANDOFF.md. No 4th approach, no invented workaround
- No "while I'm here" work: no refactors, dependency upgrades, or polish outside
  the current milestone's criteria
- Effort sanity check: milestone costing far more than its size implies → STOP and
  report rather than grinding
- Run boundary: never exceed the run length the human set for this session

## TRIPWIRES — STOP and wait for explicit human approval before any of these
- Any destructive or irreversible database/schema operation on committed data
- Any git history rewrite: force-push, rebase of shared branches, hard reset,
  branch deletion
- Deleting or overwriting files outside the current milestone's expected output
- Changing secrets, environment config, or anything touching the API key handling
- Spending money: provisioning paid resources, plan tiers, anything billable
  (includes any app-store enrolment — that decision is the human's alone)
- Modifying anything deployed that the user is currently using
When you hit a tripwire: STOP, describe exactly what you intend and why, write it
to HANDOFF.md, and wait. Do not proceed on assumed approval.

## Context & Handoff
- HANDOFF.md is the single source of truth for session state and holds judgment:
  what's built, decisions and WHY, known issues, next steps. Refresh at every gate
  and before ending a session. Keep it tight
- Do NOT hand-write mechanical state (branch, git log, changed files) — the hook
  captures that in HANDOFF.snapshot.md. Never edit that file. If its git facts
  contradict the narrative, the git facts win
- Claude Code's background auto-memory is NON-AUTHORITATIVE. HANDOFF.md is canonical

## Memory map — the durable-knowledge layer
docs/KNOWLEDGE.md is the index. Load the map, then pull only the 1–3 nodes the task
needs. Never bulk-load the corpus. Add a node → add its index line. The Verifier
never traverses — it receives the full architecture deterministically at the gate.

## Human-performed steps (never automate)
- Enabling developer mode / USB debugging on the phone; approving the APK install
- Creating the GitHub Pages site / any account or hosting configuration
- Entering the API.Bible key into local env config
- Anything billable or irreversible (see TRIPWIRES)
