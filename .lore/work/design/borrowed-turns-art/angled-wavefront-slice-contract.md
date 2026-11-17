# Borrowed Turns: angled board and wavefront overlays

## Authority and visual target

Ronald rejected the ribbon/stamp direction as tile decoration and requested
concept exploration plus a board yaw of about 30 degrees. He liked the
directional wavefronts in panel **B / Contour projection** of
`.lore/local/experiments/002-shadow-paper/telegraph-overlay-concepts/overlay-comparison-candidate.png`
as a starting point, then approved the proposed playable slice.

Use that panel's broad, continuous luminous footprint, curved wavefronts across
its width, and conspicuous direction. Do not recreate little hand badges,
narrow ribbons, per-tile boxes or decorative tile tint and call them overlays.
The concept's altered characters, source-cell coverage and apparent push
destinations are not approved gameplay or artwork. Keep the current source PNGs,
upright standees, accepted sizing/anchors and Director unchanged.

This assignment writes tests, this contract and neutral interfaces only.
Production follows independent behavioral RED.

## One default slice, not another option matrix

The existing launch opens the new slice directly:

```sh
godot --path games/borrowed-turns -- --presentation=stage --encounter=two-pursuers
```

The normal encounter chooser also opens it. There is no buried appearance
selection, new angle slider, overlay-style menu or preset-state loader.
Keep the paper/original-escape startup default and existing plain/paper views.
They remain same-state correctness comparisons, not competing new art directions.

Retire the ribbon/stamp comparison controls, setters and hand-rendering code
during production. `38d7e3e` preserves the previous experiment for honest
before/after evidence. Do not retain it as an expanding runtime option framework.
Use the existing source PNG edges for this slice; no new contour choice or
character treatment is introduced.

## Shared ground plane

Add this method to `ui/stage_projection.gd`:

```gdscript
func configure_ground(columns: int, rows: int, bounds: Rect2, yaw_degrees: float) -> bool
```

Rotate centered logical ground coordinates about the vertical axis before
perspective projection, then uniformly fit the projected corners inside bounds.
Positive yaw moves increasing grid Y toward screen-left and increasing grid X
toward the viewer. Start near +30 degrees in the real profile. Camera compression,
fit margins and perspective distance are presentation tuning, not permanent
pixel/unit-test expectations. Both axes must be visibly oblique in actual renders.
Do not rotate a screenshot, the source backdrop/floor images, or standee sprites.

Build on the existing `configure` homography. `project`, `unproject`, half-open
`cell_at`, `cell_polygon` and `inverse_coefficients` remain the common consumers.
Invalid dimensions, nonfinite yaw/bounds or nonpositive bounds clear stale maps
and return false, as the existing configure method does.

`Board._ensure_projection()` chooses this ground profile when Stage has the
configured two-pursuer standees. Unconfigured/original Stage keeps its existing
quad. Configure/clear/resize must invalidate the same projection cache. The floor
renderer already consumes its corners and inverse coefficients; use that join,
not a second shader transform. Grid, floor/apron, footprint regions, target
outlines, predictions, exit, actor feet, motion interpolation and inverse picking
all use it. Sort upright actors by projected feet, not row number or source ID.
Keep body/alpha picking, source tabs, rear-source reveal and Alt-floor targeting.
Angle reduces alignment; it does not guarantee zero occlusion.

The fitted playing plane may change its footprint inside the existing stage
allocation. Do not resize the accepted standees, move the Director slots or
silently move actors to different logical cells. If the apron needs adjustment,
keep its accepted source material and shared plane; disclose it in visual review.

## Model-to-overlay join

Keep `Board.announcement_marks()` as the detached source/turn/kind/origin/
direction/ordered-cells/lane projection already tested. Here lane is stable source
ordering for overlapping contour offsets, not a narrow decorative strip.
It does not consult held storage to cancel a fresh announcement.

Add `ui/telegraph_regions.gd`, a compact geometry helper:

```gdscript
static func boundaries(cells: Array) -> Array
```

