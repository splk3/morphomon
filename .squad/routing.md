# Work Routing

How to decide who handles what.

## Routing Table

| Work Type | Route To | Examples |
|-----------|----------|---------|
| Architecture, system design, decisions | Mal | How morphomon scanner should work, scene graph design, tech debt calls |
| Code review, quality gates | Mal | Review GDScript PRs, check patterns, naming |
| Scope & priorities | Mal | What to build next, cut decisions |
| GDScript implementation | Kaylee | New scripts, refactors, bug fixes in `.gd` files |
| Player mechanics & physics | Kaylee | Jump feel, movement tuning, collision |
| Game systems | Kaylee | State machines, creature transformations, pickups, enemies |
| Scene files & level layout | Wash | `.tscn` edits, TileMap platform placement |
| Visual assets & parallax | Wash | SVG sprites, background layers, camera config |
| UI & main menu | Wash | Menu layout, HUD, visual polish |
| Session logging | Scribe | Automatic — never needs routing |
| Work queue & backlog | Ralph | GitHub issues, PR status, board monitoring |

## Issue Routing

| Label | Action | Who |
|-------|--------|-----|
| `squad` | Triage: analyze issue, assign `squad:{member}` label | Mal |
| `squad:mal` | Pick up issue | Mal |
| `squad:kaylee` | Pick up issue | Kaylee |
| `squad:wash` | Pick up issue | Wash |

### How Issue Assignment Works

1. When a GitHub issue gets the `squad` label, the **Lead** triages it — analyzing content, assigning the right `squad:{member}` label, and commenting with triage notes.
2. When a `squad:{member}` label is applied, that member picks up the issue in their next session.
3. Members can reassign by removing their label and adding another member's label.
4. The `squad` label is the "inbox" — untriaged issues waiting for Lead review.

## Rules

1. **Eager by default** — spawn all agents who could usefully start work, including anticipatory downstream work.
2. **Scribe always runs** after substantial work, always as `mode: "background"`. Never blocks.
3. **Quick facts → coordinator answers directly.** Don't spawn an agent for "what port does the server run on?"
4. **When two agents could handle it**, pick the one whose domain is the primary concern.
5. **"Team, ..." → fan-out.** Spawn all relevant agents in parallel as `mode: "background"`.
6. **Anticipate downstream work.** If a feature is being built, spawn the tester to write test cases from requirements simultaneously.
7. **Issue-labeled work** — when a `squad:{member}` label is applied to an issue, route to that member. The Lead handles all `squad` (base label) triage.
