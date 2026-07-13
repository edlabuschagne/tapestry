# Project Scope — Tapestry (working title)

> Target path in build repo: `/docs/PROJECT_SCOPE.md`

## Vision
A study Bible where the cross-references are the interface, not a footnote. The
reader opens a passage, sees its "constellation" — the passages most strongly
linked to it, drawn as an orbit around it — and walks the Bible link by link
(Isaiah 53 → Matthew 8 → 1 Peter 2), with full passage context always one tap
away. Obsidian's local graph, for Scripture.

## Target Users
Initially one: the builder — a reader who engages Scripture thematically rather
than book-by-book, on an Android phone and in a browser. Design decisions favour
that reader; multi-user concerns (accounts, sync, sharing) are explicitly out of
scope for now.

## Core Problem
Existing Bible apps treat cross-references as marginalia: tiny superscript letters
that open a flat list. There is no way to *see* the web of connections or to
navigate it as a first-class activity. Readers who think in links either lose the
thread or lose the context. The data to fix this has existed for a century
(Treasury of Scripture Knowledge; OpenBible.info's ~340k weighted cross-references)
— what's missing is the experience.

## Core Features (the must-haves)
1. **Passage reader** — Scripture displayed passage-by-passage (BSB section
   headings define passage boundaries), with surrounding context, offline, from a
   bundled public-domain translation (BSB).
2. **The constellation** — tap a passage, see its top linked passages as nodes on
   a deterministic radial orbit, edge weight shown by thickness/size; tap a node
   to re-center. The graph is the map; the reader pane is the territory.
3. **Passage-level linking** — verse-level cross-references aggregated to
   passage-level edges, so the graph shows meaning-sized units, not proof-text
   fragments.
4. **Parallel translations** — NIV and NKJV as online layers via API.Bible,
   side-by-side with verse alignment; verses absent from a translation render as a
   tappable footnote marker (the printed-NIV convention), never a silent gap.
5. **Runs where the user is** — installable APK on his Android phone (sideloaded),
   and a web build on a public URL.

## Out of Scope (explicitly NOT building, for now — see docs/PARKED.md)
- Search, bookmarks, highlights, notes, reading plans
- User accounts, sync, or any server-side component
- Force-directed / whole-Bible graph visualisation
- Audio, commentaries, original-language tooling
- App-store distribution (costly; sideload + web first)
- Additional translations beyond BSB (offline) + NIV/NKJV (online)

## Success Criteria
- The builder reaches any passage of the Bible in ≤3 taps from launch, offline
- From Isaiah 53, the constellation surfaces at least one Gospel passage in its
  top links, and tapping it lands in a readable, contextual passage view
- NIV/NKJV parallel view aligns verses correctly, including footnoted absences
- The web URL loads the reader with zero JS console errors on a cold visit
- The APK runs on the builder's own phone, installed without any store
