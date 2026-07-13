# VERIFICATION.md — Tapestry

> Target path in build repo: `/docs/VERIFICATION.md`
> One spec, two readers: the executor self-checks against it before declaring done;
> the independent Verifier runs it again at the gate in fresh context. Autonomous
> Mode: the Verifier IS the gate. Base: project-forge VERIFICATION.md template.

## 0. What the Verifier sees (and must NOT see)
Fresh context, only: PROJECT_SCOPE.md, the FULL current architecture
(ARCHITECTURE.md + every node it links to, assembled deterministically — never
traversed), the current milestone's criteria + DO-NOT-BUILD list, ACCEPTANCE.json,
this file, and the milestone diff. Never the executor's chat or plan.
**Vision-capable Verifier required from Milestone 0 onward — every milestone from
M2 has UI screenshots to judge.** Verdicts: PASS / PASS-WITH-NOTES / FAIL, always
with file:line references. Flag only what affects correctness, a stated criterion,
or the Check 5 floor; style preferences are notes, never grounds to withhold PASS.

## 0a. Staging
- Checkpoint A (plan sanity) — before building M1 (pipeline design) and M3
  (constellation approach): check the plan against SCOPE + ARCHITECTURE
- Checkpoint B (hard-part isolation) — M3 only: verify the deterministic layout
  function in isolation before UI wiring
- Checkpoint C (the gate) — every milestone, via /forge-verify. Non-negotiable

## 1. The eight checks (run in order)
1. **Acceptance criteria** — work from ACCEPTANCE.json, not prose. Every flipped
   `passes` must be backed by its cited evidence; verify the citation. Any edit
   outside passes/evidence = tampering = FAIL. Behavioural proof required —
   "tests pass" with no run output is a FAIL.
2. **Architecture conformance** — house conventions: all text access via
   LocalStore/TranslationService (UI never queries or fetches directly);
   deterministic ConstellationView (pure function of inputs, no randomness);
   VerseId `BBCCCVVV` scheme everywhere; no new pub.dev dependency without
   recorded approval; key handling per ARCHITECTURE.md.
3. **Scope policing** — diff outside the milestone's expected output, or anything
   on its DO-NOT-BUILD list → FAIL even if the code is good. New ideas belong in
   docs/PARKED.md.
4. **Regression** — prior milestones' criteria spot-checked; full prior test suite
   re-run on any change to data layer or shared logic; build 0 errors; analyze 0
   errors (warnings OK); weakening a deny/ask rule or hook = security regression.
5. **Never-shortcut floor** — input validation (esp. pipeline parsing of external
   data files); security (no key in code/commits/logs, no injection via reference
   strings); accessibility (44dp targets, labels, contrast on new UI); data-loss
   safety (pipeline never overwrites a good bible.db with a failed build — write
   temp, validate, swap).
6. **Tripwire audit** — confirm none crossed unapproved (CLAUDE.md list), and that
   the session's guard-presence canary result is recorded. Unconfirmed guards on
   an autonomous run = FAIL regardless of verdict.
7. **Debt ledger** — grep the whole diff for `forge-debt:`; assemble into the
   ledger in HANDOFF.md. Unmarked shortcut = hidden debt → PASS-WITH-NOTES at
   best, FAIL if it touches the Check 5 floor.
8. **Observable-outcome verification** — open every captured outcome and confirm
   it shows what the criterion says: screenshots for UI states (reachable by the
   real user path, not only direct navigation); stdout + exit codes for the
   pipeline; the generated bible.db for artifact criteria. From M5, at least one
   capture is a real browser load of the DEPLOYED GitHub Pages URL with a JS-error
   listener, origin asserted in the capture. Contradicting capture = FAIL, not a
   note.

## 2. Output format
Use the Forge Gate Report format verbatim (Verifier Report — Milestone X; verdict;
per-check lines with refs; debt ledger; severity-high notes escalate to FAIL;
bottom line). If you cannot cite it, it did not pass.

## 3. Running the gates (commands — Windows/Git Bash safe, jq-free)
- Build: `flutter build web` → exit 0 (plus `flutter build apk --debug` on
  milestones touching Android-specific code)
- Lint: `flutter analyze` → 0 errors (warnings acceptable)
- Tests: `flutter test` → all green
- Integration + capture: `flutter test integration_test` on a device/emulator,
  writing screenshots to `verification-shots/M[X]/<criterion>.png`. Playwright is
  NOT used — Flutter web renders to canvas and is invisible to DOM drivers
- Pipeline (M1+): `dart run tool/build_db.dart` → exit 0; smoke queries print to
  captured stdout in `verification-shots/M[X]/pipeline.txt`
- Network rule: the entire battery runs with no live external calls; the API layer
  is mocked. Burning API.Bible quota at a gate is itself a FAIL
- Deployed check (M5+): scripted real-browser load of the GitHub Pages URL,
  JS-error listener attached, origin asserted in the capture file
- Security checks proven as an unprivileged user would hit them — never via a
  bypass path

## 4. Debt ledger at handoff
Collect all `forge-debt:` markers per milestone into HANDOFF.md with file:line +
severity (low/med/high; high touches the Check 5 floor and blocks PASS).
**Cumulative budget (loop-level, checked by the run, not the Verifier): STOP for
human triage past 8 open entries or 3 medium-severity.**

## 5. Leanness floor check
Confirm the order was honoured: YAGNI → stdlib → platform feature → what's
installed → one line → then code. No new dependency without approval. Leanness
never excuses cutting a Check 5 item.
