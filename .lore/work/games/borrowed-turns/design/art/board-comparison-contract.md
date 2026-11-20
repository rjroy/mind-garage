# Borrowed Turns: board readability comparison

## Scope and authority

Ronald accepted the Director images and current standee sizes after playing
`be05d73`. He identified merging standees and inadequate tile-tint telegraphs,
suggested a thin black contour, and approved the bounded comparison proposal.
Preserve the Director, standee scale/anchors, stage/floor, source PNGs and rules.
Authored runtime marks and contours are permitted; new image generation is not
needed. This compares presentation, not alternative mechanics.

This contract covers implementation after independent behavioral RED. The first
assignment adds tests and neutral loadable interfaces only. It does not implement
or approve a visual candidate.

## Two action languages, one actual scene

- **Paper shove ribbons:** narrow warm-paper strips connect the source foot tab
  to its exact announced cells. Printed pushing-hand motifs and arrowheads convey
  a shove, not a walking route. Keep cell boundaries readable. Give A and B
  separate parallel lanes through shared cells; do not merge their warnings.
- **Shove-hand stamps:** substantial pushing-hand prints occupy each affected
  cell, with direction and the source's existing diamond/A or circle/B badge.
  There is no connecting ribbon. Shared cells carry two separate prints.

These must be finished, paper-native runtime treatments over the real encounter,
not generic arrows/boxes on a replacement board. Use authored hand geometry,
legible material edges and the existing palette. Color supplements source shape
and lettering. The treatments may share a hand motif but must differ structurally.
No continuous flashing, new lighting mechanic or ordinary grounding shadows.

Use only model-authored affected cells. A ribbon's attachment at its source is
not another threatened cell. Do not extend its end into an invented push
destination. Actor occlusion must not erase the warnings: reserve readable side
lanes inside the true cells and preserve source tabs above bodies.

Keep legal-target, selection, exact ordered prediction and held-backlash marks
distinct from enemy announcements. Retain the current double-border backlash
language and mint prediction language; do not replace these with enemy ribbons
or imply that held storage is still the enemy's current attack. Clear separation
and unobscured readback are visual review requirements, not claims from tests.

## Contours

Compare current, thin near-black, and near-black plus a narrow warm-paper rim on
the same initial state. Derive contours from actual texture alpha; preserve
interior gaps, native source pixels, depth ordering, foot anchors, scale and
source picking. Do not draw full hidden bodies through foreground pieces.
Retain hover/focus occluder fading. Black plus warm rim is the fixed contour for
both telegraph candidates, not an assertion that Ronald has selected it finally.
Contour width and material finish are judged in actual-size renders, not frozen
as pixel constants in tests.

## Minimal controls

Add two labeled OptionButtons to the existing Plans area, accessible through
**Details → Plans → Board appearance** in the two-pursuer Stage encounter:

| Control | Metadata values | Labels |
| --- | --- | --- |
| Telegraph | `current`, `ribbons`, `stamps` | Current, Paper shove ribbons, Shove-hand stamps |
| Standee edge | `current`, `black`, `rim` | Current, Thin black edge, Black + warm paper rim |

Default to `current/current` to retain an honest before comparison. Keep these
controls hidden in other encounters/views; keep their chosen values across
view changes, commands and Restart. Changing appearance only redraws the board
and synchronizes the pickers. It does not reset the controller, replay capture,
advance time, change generation, clear selection, close Details, change keyboard
focus or reassess/commit a command. No extra CLI flags, preset-state loader or
comparison framework are required. Existing launch options and actual Capture/
Restart controls reach every compared state.

## Compact interfaces

On `ui/board.gd`:

```gdscript
func set_board_comparison(telegraph: String, contour: String) -> bool
func board_comparison() -> Dictionary
func announcement_marks() -> Array
```

The setter accepts exactly the metadata values above. Invalid pairs return
`false` atomically; valid pairs return `true`, including a repeated value.
`board_comparison()` returns detached `{telegraph, contour}` preferences.

`announcement_marks()` is the actual candidate renderer's input, not a test-only
mirror. In the active two-pursuer Stage profile it returns one detached row per
current A/B shove intention with a matching living source:

```text
{source, turn, kind, origin, direction, cells, lane}
```

