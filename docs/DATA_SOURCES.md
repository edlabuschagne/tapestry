# Data Sources & Licensing — Tapestry

> Target path in build repo: `/docs/DATA_SOURCES.md`
> Knowledge node. Load when: pipeline work (M1), attribution UI (M5), or any
> question about what we may legally ship. Links: ARCHITECTURE.md (data models),
> MILESTONES.md (M1, M4, M5).

## Bundled offline (shipped inside the app)
| Dataset | Source | License | Obligation |
|---|---|---|---|
| Berean Standard Bible (BSB) text + section headings | berean.bible / helloao free-use API dumps | Public domain (dedicated April 2023) | None; courtesy credit on About screen |
| Cross-references (~340k, vote-weighted) | OpenBible.info | Creative Commons **Attribution** | MUST attribute — About screen + README carry the line: "Cross-reference data from OpenBible.info, CC-BY" |
| Treasury of Scripture Knowledge (fallback/supplement) | Public domain | Public domain | None |

## Online layers (fetched at runtime, never bundled)
| Dataset | Source | Terms |
|---|---|---|
| NIV, NKJV | API.Bible (American Bible Society) — free Starter plan | Non-commercial; up to 3 copyrighted translations; fair-use caching only; attribution per their ToS; key is the human's, entered locally, never committed |

## Hard rules the pipeline and app must honour
- Never bundle, persistently cache, or export NIV/NKJV text beyond API.Bible's
  fair-use session caching — the offline layer is BSB only
- The app remains non-commercial while on the Starter plan; any monetisation or
  store release triggers a licensing review FIRST (tripwire-adjacent: human call)
- Attribution strings are acceptance criteria (M5-04), not decoration

## Pipeline input hygiene (Check 5: input validation)
External data files are untrusted input: validate row shapes, reference parsing,
and vote integers; reject and report malformed rows; never write a partial
bible.db over a good one (temp-write → validate → atomic swap).
