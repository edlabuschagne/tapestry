# Vendored pipeline inputs

Fetched once and committed so `tool/build_db.dart` runs offline and deterministically
(no network at build or gate time). Re-fetch manually to refresh either dataset.

| File | Source | Fetched | License |
|---|---|---|---|
| `bsb_complete.json` | `https://bible.helloao.org/api/BSB/complete.json` | 2026-07-13 | Public domain (Berean Standard Bible, dedicated April 2023) |
| `cross_references.txt` | `https://a.openbible.info/data/cross-references.zip` | 2026-07-13 | Creative Commons Attribution (CC-BY) — OpenBible.info |