`source`, `kind`, ordered `cells` and announcement `turn` come from the snapshot;
`origin` and `direction` are copied from its matching enemy. Never recompute a ray
from range, infer cancellation from a held source, or suppress a new announcement
because an older occurrence is held. `lane` is stable A=0/B=1, even with just one
source or reordered arrays. No style, focus or preview selection changes these
facts. Outside Stage/theatre mode it returns `[]`; unsupported ability/source
kinds keep their existing rendering. Current-style rendering remains the old
baseline; both new styles consume these same rows. Backlash and prediction keep
their existing model/controller paths.

On `ui/encounter_ui.gd`:

```gdscript
func set_board_comparison(telegraph: String, contour: String) -> bool
```

It delegates to the board and synchronizes the two public `telegraph_picker` and
`contour_picker` controls without emitting recursive signals. There is no second
copy of the preferences in the UI.

**Neutral setup before RED:** board/UI setters return `false`, board preferences
return `current/current`, marks return `[]`. Both real pickers exist with the
listed metadata inside a hidden group and have no callbacks. No new drawing,
selection, command, stage-layout or model behavior belongs in this setup.

## Evidence and human judgment

Use the actual `two-pursuers` encounter, not test-fixture imitations:
initial overlap, A captured and settled, B captured and settled. Restart before
each alternative capture. Both actors stay alive; capture removes only that
source's current warning. Initially A `[2,1]` faces `[0,1]` through `[2,2],[2,3]`;
B `[2,3]` faces `[0,-1]` through `[2,2],[2,1]`. The model remains authoritative
if content changes. Also inspect a real release preview with held backlash
present, so prettier warnings do not hide command consequences.

Capture both 1024×720 and 1600×900:

- Three initial-state outline views using current telegraphs.
- Each new telegraph language in initial/A-held/B-held states, always using rim.
- One supplementary release-preview view per language.

Freeze only scene processing during each matched appearance batch after normal
settlement, so the Director pose does not change between alternatives. Never
fabricate snapshots or transfer art for screenshots. Evidence is actual scene
readback, not a generated concept image. A paired sheet is a review convenience;
keep individual full-size views. Regenerable evidence stays local.

Ronald judges action recognition, source, direction, exact threatened cells,
overlap, what disappeared after capture, and silhouette separation independently
from aesthetic preference. Before/after stills do not establish motion quality,
human input reliability or enjoyment.

## Test ownership and commands

- `tests/board_warning_run.gd`: controlled snapshots, independent of production
  tuning/art. Verify option validation; exact source/cell/origin/direction/turn;
  stable overlap lanes; suppression and fresh announcements while held; detached
  facts; and preservation of board selection, preview and focus. Existing
  `standee_board_run.gd` remains responsible for alpha picking and geometry.
- `ui/board_comparison_smoke.gd`: extends the existing scene smoke helpers.
  Controlled fixtures verify actual picker delegation and state/history/
  command/prediction/controller preservation. Optional captures then use the
  actual two-pursuer fixture and real capture controls for the matched views.
- Existing `two_pursuer_presentation_run.gd` owns puppet occurrence/transfer
  correctness. Do not duplicate that controller's event matrix here.

```sh
# Author: syntax only, before independent behavioral RED.
godot --headless --path games/borrowed-turns --check-only --script res://tests/board_warning_run.gd
godot --headless --path games/borrowed-turns --check-only --script res://ui/board_comparison_smoke.gd

# Independent tester: neutral setup must produce behavioral failures, not exit 2.
godot --headless --path games/borrowed-turns --script res://tests/board_warning_run.gd
godot --headless --path games/borrowed-turns --script res://ui/board_comparison_smoke.gd

# After implementation: graphical readback, using the existing local puppet pack.
godot --path games/borrowed-turns --script res://ui/board_comparison_smoke.gd -- \
  --capture-dir=/tmp/opencode/borrowed-turns-board-comparison
```

Missing methods/controls/material are setup errors (exit 2), assertion failures
exit 1. No pixel/style correctness assertions. Production work, independent
GREEN/regressions, fresh oracle correctness review, separate refactor/quality
review and Designer's visual inspection follow the parent-owned workflow.
