# KNOWLEDGE.md — Tapestry memory map

> Target path in build repo: `/docs/KNOWLEDGE.md`
> The index is the hub: read this map, then load only the 1–3 nodes the task needs.
> Never bulk-load. (The Verifier is exempt — it receives the full architecture
> deterministically at the gate; see VERIFICATION.md §0.)

| Node | What's in it / when to load it |
|---|---|
| docs/PROJECT_SCOPE.md | Vision, users, out-of-scope list. Load when judging whether something belongs in the build |
| docs/ARCHITECTURE.md | Stack + whys, component map, data models, conventions. Load for any implementation task |
| docs/DATA_SOURCES.md | Licensing, attributions, pipeline input hygiene. Load for pipeline (M1), translations (M4), shipping (M5) |
| docs/MILESTONES.md | The plan, criteria, DO-NOT-BUILD lists, autonomy tags. Load at every milestone start |
| docs/ACCEPTANCE.json | The flip-only ledger. Load at self-check and gate |
| docs/VERIFICATION.md | The gate spec, commands, eight checks. Load at self-check and gate |
| docs/PARKED.md | Shiny ideas holding pen. Load only to append |

Maintenance: add a node → add its line here. One topic per node. A node nothing
links to is an orphan — fold it in or drop it. Stale links are defects.