It returns detached logical-space closed-region contours as
`Array[PackedVector2Array]`, with the closing point implicit. The region is the
exact union of the given unit cells: no shared internal seams, source-cell
extension, convex hull across gaps, range recomputation or fake destination.
Empty cells produce no contour. Current consumers are cardinal shove footprints;
this is geometry, not another combat simulation.

Add the actual candidate renderer input on Board:

```gdscript
func announcement_regions() -> Array
```

Each row contains the existing announcement facts plus `contours`, built from
that row's cells, and `projected`, those contour vertices through the shared
plane. The real renderer consumes `projected` for the wash/outline and clips
wavefront construction against the logical contours. Resize recomputes projected
vertices without changing the logical region. Preserve one row per source even
when regions overlap. Outside Stage/theatre or after clearing state return `[]`. Unrelated sources/abilities
keep their existing paths. The renderer must consume these rows, not a test-only
mirror or an independently recomputed ray.

Draw the broad region below upright actors/source tabs, with a restrained
transparent wash, luminous continuous outline, full-width curved wavefronts and
a clear directional head clipped inside the affected region. Keep the dark
paper visible. Cool A and warm B can echo the concept's rear/right broad pursuer
and front/left hooded pursuer, but use existing A/diamond
and B/circle source cues as well. At shared cells both announcements remain
visible, through distinct inset contour traces/curve spacing and direction.
Inspecting one may emphasize it, never erase the other.

Capture removes only that source's current region. Surviving sources may announce
again while an older occurrence remains held. Keep mint command/legal prediction
and double-border held backlash distinct and above the threat wash. Neither is
silently turned into another enemy wavefront. Existing model/controller event
paths remain authoritative for committed effects and displacements.

**Neutral setup:** `configure_ground` returns false; `boundaries` and
`announcement_regions` return `[]`. No production method calls them yet. Existing
rendering, defaults and controls stay unchanged until independent RED.

## Focused evidence and test boundaries

Reuse these runners rather than adding a parallel harness:

- `tests/stage_projection_run.gd`: retain analytic homography, seams, invalid-map,
  material and original-board coverage. Add controlled yawed ground fitting,
  forward/inverse ownership, shader inverse use and invalid-ground cases.
- `tests/standee_board_run.gd`: retain scale, native registration, alpha/gap input,
  tabs, focus and lifecycle tests. Add oblique row/column anchors and a depth case
  where a larger X beats row order. The old same-column occlusion fixture gets
  deliberately taller test-owned silhouettes, because yaw can remove that
  particular collision; the genuine overlapping-opaque-pixel assertion remains.
  The isolated alpha fixture uses a wider controlled board to retain a truly
  empty floor sample, not a floor point underneath a relocated body.
- `tests/board_warning_run.gd`: replace superseded option-validation coverage with
  exact union-area/coverage/connectedness and source-to-region joins. Retain all
  source, direction, cancellation, fresh-held and prediction separation coverage.
- `ui/board_comparison_smoke.gd`: replace the obsolete picker matrix in place.
  Check the default slice, floor material/projection join, actual foot/body and
  Alt-floor targeting, resize with a prepared command, both captures, release/
  backlash separation and plain/paper/Stage model-state parity. Old comparison
  controls must not remain visible. Optional captures use the actual encounter.

```sh
# Author syntax only; independent tester runs these without --check-only for RED.
godot --headless --path games/borrowed-turns --check-only --script res://tests/stage_projection_run.gd
godot --headless --path games/borrowed-turns --check-only --script res://tests/standee_board_run.gd
godot --headless --path games/borrowed-turns --check-only --script res://tests/board_warning_run.gd
godot --headless --path games/borrowed-turns --check-only --script res://ui/board_comparison_smoke.gd

# After implementation, graphical evidence with the existing local puppet pack.
godot --path games/borrowed-turns --script res://ui/board_comparison_smoke.gd -- \
  --capture-dir="$PWD/.lore/local/experiments/002-shadow-paper/angled-wavefront/author"
```

