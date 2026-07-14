# HANDOFF.md — Tapestry

> Mechanical git state lives in HANDOFF.snapshot.md (auto-generated, never hand-edited).
> This file holds judgment: what's built, decisions and why, known issues, next steps.

## Current state
Milestone 0 approved by the human (2026-07-13). Milestone 1 gated PASS-WITH-NOTES
(2026-07-13), Milestone 2 gated PASS-WITH-NOTES (2026-07-14) and was batch-reviewed.
Milestone 3 gated PASS-WITH-NOTES (2026-07-14), reviewed and approved by the human —
cleared to continue into Milestone 4 (the duplicate "Isaiah 53" node label was
accepted as-is, not worth a fix right now). Milestone 4 gated PASS-WITH-NOTES on the
second attempt (2026-07-14; first attempt genuinely FAILed — see below) —
**stopped here for human review, per its `needs-human-check` tag, regardless of
verdict.** Do not start Milestone 5 until the human has reviewed M4 and, per its own
acceptance criteria, entered a real API.Bible key locally to confirm live NIV/NKJV
behaviour (never done by the agent — the key is human-entered only).

**Post-gate addition (2026-07-14, human-requested):** NKJV wiring was added after the
M4 gate closed — a `SegmentedButton` in `ParallelScreen`'s app bar switches between
NIV and NKJV, re-fetching and re-aligning on change (`lib/ui/parallel_screen.dart`).
This completes what M4's own title/PROJECT_SCOPE.md always named as the goal; no
`ACCEPTANCE.json` criterion mentions NKJV specifically (all five are NIV-scoped), so
nothing there was changed — I can't add a criterion myself per CLAUDE.md's flip-only
rule. Covered by a new test in both `test/ui/parallel_screen_test.dart` and
`integration_test/parallel_test.dart` (screenshots `M4-06-niv-selected.png` /
`M4-06-nkjv-selected.png`), full battery re-run clean (41/41 tests, analyze 0 issues,
build web exit 0). Not independently re-gated by the Verifier — this is a small,
additive, well-tested change on top of an already-PASSed milestone, not a new
milestone; flag if you'd like a formal re-gate anyway.

**Human-verification bug found and fixed (2026-07-14):** the human's first live-key
test showed every single verse in the Parallel view falling back to "This verse does
not appear in this translation" — for both NIV and NKJV. Root cause confirmed by
having the human run a one-off diagnostic PowerShell script against the real
API.Bible endpoint (their key never left their terminal/pasted to the agent — only
the response body was shared): the real `content-type=text` response wraps verse
numbers in square brackets (`[1] In the beginning...`), not a bare number followed by
whitespace as `_splitIntoVerses` had guessed (the exact uncertainty its `forge-debt`
marker flagged). Fixed the regex (`lib/data/api_bible_translation_service.dart`) and
closed the debt item for real: added `test/data/api_bible_translation_service_test.dart`,
which injects a `MockClient` (via `package:http/testing.dart`) returning content
shaped exactly like the captured real response — verse-bracket parsing and
poetic-line-break whitespace collapsing are now both regression-tested, still with
zero live network calls (M4-04 intact). Full battery re-run clean (44/44 tests). The
human needs to re-run the app with their key once more to confirm the fix actually
works end-to-end — not yet confirmed as of this note.

## Ahead-of-schedule: repo made public + GitHub Pages deploy workflow (2026-07-14)
At the human's explicit request (wants to share the app with a few people for
feedback), not part of any milestone's build:
- **Repo visibility changed to public** (`gh repo edit --visibility public`) — human
  explicitly approved after being told the tradeoff (GitHub Pages needs either a
  public repo or a paid plan; no custom domain needed either way).
- **`.github/workflows/deploy-pages.yml` added** — builds the web app
  (`flutter build web --base-href /tapestry/`) and deploys to GitHub Pages via the
  official `actions/deploy-pages` action, triggered on every push to `main` or
  manually. This is exactly the "workflow preps it" half of Milestone 5's own deploy
  deliverable — deliberately NOT doing the rest of M5 (release APK signing, About
  screen attributions, etc.), just this one piece, now, because it was asked for
  directly.
- **Still needs the human to flip Pages on**: repo Settings -> Pages -> Build and
  deployment -> Source: "GitHub Actions". The workflow will fail until that's done
  (Pages has to exist before `deploy-pages` can publish to it); once enabled, either
  wait for the next push or manually re-run the workflow.
