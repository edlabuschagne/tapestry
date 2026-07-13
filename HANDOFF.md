# HANDOFF.md — Tapestry

> Mechanical git state lives in HANDOFF.snapshot.md (auto-generated, never hand-edited).
> This file holds judgment: what's built, decisions and why, known issues, next steps.

## Current state
Milestone 0 approved by the human (2026-07-13). Milestone 1 (The data forge) built,
self-checked, awaiting its `/forge-verify` gate. `auto-verifiable` — proceeds to
Milestone 2 on its own PASS/PASS-WITH-NOTES, no human stop required (unlike M0).

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

## Milestone 1 — what's built
- **Data sources** (researched, verified live, vendored — see `tool/data/README.md`):
  BSB text + section headings from `bible.helloao.org/api/BSB/complete.json` (public
  domain, 66 books, 31,086 verses — confirmed exactly matches M1-02's threshold);
  cross-references from `a.openbible.info/data/cross-references.zip` (CC-BY, 344,799
  rows). Both vendored as committed files so the pipeline and its tests run offline
  and deterministically — no network at build or gate time.
- **Domain models** (`lib/domain/`): `book_index.dart` (canonical 66-book order +
  both source's own book-abbreviation schemes), `verse_id.dart` (BBCCCVVV codec per
  ARCHITECTURE.md), `passage.dart`, `edge.dart`.
- **Pipeline** (`tool/build_db.dart` + `tool/src/`): parses BSB into verses + headings
  -> passages (a heading always starts a new passage; passages never cross book
  boundaries; a book with no heading before its first verse — not the case anywhere
  in the current BSB dump — falls back to the book's own name rather than crashing);
  parses and validates cross-reference rows (malformed rows rejected and counted, not
  fatal); aggregates verse-level refs to undirected passage-level edges (self-edges
  and net non-positive weight dropped); writes `assets/bible.db` via `package:sqlite3`
  with a temp-write -> validate -> atomic-swap sequence so a failed build can never
  clobber a good one (Check 5 floor).
- **Real run**: 66 books, 31,086 verses, 3,083 passages, 199,464 edges. Isaiah 53:5's
  passage is "The Suffering Servant" (Isaiah 53:1-53:8); its single top-weighted edge
  points to 1 Peter 2:21-2:25 ("Christ's Example of Suffering"), weight 714 — a
  theologically apt result the data produced on its own, not curated.
- **Tests** (26 total, all green): `test/domain/verse_id_test.dart` (codec),
  `test/tool/bsb_source_test.dart` (passage segmentation incl. cross-chapter
  boundaries, footnote/poem text extraction, fallback heading), `test/tool/
  cross_ref_source_test.dart` (ranges, malformed rows, negative votes),
  `test/tool/edge_builder_test.dart` (aggregation, self-edge/noise dropping, no
  orphans), `test/tool/build_db_acceptance_test.dart` (runs the real vendored data
  through the pipeline and asserts M1-02 through M1-06 directly).

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
- **Vendored, not fetched-at-build-time, pipeline inputs.** Keeps `dart run
  tool/build_db.dart` and its tests network-free, matching the gate's general
  no-live-calls posture, at the cost of ~15MB of committed data files.
- **Edges stored undirected.** A cross-reference's stated direction (`From Verse` ->
  `To Verse`) is evidence of a link either way; the constellation view (M3) wants
  "neighbours of a passage" regardless of which side of the original reference it
  came from, so edges are canonicalized to (min id, max id) and summed rather than
  kept as two directed rows.
- **`sqlite3` added as a dependency now; `drift` deferred to M2.** ARCHITECTURE.md
  already decided "drift over a bundled prebuilt SQLite file" — `sqlite3` is the raw
  writer this milestone's pipeline needs and is drift's own underlying dependency, so
  this isn't a new/unsanctioned package. `drift` itself (the app's query layer) stays
  out until M2 actually reads the database, keeping M1 scoped to just the pipeline.

## Debt ledger (forge-debt)
- **[low]** M0-03 screenshot captured via ad hoc static-serve + Playwright instead of
  Flutter's own `integration_test` on-device harness, because no Android
  emulator/device was available in this session. No `// forge-debt:` code marker (this
  is a verification-process shortcut, not a code shortcut) — recorded here directly.
  Resolve by M2: create an AVD (or use the user's phone) and re-capture M0-03 (and all
  of M2's screenshots) through `flutter test integration_test`.
- **[low]** `tool/src/cross_ref_source.dart` (`_resolveVerseRefStart`) — a cross-
  reference range (e.g. `Prov.8.22-Prov.8.30`) resolves to its start verse's passage
  only, not every passage the range touches. Ranges rarely cross a BSB passage
  boundary, so this affects which single passage a handful of edges attach to, never
  whether a reference resolves at all. Marked inline with `// forge-debt`.

Cumulative: 2 open, both low severity. Well under the STOP threshold (8 open / 3
medium).

## Known issues
- One OpenBible.info cross-reference row (Gen.22.10 -> Isa.53.6-Isa.53.12 chain
  passes fine; the actual failure is a reference touching **3 John 1:15**) doesn't
  resolve against BSB — a well-known versification split where some traditions divide
  3 John's final verse (BSB's single verse 14) into two. Handled gracefully: the row
  is rejected and counted (1 of 344,799), not a crash. Not a bug, not debt — Check 5
  validation working as designed.

## Next steps
1. Run `/forge-verify` for Milestone 1 (auto-verifiable — proceeds to Milestone 2 on
   its own PASS/PASS-WITH-NOTES).
2. Carry forward the M0-03 debt item: get a real Android emulator or the phone
   connected by Milestone 2 (it needs one anyway for the airplane-mode criterion),
   and re-capture M0-03 plus M2's screenshots through `flutter test integration_test`
   instead of the ad hoc method used here.