Missing seams/materials exit 2; behavioral assertions exit 1. Do not invent
pixel/style correctness tests. Keep generated evidence under `.lore/local/`,
not reboot-volatile `/tmp`. Capture the actual initial/A-held/B-held and release
preview at 1024×720 and 1600×900 after normal settlement. Freeze only scene
processing for readback, not fabricated state or artwork. Compare against
regenerated `38d7e3e` before evidence separately; no current-runtime legacy menu
is required.

Designer reviews the actual result against panel B at both sizes. Ronald judges
source, shove direction, full region, simultaneous warnings and capture removal,
then appearance and standee separation. Technical geometry correctness is not
concept fidelity or human acceptance. Independent tester owns behavioral RED/
GREEN; parent owns the record, Git, fresh oracle and separate quality reviews.

## V1 correction: occluded directional fronts

Independent visual review of the eight `author/v2` images found a material
failure, particularly surviving warm B after holding A at 1024×720: bodies and
HP plates hide the defining front/head while backlash borders dominate. These
images remain valid visual RED. Passing geometry checks did not establish
direction readability.

After the completed frozen GREEN, the parent released focused test authoring
only. Add one inert seam to `wavefront_overlay.gd`:

```gdscript
static func select_visible_cue(candidates: Array, contours: Array,
    project: Callable, occluded: Callable) -> Dictionary
```

Production will build exactly nine candidates: three longitudinal front phases
by three head-side positions. This is one bounded overlay correction, not a
placement framework, menu or new mechanic. Unit inputs are test-owned candidate
geometry, not production positions, artwork, tuning or screenshot coordinates.
Each candidate has a logical `curve: PackedVector2Array` and directional
`head: PackedVector2Array`. `contours` is the existing exact logical union.
`project` maps through the existing ground projection; `occluded` queries
projected actor alpha/source tabs using the already cached image/layout join.
Do not copy images per candidate or create another picking model.

Selection clips curves to the exact union before measuring them. A candidate's
complete head must fit inside the union and be unoccluded, including its
interior/wings, not just its tip or vertices. Probe between curve vertices in
screen space. Require a single continuous exposed curve run at least as long as
the projected head's maximum extent; scattered visible pieces cannot be added
together to qualify. Among qualifying candidates choose the longest continuous
run, with deterministic input-order ties. Numeric tie tolerance may handle
projection roundoff; it is not artistic placement tuning.

Return detached logical geometry:

```text
{status: "visible", candidate: <input index>, curves: <clipped full front parts>,
 heads: <complete head parts>}
```

The front parts retain the full-width projection, including portions naturally
hidden below actors. Selecting an exposed portion does not move the effect above
bodies/tabs or shrink the warning into a tile badge. When no candidate qualifies,
return exactly `{status: "blocked", candidate: -1, curves: [], heads: []}`.
Do not invent an outside-region fallback, clipped arrow fragment or visible
status with no drawable cue. A blocked cue does not erase its continuous source
region; it remains an unresolved visual layout.

Neutral setup returns that blocked result and is not called by the renderer.
The existing warning runner adds tests for exposed-side selection, complete-head
occlusion, between-vertex stripes/continuous runs, exact gap clipping, projected
occlusion queries, deterministic detached outputs and blocked/empty cases.
Existing source/region/prediction tests remain unchanged.

```sh
# Author syntax only; independent tester removes --check-only for new RED.
godot --headless --path games/borrowed-turns --check-only --script res://tests/board_warning_run.gd
```

After independent RED and a separate production release, write only the compact
cue construction/selection join and necessary board draw/occlusion factoring.
Keep source identifiers below actors/tabs in an exposed pocket. Backlash may
receive a bounded hierarchy adjustment, but its complete double-border footprint,
deadline/cost meaning and exact prediction marks must remain unmistakable.
Projection, sizes, source PNGs, Director and model are not correction targets.
Repeat the existing eight actual views against v2, starting with A-held at 1024.
Do not declare the correction successful from visibility-unit GREEN alone.

