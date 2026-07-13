# HANDOFF.md — Tapestry

> Mechanical git state lives in HANDOFF.snapshot.md (auto-generated, never hand-edited).
> This file holds judgment: what's built, decisions and why, known issues, next steps.

## Current state
Milestone 0 (Bootstrap) **approved by the human** (2026-07-13) following its
PASS-WITH-NOTES gate. Now starting Milestone 1 (The data forge), which is
`auto-verifiable`.

## Gate result — /forge-verify, 2026-07-13
**Verdict: PASS-WITH-NOTES** (independent Verifier, fresh context). Full Gate Report
shared with the human in the session transcript. Summary:
- All 6 acceptance criteria (M0-01…M0-06) verified against real evidence in
  `verification-shots/M0/`; no tampering in `docs/ACCEPTANCE.json` (only
  `passes`/`evidence` changed).
- No scope creep, no tripwire crossed, canary proof confirmed.
- One note (not a FAIL): M0-03's screenshot was captured via a disclosed
  static-serve + Playwright workaround rather than Flutter's own `integration_test`
  harness — see debt ledger below. Verifier judged this a valid, non-conforming but
  non-contradicting capture.
- One immaterial wording drift flagged between MILESTONES.md and ACCEPTANCE.json on
  M0-06's text (pre-existing, not an executor edit).

## What's built
- Git repo initialized; `.gitignore` (secrets, build artefacts, IDE) and `.gitattributes`
  (`*.sh` forced LF) in place from commit zero.
- Flutter 3.44.6 (stable) + Android SDK 36.1 toolchain installed by the human; `flutter
  doctor` exits 0 for Android + web (Windows-desktop/Visual Studio is correctly red —
  not a target per ARCHITECTURE.md).
- Flutter skeleton scaffolded for Android + web only (`--platforms=android,web`),
  project name `tapestry`, org `com.edlabuschagne`. Default counter demo replaced with
  a minimal `TapestryApp`/`PlaceholderScreen` showing centered "Tapestry" text.
- `flutter analyze` — 0 issues. `flutter test` — 1/1 passing (asserts the placeholder
  text renders).
- `flutter build web` and `flutter build apk --debug` both exit 0.
- Forge harness copied in per the CLAUDE.md procedure: `.claude/commands/forge-verify.md`,
  `.claude/hooks/{quick-check,handoff-snapshot}.sh` (confirmed LF, no CR bytes),
  `.claude/settings.json` (deny baseline + canary target + hook wiring, no `ask` lines
  yet — none are due until M5's deploy step). `quick-check.sh` placeholders filled:
  `TYPECHECK_CMD="flutter analyze"`, `LINT_CMD=""` (analyze covers both roles for Dart;
  running it twice per edit would be redundant). Temp clone of project-forge deleted;
  `forge-eval-verifier.md` was not copied (per its own instruction — Forge-repo only).
- GitHub Actions CI (`.github/workflows/ci.yml`): `flutter analyze` + `flutter test` on
  every push/PR, stable channel.

## Decisions and why
- **Git identity corrected mid-session.** The global git config defaulted to the
  `afrikapro` GitHub identity; this repo needed `edlabuschagne` (the active `gh` account,
  and the account the project-forge clone URL in CLAUDE.md points at). Set as a *local*
  override (`git config user.name/email`, no `--global`) so other repos on this machine
  are unaffected.
- **App org id:** `com.edlabuschagne` chosen for the Android applicationId
  (`com.edlabuschagne.tapestry`). Not a tech-stack change, no approval needed — just a
  namespacing choice for a personal-use app.
- **M0-03 evidence method:** no Android emulator/device exists yet (`flutter emulators`
  → none), so the "app launches" screenshot was captured by serving the built
  `build/web` bundle statically and screenshotting it with a throwaway Playwright script
  (pixel capture only, not DOM inspection — consistent with VERIFICATION.md's warning
  that Playwright is blind to Flutter web's *rendered content*, which doesn't apply to a
  raw screenshot). This is **not** the Flutter integration_test harness VERIFICATION.md
  specifies for the formal gate. Logged as debt below; revisit at Milestone 2, which
  requires a real device/emulator anyway for the airplane-mode criterion.

## Debt ledger (forge-debt)
- **[low]** M0-03 screenshot captured via ad hoc static-serve + Playwright instead of
  Flutter's own `integration_test` on-device harness, because no Android
  emulator/device was available in this session. No `// forge-debt:` code marker (this
  is a verification-process shortcut, not a code shortcut) — recorded here directly.
  Resolve by M2: create an AVD (or use the user's phone) and re-capture M0-03 (and all
  of M2's screenshots) through `flutter test integration_test`.

Cumulative: 1 open, low severity. Well under the STOP threshold (8 open / 3 medium).

## Known issues
None outstanding in the built code.

## Next steps
1. Build Milestone 1: `tool/build_db.dart`, ingesting BSB text + OpenBible.info
   cross-references into `assets/bible.db` (drift/SQLite, per ARCHITECTURE.md).
2. Carry forward the one open debt item: get a real Android emulator or the phone
   connected by Milestone 2 (it needs one anyway for the airplane-mode criterion),
   and re-capture M0-03 plus M2's screenshots through `flutter test integration_test`
   instead of the ad hoc method used here.
