# Milestones — Tapestry

> Target path in build repo: `/docs/MILESTONES.md`
> Milestone 0 is the bootstrap. Feature milestones start at 1. Criteria are
> mirrored in docs/ACCEPTANCE.json (flip-only ledger — criteria change only here,
> in planning, with the human).

## Milestone 0 — Bootstrap (setup)
**Goal:** a running Flutter skeleton, proven toolchain, armed harness.
**Deliverables:** Flutter SDK + Android toolchain installed (agent guides, human
performs installs); git repo with `.gitignore` covering secrets/build artefacts;
"hello Tapestry" shell that builds for web and Android; Forge harness copied from
the project-forge repo per the "Harness copy-in" procedure in CLAUDE.md (LF
endings, settings merge, quick-check placeholders, workspace-trust step, canary
proof); GitHub Actions running analyze + test on
push; baseline commit.
**Acceptance Criteria (testable, observable):**
- [ ] `flutter doctor` exits 0 for Android + web toolchains (captured output)
- [ ] `flutter build web` and `flutter build apk --debug` both exit 0
- [ ] App launches showing a "Tapestry" placeholder screen (screenshot)
- [ ] `mkdir __forge_canary__` is BLOCKED in a Claude Code session (guard proof)
- [ ] CI runs analyze + test green on push (link to run)
- [ ] `.env`-style secrets pattern is gitignored from commit zero
**Verification:** captured stdout/exit codes + one integration_test screenshot.
**Autonomy:** needs-human-check (human performs installs; first-of-kind setup).

## Milestone 1 — The data forge (pipeline → bible.db)
**Goal:** one command builds the complete offline dataset.
**Deliverables:** `tool/build_db.dart` ingesting BSB text + OpenBible.info
cross-references; passage table from BSB headings; passage-level weighted edges;
canonical VerseId scheme; attribution recorded.
**Acceptance Criteria:**
- [ ] `dart run tool/build_db.dart` exits 0 and writes `assets/bible.db`
- [ ] DB contains 66 books and ≥ 31,000 BSB verses (queried count in captured output)
- [ ] Query for VerseId of John 3:16 returns BSB text containing "only begotten" or
      "one and only" (pipeline smoke test prints it)
- [ ] Every verse maps to exactly one passage; passage for Isaiah 53:5 spans within
      Isaiah 52:13–53:12 and carries a heading
- [ ] Top-weighted edge from the Isaiah 53 passage points to a New Testament
      passage (printed in smoke output)
- [ ] No orphan edges (every edge endpoint is an existing passage) — asserted by test
**Verification:** captured stdout + generated-artifact inspection (Check 8, batch
form); unit tests on the aggregation logic.
**DO-NOT-BUILD:** any UI; NIV/NKJV anything; search indexes.
**Autonomy:** auto-verifiable.

## Milestone 2 — The reader
**Goal:** read any passage of the BSB, offline, with context.
**Deliverables:** book/chapter navigation; ReaderScreen rendering a passage
(heading + verses, verse numbers as anchors); prev/next passage; drift wiring of
the bundled DB on Android and web.
**Acceptance Criteria:**
- [ ] From launch, user reaches Isaiah 53 in ≤3 taps; screen shows the passage
      heading and full text (screenshot)
- [ ] Prev/next moves one passage and never skips or repeats (widget test +
      screenshots of boundary cases: Genesis 1 start, Malachi end)
- [ ] Airplane-mode launch on Android renders a passage normally (screenshot from
      device/emulator with network disabled)
- [ ] Web build renders the same passage in a browser (screenshot)
**Verification:** integration_test screenshots (Flutter harness — NOT Playwright;
Flutter web renders to canvas) + widget tests.
**DO-NOT-BUILD:** the constellation; translations; theming beyond defaults.
**Autonomy:** auto-verifiable.

## Milestone 3 — The constellation
**Goal:** the point of the whole app.
**Deliverables:** ConstellationView (CustomPainter): center passage node + up to
12 top-weighted neighbours on a radial orbit, node label = short reference, edge
thickness ∝ weight; tap neighbour → recenter with reader pane following; back
returns; entry point from ReaderScreen.
**Acceptance Criteria:**
- [ ] Opening the constellation for Isaiah 53's passage shows ≥5 neighbour nodes,
      at least one from the Gospels (screenshot)
- [ ] Layout is deterministic: two runs on the same passage produce identical
      screenshots (golden test)
- [ ] Tapping a neighbour recenters the graph AND updates the reader pane to that
      passage (integration test + before/after screenshots)
- [ ] Every rendered node resolves to a readable passage (no dead taps — test over
      the 50 highest-degree passages)
- [ ] Tap targets ≥ 44dp; node labels legible at default font scale (accessibility
      floor — screenshot judged)
**Verification:** golden tests + integration_test screenshots.
**DO-NOT-BUILD:** force-directed layout; whole-Bible view; pan/zoom physics;
animations beyond simple transitions.
**Autonomy:** needs-human-check — whether the constellation *feels* right is
subjective quality a screenshot can't settle. The run stops here even on PASS.

## Milestone 4 — Translation layers (NIV / NKJV)
**Goal:** licensed modern translations, bounced side-by-side.
**Deliverables:** TranslationService (API.Bible client, mockable, cached);
settings entry for key presence; ParallelScreen with two verse-aligned panes;
VerseStatus handling — footnote markers for absent verses with tappable note.
**Acceptance Criteria:**
- [ ] With a mocked API, parallel view aligns BSB/NIV verse-by-verse for Romans 8
      (screenshot)
- [ ] Mocked NIV omitting Matthew 17:21 renders a footnote marker at the correct
      position; tapping reveals the note (screenshots of both states)
- [ ] With no API key configured, app runs in BSB-only mode with a plain
      explanation — no crash, no blank pane (screenshot)
- [ ] No test or gate step performs a live network call (asserted: gate battery
      passes with network mocked/disabled)
- [ ] The API key appears nowhere in the repo or logs (grep proof in gate output)
**Verification:** widget/integration tests over the mock; screenshots.
**DO-NOT-BUILD:** more translations; offline caching of NIV/NKJV beyond fair-use
session cache; any account system.
**Autonomy:** needs-human-check — a real external service integration; the human
enters the real key and verifies live behaviour at the stop.

## Milestone 5 — Shipping
**Goal:** on the phone and on the web, for real.
**Deliverables:** release APK build + sideload instructions; GitHub Pages
deployment of the web build (workflow preps it; human flips Pages on); About
screen with attributions (OpenBible CC-BY, BSB, API.Bible per ToS).
**Acceptance Criteria:**
- [ ] `flutter build apk --release` exits 0; human confirms install + launch on
      their phone (human-verified criterion, recorded in HANDOFF)
- [ ] Deployed URL loads the reader with zero JS console errors — real browser
      load of the DEPLOYED origin, asserted in the capture (Check 8 deployed rule)
- [ ] Airplane-mode phone use still reads BSB end-to-end (human-verified)
- [ ] About screen shows all three attributions (screenshot)
**Verification:** deployed-URL browser capture with JS-error listener + human
confirmation of on-phone steps.
**DO-NOT-BUILD:** app-store packaging/signing for stores; custom domains;
analytics of any kind.
**Autonomy:** needs-human-check (deploy + on-phone steps are human-owned).

---
**Suggested first autonomous run:** "Run milestones 1–2, stop on any FAIL or
tripwire, then stop for batch review." M3 onward inherently stops per its tag.