## Authorized layout intervention: off-grid roster

After the two bounded cue-only corrections still failed the visual objective,
Ronald selected **Try off-board roster**. Keep small true-cell source markers
and move large HP/name plates off the playing plane. This is a new authorized
layout intervention, not permission for another unbounded wavefront patch loop.
The existing `author/v4` images are its visual before reference.

Use one compact, always-visible roster in the Stage's ungridded side margin,
below the Director and outside the grid bounds. Do not shrink the accepted
playing plane, actors or theatre to make room; do not cover status/actions.
Keep names and HP readable at 1024×720 and 1600×900. Names can be ordinary labels
such as You, Pursuer A and Pursuer B, with existing source IDs/shapes. Do not add
character lore or new artwork. Keep roster slots stable by identity while bodies
move or depth order changes. Living membership may compact after death.

Extend the existing **actual drawing and picking input** `standee_layout()` rows:

```text
existing actor/cell/rect/foot/tab_rect/opacity/texture/hp
+ name: String
+ roster_rect: Rect2
```

`tab_rect` becomes the small source-only foot marker, containing the true foot
and fitting inside its projected cell. Do not print HP/name there. `roster_rect`
is the actual off-grid name/HP surface and source-select target, not test-only
geometry or a second copy of actor state. Names stay nonempty/distinct/stable;
tests do not freeze their English wording. HP is current confirmed actor HP,
not selected predicted HP. The source row, body and foot marker all map to the
same actor and true cell. Explicit source targets take priority over artwork;
transparent body gaps and Alt-floor targeting retain existing behavior.
Existing bracket-key selection remains available. No additional appearance menu.

**Neutral setup before independent RED:** add only `name: ""` and
`roster_rect: Rect2()` to the existing rows. Leave v4 drawing, foot-plate geometry,
picking and cues unchanged. No production roster behavior belongs in this setup.

Reuse `tests/standee_board_run.gd` for controlled descriptor geometry, small marker
containment, identity/HP refresh, stable roster slots, source priority over
opaque art, lifetime removal and no invisible baseline-view roster. Existing
native scale/alpha/body/tab/focus tests remain. Reuse
`ui/board_comparison_smoke.gd` for actual roster inspection/capture, current-versus-
preview HP, confirmed pursuer/player damage and death/restart updates, resizing,
view/state parity and exclusion from the real Director seam/grid/control bounds.
Those behavioral assertions use controlled fixture HP and commands, not live
balance values. Production must draw and hit-test the same descriptor fields.

```sh
# Author syntax only; independent tester removes --check-only for RED.
godot --headless --path games/borrowed-turns --check-only --script res://tests/standee_board_run.gd
godot --headless --path games/borrowed-turns --check-only --script res://ui/board_comparison_smoke.gd

# After separate production release, actual same-eight-state evidence.
godot --path games/borrowed-turns --script res://ui/board_comparison_smoke.gd -- \
  --capture-dir="$PWD/.lore/local/experiments/002-shadow-paper/angled-wavefront/roster/author"
```

All new roster evidence belongs under persistent gitignored
`.lore/local/experiments/002-shadow-paper/angled-wavefront/roster/`. Compare the
actual initial, either-held and release-preview views against v4, especially
B after A-held at 1024. Passing roster geometry/selection/HP checks cannot close
the directional-wavefront visual finding. Projection, exact regions, actor
size/art, Director, under-actor effect layer and mechanics remain unchanged.

## Superseding direction: source-driven moving curves

Ronald clarified that the waves mean **motion in curves moving from the attacker
towards the end of the telegraph**, not arrows or a static exposed head. The two
questions are what will be hit and who is attacking. He explicitly kept the
telegraph below the standees and asked that each affected tile be covered.
The parent confirmed that interpretation and Ronald authorized continuing.