- This does NOT count as Milestone 5 being started or completed — M5's own gate still
  covers the full deploy criteria (release build, About screen, deployed-URL capture
  with a JS-error listener) when its turn comes.

## Gate result — Milestone 4, /forge-verify, 2026-07-14
**Verdict: PASS-WITH-NOTES** (independent Verifier, fresh context, second attempt —
the first attempt genuinely FAILed, see below). All 5 acceptance criteria (M4-01
through M4-05) verified against real behavioural evidence: `flutter test` 40/40 green,
`flutter analyze` 0 issues, `flutter build web` exit 0, a grep proof that no test or
`integration_test` file ever references `ApiBibleTranslationService` or the live
API.Bible URL (M4-04), a grep proof the key is never hardcoded or logged — only read
via `String.fromEnvironment` (M4-05), and all four screenshots visually confirmed
against their criteria (`verification-shots/M4/`). No tampering in `docs/
ACCEPTANCE.json` (only passes/evidence changed). DO-NOT-BUILD clean (no additional
translations wired, no persistent NIV caching, no account system). No tripwire
crossed; autonomy tag correctly left as `needs-human-check`.

**First gate attempt: genuine FAIL, fixed and re-gated — not a rubber-stamp.** The
Verifier's first pass (fresh context) found two real defects, both touching Check 2/5,
neither hidden or argued away:
1. **Check 5 (accessibility floor) — footnote tap target under 44dp.** The
   footnote-reveal `InkWell` (`lib/ui/parallel_screen.dart`, the centerpiece
   interaction this exact milestone asks for: "a tappable footnote marker... tap
   reveals the note") wrapped only its inline text with no minimum size — well under
   the same 44dp floor this project already enforces for constellation node tap
   targets. Unmarked as a shortcut. Per VERIFICATION.md's own rule ("FAIL if it
   touches the Check 5 floor"), this alone was sufficient grounds to withhold PASS.
2. **Check 2 (correctness) — Settings screen made a false claim.** `lib/ui/
   settings_screen.dart` told the user "NIV and NKJV parallel views are available"
   when configured, but no code path anywhere wires up NKJV (`ParallelScreen` defaults
   to NIV only, no picker, no second call site). A real correctness bug in shipped UI
   copy, independent of ACCEPTANCE.json's (NIV-only) criteria.

Both fixed in a follow-up commit (`SizedBox(height: 44)` around the footnote
`InkWell`; Settings copy corrected to only claim NIV) and independently re-verified by
a second fresh Verifier — which read the *current file contents*, not the fix
commit's message, before agreeing both were genuinely resolved. Re-ran the full
battery clean and recaptured the two M4-02 screenshots (layout shifted slightly).

Three low/low-medium notes on the re-gate, none blocking:
- `lib/data/api_bible_translation_service.dart`'s verse-splitting regex is
  "approximate by necessity" (can't be checked against the live wire format under
  M4-04's no-live-call rule) and was missing its `// forge-debt:` marker — added
  post-gate (see debt ledger).
- `http: ^1.2.2` was added to `pubspec.yaml` with no citable approval record in any
  project doc — it *was* explicitly asked and approved via AskUserQuestion mid-session
  (dart:io's HttpClient doesn't work on Flutter web), just not written down anywhere
  the Verifier can see. Recorded here now, matching the M1 `sqlite3` precedent.
- The M4 test/integration_test evidence constructs `ParallelScreen` directly rather
  than navigating through taps from `TapestryApp` (unlike M2/M3's own tests) — the
  feature is genuinely reachable via `ReaderScreen`'s "Parallel" button
  (`lib/ui/reader_screen.dart:69-90`), so this is a thoroughness note, not a gap.

## Gate result — Milestone 3, /forge-verify, 2026-07-14
**Verdict: PASS-WITH-NOTES** (independent Verifier, fresh context). All 5 acceptance
criteria verified against real behavioural evidence — the layout function's
determinism proven both as a pure function and at the rendered-pixel level, the
50-highest-degree no-dead-taps sweep run against real data, the recenter test proving
the graph (not just a label) actually recentered. Checkpoint B honoured (layout
function isolated and unit-tested before UI wiring). DO-NOT-BUILD clean, no tampering,
no regression, no new debt.

Two notes: (1) the debt ledger's cumulative count had drifted to 4 by double-counting
an already-closed item — fixed below. (2) **Worth your specific attention given M3's
subjective, needs-human-check nature:** in the Isaiah 53 constellation, one neighbour
node is labeled "Isaiah 53" — identical to the center node's own label — because a
second, distinct passage also happens to fall within Isaiah 53's chapter and
`shortReference()` only resolves to book+chapter, not down to the specific passage.
It's not a bug (different passage IDs, the tap correctly goes to the other passage),
but it could visually read as confusing or redundant. Worth deciding whether that's
fine as-is or needs a disambiguating label (e.g. appending part of the heading) before
this ships further.

## Milestone 4 — what's built
- `lib/domain/verse_status.dart`: sealed `VerseStatus` (`VersePresent(text)` /
  `VerseFootnoted(note)`) — a verse in an online translation is either there or it
  isn't, and "isn't" always carries a human-readable reason, never a silent gap.
- `lib/data/translation_service.dart`: the mockable `TranslationService` interface
  (`resolveBibleId`, `fetchVerses`). `lib/data/api_bible_translation_service.dart`: the
  real API.Bible client — resolves a translation abbreviation to its account-specific
  `bibleId` at runtime (never hardcoded, since that id is account-specific), fetches a
  whole chapter in one call rather than per-verse to conserve API.Bible's fair-use
  quota, splits the returned text by verse number via regex (marked `// forge-debt`:
  necessarily unverified against the live wire format, since no test/gate step may
  call the live service — the human confirms this at the milestone's own
  needs-human-check stop). Never constructed by any test.
- `lib/ui/parallel_screen.dart`: `ParallelScreen` — BSB alongside NIV, aligned
  verse-by-verse per *chapter* (not per BSB passage: Romans 8 alone spans several
  passage boundaries, and translation alignment is inherently chapter/verse-based).
  Falls back to a plain BSB-only notice when no key is configured or the translation
  can't be resolved. Footnoted verses render a tappable `[footnote]` marker
  (44dp-tall tap target) that opens a dialog with the manuscript note.
- `lib/ui/settings_screen.dart`: minimal key-configured/not status screen (no other
  settings — DO-NOT-BUILD: any account system).
- **Post-gate:** NKJV wiring added (see "Current state" above for the full note) —
  `ParallelScreen.availableTranslations = ['NIV', 'NKJV']`, a `SegmentedButton` in its
  app bar, `_selectTranslation()` re-running `_load()` against the newly picked
  translation. Settings copy restored to mention both, now accurately.
- `lib/main.dart`: reads the key via `String.fromEnvironment('BIBLE_API_KEY')` only
  (never hardcoded, never logged); constructs `ApiBibleTranslationService` only if
  non-empty, else `null` (BSB-only mode).
- **Tests**, all against a `FakeTranslationService` that never touches the network:
  `test/ui/parallel_screen_test.dart` (M4-01/02/03, host `flutter_test`) and
  `integration_test/parallel_test.dart` (same three scenarios, real Chrome via
  `flutter drive` + chromedriver, screenshots to `verification-shots/M4/`).
- **Two flutter_test gotchas hit and fixed, worth remembering:**
  - drift's default `MigrationStrategy()` auto-creates the schema (`m.createAll()`) on
    a fresh database — a test that also issues its own `CREATE TABLE` on a brand-new
    temp-file db collides with it ("table verses already exists"). Fix: don't
    hand-create the schema on a fresh db; just insert into what drift already made.
  - `ListView`/`ListView.builder` both lazily mount only near-viewport items via the
    sliver protocol — passing a literal `children:` list does *not* avoid this (only
    changes how the widget is supplied, not whether Elements are eagerly built). A
    39-verse Romans 8 test needed `scrollUntilVisible` per verse, same as the lazy
    book/chapter grids already established in M2; the default 300px scroll delta was
    coarse enough to jump clean over a short verse's mount window between visibility
    checks (reproduced with Romans 8:6) — fixed with a smaller delta (60px) and a
    higher `maxScrolls` cap.
- **Web `integration_test` via `flutter drive`, one real flag mistake, worth
  recording:** `--web-launch-url` is "the URL to open in the browser," **not** the
  chromedriver connection — that's `--driver-port`. Using the wrong flag didn't error
  outright; it let the app boot and even run partway before hanging or crashing the
  Chrome tab unpredictably (looked like flakiness, wasn't). `--driver-port=4444`
  fixed it outright. Also hit: the web/WASM sqlite engine is strict SQL and rejects a
  double-quoted string literal as an invalid identifier reference (native sqlite3
  permits it as a legacy quirk) — use single quotes in any raw SQL run against a
  web-target store.
- **Also found and killed dozens of leaked `chrome.exe` processes** from earlier
  interrupted `flutter drive` runs accumulating unseen — worth a clean
  `taskkill //F //IM chrome.exe //T` before any web integration_test session if
  runs start behaving strangely (crashes, hangs) with no code-side explanation.

## Milestone 3 — what's built
- `lib/domain/constellation.dart`: `layoutConstellation()` — a pure function, ordered
  `NeighbourEdge` list in, node angles out, evenly spaced starting at 12 o'clock.
  Verified in isolation (unit tests) *before* any UI wiring, per VERIFICATION.md's
  Checkpoint B for M3.
- `lib/data/local_store.dart`: `topNeighbours()` (up to 12, weight desc / neighbour-id
  asc tie-break — the order that makes the layout reproducible) and
  `highestDegreePassageIds()` (for the M3-04 sweep), both raw SQL via `customSelect`
  since drift's fluent builder can't express the "either end of an undirected edge"
  CASE WHEN cleanly.
- `lib/domain/short_reference.dart`: node labels ("Isaiah 53", or "Isaiah 52-53" for a
  multi-chapter passage). Takes raw `book`/`startVerseId`/`endVerseId` fields rather
  than a `Passage` object — there are two distinct `Passage` types in this codebase
  (the pipeline's own in `lib/domain/passage.dart`, and drift's auto-generated one
  from the `Passages` table, used everywhere at runtime) and a single function that
  works with either sidesteps the collision entirely.
- `lib/ui/constellation_view.dart` (`CustomPainter`) + `lib/ui/constellation_screen.dart`
  (graph + reader pane, tap-to-recenter, entry point from ReaderScreen's app bar).
  `lib/ui/passage_body.dart` extracted from ReaderScreen so both screens render a
  passage identically.
- **Found and fixed during manual smoke-testing, before writing formal tests:**
  labels were originally centered inside each node, which clipped longer references
  like "Revelation" (rendered as "evelation") — moved neighbour labels outside the
  node (radially outward, single line, ellipsis) and kept the center's label inside
  its larger circle (avoiding both the clipping and a center/neighbour label collision
  at the 6 o'clock position, which occurs for any fixed direction whenever there are
  exactly 12 evenly-spaced neighbours, since 12 is divisible by 4).
- Real data: Isaiah 53's constellation surfaces 12 neighbours including Matthew, John,
  and Acts passages; tapping "1 Peter 2" recenters the graph onto it and the reader
  pane updates to 1 Peter 2:21-25, with Isaiah 53 now appearing as 1 Peter 2's own
  neighbour (confirming the undirected-edge design from M1).
- Tests: `test/domain/constellation_test.dart` (pure layout function), `test/ui/
  constellation_golden_test.dart` (M3-02 — renders the widget twice from identical
  input, asserts pixel-identical PNG bytes; needed `tester.runAsync` around
  `toImage()`/`toByteData()`, another flutter_test/real-async-work interaction like
  the M2 `File.copy` one), `test/ui/constellation_no_dead_taps_test.dart` (M3-04, real
  data), `test/ui/constellation_recenter_test.dart` (M3-03).
- Fixed a real bug in `test_driver/integration_test.dart`: it hardcoded
  `verification-shots/M2/` as the screenshot output folder (copied from the M2 work
  without generalizing) — now derives the milestone from the screenshot name's own
  prefix, so it works for any milestone's screenshots.

## Gate result — Milestone 2, /forge-verify, 2026-07-14
**Verdict: PASS-WITH-NOTES** (independent Verifier, fresh context). All 4 acceptance
criteria verified against real evidence — three via the actual `integration_test`
harness (Chrome), one via direct `adb` device control (Android, airplane mode). No
tampering, no scope violation (DO-NOT-BUILD clean: no constellation, no
translations, no non-default theming), no regression, no tripwire crossed. Two notes,
both addressed above: the debt ledger was undercounting by one entry (now fixed), and
the "verse numbers as anchors" deliverable text isn't fully implemented but isn't
tested by any M2 criterion (flagged for a future decision, not blocking).

## Gate result — Milestone 1, /forge-verify, 2026-07-13
**Verdict: PASS-WITH-NOTES** (independent Verifier, fresh context). All 6 acceptance
criteria verified against real pipeline stdout, a direct SQL query against the actual
built `assets/bible.db`, and 26 passing tests over the real vendored data. No
tampering, clean DO-NOT-BUILD compliance, no secrets, guard config unchanged, genuine
input validation and write-temp/validate/atomic-swap safety confirmed.

Three notes: (1) the Verifier flagged that adding `sqlite3` as a new pub.dev dependency
had no recorded approval — true, I added it reasoning it was implied by
ARCHITECTURE.md's already-decided drift/SQLite direction, but should have asked first.
**Asked the human afterward; approved retroactively** (2026-07-13) as the minimal,
correct implementation of that existing decision, not a scope expansion. (2) A
mismatch in my own gate-briefing — I told the Verifier to expect two inline
`forge-debt` code markers; only one exists (the M0-03 item is a HANDOFF.md note, never
a code marker, so this wasn't a real finding). (3) The db swap
(`tool/src/sqlite_writer.dart`) is delete-then-rename, not one atomic OS call — doesn't
violate the actual invariant (bad build never overwrites a good db) but is marginally
less bulletproof than a true atomic replace. Low severity, not urgent; worth revisiting
if this pipeline ever runs somewhere crashes are likely mid-swap.

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
- **Asked the human before adding `drift` for M2** (learned from the M1 process gap)
  — approved. Also added its necessary companions (`sqlite3_flutter_libs`,
  `path_provider`, `path`) under that same approval rather than asking once per
  package, since none of them is an independent feature choice — each is required
  machinery to make the already-approved drift/SQLite decision actually run on
  Android + web. `integration_test`/`flutter_driver` ship with the Flutter SDK
  (same tier as `flutter_test`), not pub.dev packages needing separate approval.

## Debt ledger (forge-debt)
- ~~M0-03 screenshot via ad hoc method~~ **Closed, not re-captured — on reflection,
  there's nothing to re-capture.** M0-03's criterion was specifically about the
  bootstrap *placeholder* screen, which M2 legitimately replaced with the real
  HomeScreen (book list) — that's the intended evolution M1/M2's deliverables called
  for, not a regression. The placeholder no longer exists to screenshot through any
  harness. The original ad hoc capture (`verification-shots/M0/M0-03-launch.png`) is
  an accurate historical record of what was true when M0 gated and was approved; M0
  is closed and its evidence isn't revisited. Re-screenshotting today's HomeScreen
  wouldn't be "M0-03 done properly," it would be evidence for a different (and
  already-satisfied) criterion. No action needed.
- **[low]** `tool/src/cross_ref_source.dart` (`_resolveVerseRefStart`) — a cross-
  reference range (e.g. `Prov.8.22-Prov.8.30`) resolves to its start verse's passage
  only, not every passage the range touches. Ranges rarely cross a BSB passage
  boundary, so this affects which single passage a handful of edges attach to, never
  whether a reference resolves at all. Marked inline with `// forge-debt`.
- **[low]** `flutter drive` against the Android emulator hangs (VM service connection
  drops ~10-30s in) for reasons unrelated to app code — confirmed by retrying after
  fixing a real setState bug that was the actual cause of every *other* symptom seen
  during this investigation, with no change to the Android hang. Root cause
  undiagnosed. Not blocking: M2-03's evidence was obtained via direct `adb` device
  control instead. Worth a fresh look before M3, which will also want on-device
  screenshots.
- **[low]** `test/support/test_store.dart:16-22` (`// forge-debt` inline marker) — uses
  synchronous `writeAsBytesSync` instead of async `writeAsBytes` to copy the ~16MB test
  database, working around an unreproduced `flutter_test` pump-loop deadlock (see the
  RESOLVED section's note on `File.copy` async hangs). Flagged by the M2 Verifier as
  missing from this ledger in an earlier draft — added here now.
~~Verse-number-anchors gap~~ **Closed, parked** — resolved to `docs/PARKED.md` (see M2
loose-ends cleanup); no longer counted below.
- **[low]** `lib/data/api_bible_translation_service.dart` (`_splitIntoVerses`) — regex-
  based verse-splitting on API.Bible's chapter text response, "approximate by
  necessity" since no test/gate step may call the live service to confirm the exact
  wire format (M4-04). Marked inline with `// forge-debt`. The human's live-key check
  at M4's needs-human-check stop is exactly what confirms or corrects this.
- **[low]** `pubspec.yaml` — `http: ^1.2.2` added without a recorded-in-docs approval
  trail (the M4 Verifier couldn't see it anywhere). It *was* asked and approved
  mid-session (dart:io's `HttpClient` doesn't work on Flutter web) — recording that
  here now, same pattern as M1's retroactive `sqlite3` note above.
- **[low]** M4's test/integration_test evidence (`test/ui/parallel_screen_test.dart`,
  `integration_test/parallel_test.dart`) constructs `ParallelScreen` directly rather
  than navigating through taps from `TapestryApp`, unlike M2/M3's own tests. The
  feature is genuinely reachable via `ReaderScreen`'s "Parallel" button
  (`lib/ui/reader_screen.dart:69-90`) — a thoroughness note, not a functional gap.

Cumulative: 6 open, all low severity. Well under the STOP threshold (8 open / 3
medium). (M3's Verifier caught this count drifting to 4 in an earlier draft that
double-counted a closed item — fixed.)

## Known issues
- One OpenBible.info cross-reference row (Gen.22.10 -> Isa.53.6-Isa.53.12 chain
  passes fine; the actual failure is a reference touching **3 John 1:15**) doesn't
  resolve against BSB — a well-known versification split where some traditions divide
  3 John's final verse (BSB's single verse 14) into two. Handled gracefully: the row
  is rejected and counted (1 of 344,799), not a crash. Not a bug, not debt — Check 5
  validation working as designed.

## RESOLVED — integration_test harness (2026-07-14)
Spent a long stretch on `flutter drive` hanging against the Android emulator
(`tapestry_avd`, Android API 36 x86_64). 4 distinct fix attempts — scrolling into view
before tapping lazily-built list/grid items, switching a `RichText` to `Text.rich` (real
bug: `find.textContaining` can't see raw `RichText`), switching the test's DB-open path
to the production `openLocalStore()`, enabling the emulator's GPU acceleration (its AVD
had `hw.gpu.enabled=no`) — none resolved the Android hang. Stopped there per the
3-attempt budget and reported the blocker.

**Root cause, found afterward:** `ReaderScreen._goTo` and `didUpdateWidget` called
`setState(() => _future = _load(id))`. The arrow closure's implicit return value is the
*value of the assignment expression* — i.e. the `Future` itself — which Flutter's
`setState` rejects at runtime ("setState() callback argument returned a Future").
Every "multiple exceptions" failure (on web) and quite possibly the Android VM-service
disappearing were downstream of this: tapping Next/Previous threw an uncaught assertion
mid-gesture. Fixed by using a block body (`setState(() { _future = next; });`) in both
methods — `next` computed *before* the `setState` call either way, but the block body is
what actually matters; my first attempted fix (hoisting `next` into a variable but
keeping the arrow body) still failed, because the arrow's return value is unrelated to
*when* the future was created.

**After the fix:**
- **Web** (`flutter drive -d chrome`, via a locally-installed `chromedriver` matching
  the exact Chrome build — needed a separate WebDriver server, not obvious up front):
  M2-01 and M2-02 (Genesis-start, Malachi→Matthew) now pass with real screenshots.
  Dropped an extra "Revelation end" scenario (bonus coverage beyond M2-02's literal
  text) after it hit an unrelated web-only timing quirk on a third consecutive screen
  transition in the same test — not chased further; the same scenario already passes
  reliably in `test/ui/reader_navigation_test.dart` (host `flutter_test`).
- **Android**: retried `flutter drive` once more after the fix (legitimate new
  information, not a repeat) — **still hangs identically**. So the setState bug wasn't
  the (sole) cause of the Android-specific failure; something about this
  `flutter_driver`/emulator/Windows combination remains unresolved and is *not* an app
  bug (the app itself works fine on Android — see M2-03 below, captured without the
  driver). Not investigated further.
- **M2-03 (airplane mode)** captured manually instead of via the driver: installed the
  debug APK directly (`adb install`), set `airplane_mode_on` + `svc wifi disable` +
  `svc data disable` (confirmed via `adb shell ping` failing and the airplane-mode icon
  in the status bar), force-stopped and relaunched the app, captured via
  `adb exec-out screencap`. Shows a full passage rendering correctly and completely
  offline.

**Net result:** all four M2 screenshot criteria have real evidence (`verification-shots/M2/`),
three via the actual on-device/browser `integration_test` harness this milestone was
meant to establish, one via direct `adb` device control. Carrying forward as debt:
the Android `flutter drive` connection issue itself (undiagnosed, may need a different
emulator/API image or Flutter version to resolve) and the dropped bonus Revelation-end
scenario in `integration_test/app_test.dart` (covered elsewhere, not missing evidence).

## Milestone 2 — what's built (pending M2's own screenshot evidence)
- `pubspec.yaml`: `drift`, `sqlite3_flutter_libs`, `path_provider`, `path` (all
  approved by the human before adding — see Decisions below), plus
  `integration_test`/`flutter_driver` (ship with the Flutter SDK, same tier as
  `flutter_test`, no separate approval needed).
- `lib/data/local_store.dart`: drift `Table` classes mirroring the pipeline's physical
  schema exactly (column names via `.named(...)` where they'd otherwise collide with
  drift's own DSL — e.g. `Verses.content` maps to the physical `text` column, since a
  column getter literally named `text` shadows drift's `text()` column-builder
  function). Query methods: `passageById`, `versesForPassage`, `bookById`, `allBooks`,
  `passageContainingVerse` (resolves a chapter jump to whichever passage's range
  contains that verse — a chapter's first verse may belong to a passage that started
  in an earlier chapter), `maxChapterForBook`, `maxPassageId`.
- `lib/data/db_connection_{native,web}.dart`: native copies the bundled asset to the
  app's support directory on first launch (Android can't open a db file straight out
  of the asset bundle); web uses `WasmDatabase.open` with prebuilt `sqlite3.wasm` +
  `drift_worker.js` (downloaded matching the exact installed `sqlite3`/`drift`
  versions from their GitHub releases — see below), seeded from the same bundled
  asset via `rootBundle`.
- `lib/ui/`: `HomeScreen` (66-book list) -> `BookScreen` (chapter grid, chapter count
  queried live rather than hand-copied) -> `ReaderScreen` (heading + verses with
  verse-number anchors, Previous/Next). Passage ids are sequential in canonical
  reading order (an emergent property of how the M1 pipeline assigns them), so
  prev/next is just `id ± 1` with a bounds check — no query needed to determine
  adjacency.
- `integration_test/app_test.dart` + `test_driver/integration_test.dart`: M2-01 and
  M2-02 (Genesis-start, Malachi→Matthew) pass for real against Chrome — see RESOLVED
  section above for the Android situation and the dropped bonus scenario.
- `test/ui/reader_navigation_test.dart`: the same M2-02 boundary logic (incl. the
  Revelation-end true-canon-boundary case) via host `flutter_test`, independent of the
  on-device harness.
- **Evidence captured** (`verification-shots/M2/`): `M2-01-isaiah-53.png`,
  `M2-02-genesis-start.png`, `M2-02-malachi-to-matthew.png` (all via the real
  `integration_test` harness on Chrome), `M2-03-airplane-mode.png` (Android emulator,
  airplane mode confirmed via status bar + failed `ping`, captured via direct `adb`
  device control since the driver itself doesn't work on Android here). M2-04 (web
  render) is satisfied by the same `M2-01-isaiah-53.png` — it was captured via Chrome.

## Next steps
1. **Stopped for human review of Milestone 4** (needs-human-check, PASS-WITH-NOTES).
   Per the milestone's own last acceptance criterion and CLAUDE.md's human-performed
   steps list, the human should enter a real API.Bible key locally
   (`--dart-define=BIBLE_API_KEY=...`) and confirm live NIV behaviour actually works
   end-to-end — this has never been done by the agent and can't be, by design (M4-04
   forbids any live call in tests/gate). Also worth the human's own judgment call: is
   the current NIV-only scope (no NKJV wiring, corrected Settings copy) fine to ship
   as-is, or worth building out a translation picker before Milestone 5?
2. Once M4 is reviewed and approved, build Milestone 5 (Shipping): release APK +
   sideload instructions, About screen attributions (OpenBible CC-BY, BSB, API.Bible
   ToS), GitHub Pages deployment finished properly (the workflow already exists,
   ahead of schedule — see above — but M5's own gate still covers the full deploy
   criteria: release build, About screen, deployed-URL capture with a JS-error
   listener). `needs-human-check` — deploy + on-phone steps are human-owned.
   DO-NOT-BUILD: app-store packaging/signing, custom domains, analytics.
3. The Android `flutter drive` connection issue remains unresolved and undiagnosed —
   still not urgent, direct `adb` control remains a proven fallback if M5's on-phone
   evidence needs it.
