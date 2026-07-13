# Architecture — Tapestry

> Target path in build repo: `/docs/ARCHITECTURE.md`
> Every choice below carries its why. Change nothing here without planning-level
> approval (CLAUDE.md rule).

## Tech Stack
| Layer | Choice | Why (plain language) |
|---|---|---|
| Framework | Flutter (stable), Dart | One codebase → Android APK + web build; the user's stated learning goal |
| Targets | Android, Web only | The two places it ships. iOS/desktop = parked |
| Local DB | `drift` over a bundled prebuilt SQLite file | Same query code on native (sqlite3) and web (sqlite3 WASM). The DB is BUILT by the pipeline, shipped as an asset — the app never constructs data at runtime |
| Graph render | `CustomPainter`, radial-orbit layout | Deterministic: same input → same pixels → screenshots the Verifier can actually judge. Force-directed is nondeterministic and screenshot-flaky → parked |
| State | Flutter built-ins only | Leanness rule 3/4. Add a framework only against a named pain |
| Online text | API.Bible REST (NIV, NKJV) | The licensed route; free Starter plan, 3 copyrighted translations, non-commercial |
| Pipeline | Dart CLI `tool/build_db.dart` | One toolchain on the Windows machine; Dart ships with Flutter |
| Hosting | GitHub Pages | Flutter web is a static bundle; user already has GitHub; free |
| CI | GitHub Actions: analyze + test + pipeline smoke | The deterministic battery, no model in the loop |

## System Overview / Component Map
```
tool/build_db.dart  ──(build time)──▶  assets/bible.db
                                          │ bundled asset
┌─────────────────────────── Flutter app ─┴──────────────────────────┐
│  data/                                                             │
│    LocalStore (drift)  ── passages, verses(BSB), edges, books      │
│    TranslationService  ── API.Bible client + per-verse cache       │
│  domain/                                                           │
│    VerseId · Passage · Edge · TranslationLayer · VerseStatus       │
│  ui/                                                               │
│    ReaderScreen        ── passage text, prev/next, verse anchors   │
│    ConstellationView   ── CustomPainter orbit, tap-to-recenter     │
│    ParallelScreen      ── two aligned translation panes            │
└─────────────────────────────────────────────────────────────────────┘
```

## Data Models (the core decision: graph never touches text)
- **VerseId** — canonical integer `BBCCCVVV` (book 1–66, chapter, verse), keyed to
  the Protestant 66-book canon. Every layer (BSB, NIV, NKJV) maps onto these IDs.
- **Passage** — `id, book, startVerseId, endVerseId, heading`. Boundaries come from
  BSB section headings (public domain — licensing-clean pericopes for free).
- **Edge** — `fromPassageId, toPassageId, weight`. Built by aggregating
  OpenBible.info verse-level cross-references (weight = sum of votes) up to the
  passage level. Self-edges and sub-threshold noise dropped in the pipeline.
- **VerseStatus (per translation)** — `present | footnoted | absent`. A verse
  missing from a layer (e.g. Matthew 17:21 in NIV) renders as a tappable footnote
  marker with the manuscript note. Never a silent gap; every graph node always
  resolves to something.
- **TranslationLayer** — metadata + fetch/caching policy for an online translation.
  BSB is the always-present offline layer; the app is fully usable without network.

## API Design (external)
- API.Bible: passage-range GET per screenful, keyed per translation. Small LRU
  cache in memory + short-lived local cache honouring their fair-use terms. Key is
  injected at build via `--dart-define=BIBLE_API_KEY`; a missing key degrades
  gracefully (BSB-only mode with a plain explanation, not a crash).
- Client-side caveat, accepted knowingly: a key shipped in a client app is
  extractable. Acceptable for personal use; revisit before any public store release.

## Key Patterns & Conventions
- `lib/` split: `data/`, `domain/`, `ui/` as above; tests mirror the tree
- All Scripture text access goes through LocalStore/TranslationService — UI never
  does raw queries or HTTP
- Tests never hit the live API (mock TranslationService); the gate must run
  offline and never spend quota
- Deterministic rendering: ConstellationView layout is a pure function of
  (centerPassage, edges) — no randomness, no animation-dependent end states
- Attribution: OpenBible.info cross-reference data is CC-BY — the About screen and
  README carry the attribution line (see docs/DATA_SOURCES.md). Non-negotiable
- Every deliberate shortcut is marked inline `// forge-debt: ...`