This supersedes the nine-candidate visibility/head-placement objective and its
three tests. Retire that runtime heuristic in the separate production phase,
rather than layering motion over it. Failed static/roster evidence stays failed;
this clarification does not retroactively accept it. Preserve all exact-region,
source/occurrence, ownership, preview, projection, alpha-picking and roster HP/
selection coverage. The approved angle, Director, standee sizes, source artwork,
model and current roster layout remain fixed. Do not paint over foreground or
move warnings above actors to rescue visibility.

**Presentation:** fill each model-affected tile completely, edge to edge, with a
readable source-colored wash. Overlap retains both sources; no inset narrow lane,
extra source cell, hull, invented push destination or inferred victim. Draw
repeating curved fronts moving away from the source foot along its actual
logical attack direction to the far end of the exact affected region. Use a
small fixed pair of staggered fronts, not a placement search or a glyph per tile.
No directional arrowheads or side pockets. A source-colored foot marker may
establish identity without claiming that its own cell is threatened.

**One existing phase:** consume `shadow.frame().loop_phase`, already advanced by
the scene's normal `shadow.advance(delta)`. Do not add a clock, controller, model
tick or independent timer. A visual cycle never commits a command or changes
turns, budgets, HP, victims or targets. Each current source renders independently.
Capture preview keeps both current warnings; confirmation removes only the
captured occurrence. A later fresh announcement can repeat while an older action
remains held. Backlash and selected release keep their distinct existing meaning.

**Compact actual draw-input seam:**

```gdscript
static func wave_geometry(region: Dictionary, phase: float) -> Dictionary
# {fills: Array[PackedVector2Array],
#  fronts: Array[{progress: float, curves: Array[PackedVector2Array]}]}

func announcement_waves() -> Array
# Existing announcement_regions() rows, plus fills and fronts above.
```

`fills` is a detached copy of the exact logical contours, not an inset.
Normalized `progress` wraps with the supplied phase; front IDs are array order.
Each curve is built across the lane with a bow in the forward direction. Its
longitudinal travel starts from the center of the real `origin` cell, not the
footprint's near edge or the player's position, and finishes at the region's
furthest forward edge. Clip every polyline to the exact logical union before
projecting it through the existing shared homography. Empty regions have no
fronts. An early front may be outside the first affected tile and therefore have
no clipped parts; this must not highlight the source cell. Geometry stays below
the actors and small foot markers. The renderer must consume these same fields,
not recompute different test-only geometry.

**Neutral setup now:** the static method returns `{fills: [], fronts: []}` and
the board method returns `[]`. Both are unused by current rendering. No production
motion, fill, old-runtime removal or layout changes before independent RED.

Reuse the warning runner for controlled cardinal progress, wrapping, curved
geometry, actual source anchoring/translation, full-cell coverage, clipping
through gaps, determinism/detachment, shared phase, capture suppression and fresh/
held occurrence joins. Replace the obsolete head/visibility tests explicitly.
Reuse the scene runner for real renderer-phase/data joins in its existing capture,
preview and resize states, plus a short ordinary-process idle interval confirming
motion without any gameplay change. Keep other focused runners unchanged.

```sh
# Author syntax only. Independent tester removes --check-only for clean RED.
godot --headless --path games/borrowed-turns --check-only --script res://tests/board_warning_run.gd
godot --headless --path games/borrowed-turns --check-only --script res://ui/board_comparison_smoke.gd

# After separate production release: actual playable animated slice.
godot --path games/borrowed-turns -- --presentation=stage --encounter=two-pursuers
```

All evidence goes under persistent ignored
`.lore/local/experiments/002-shadow-paper/source-wave-motion/`. Retain matched
actual initial/either-held/release-preview stills at 1024×720 and 1600×900, but
judge motion from a real-time recording or the live application too. Show both
initial opposing sources and separately capture A/B using normal controls.
Record actual elapsed time and only begin recording after normal startup is
ready; do not encode a slow startup/readback sequence at an invented fixed FPS.
Use existing capture/system recording tools if available; if recording is blocked,
report that and provide the direct live-play command, not a new video framework.
Passing geometry tests or static images cannot establish readable source motion
or human acceptance. Parent owns independent verification and fresh reviews.
