# Borrowed Turns

One small turn-based escape encounter built around stealing announced enemy abilities. This is revision 02's coherent shared baseline, following Ronald's rules revision. It is not a new six-way comparison or evidence of enjoyment. Mind Garage names the research effort, not this game.

## Run

Requires the installed Godot 4.7.2 executable. No packages, external services, downloaded fonts, telemetry or persistent saves. The optional stage uses three approved source images.

From the repository root:

```bash
# Import source textures once after a fresh checkout, or open the Godot editor.
godot --headless --editor --path games/borrowed-turns --import
godot --path games/borrowed-turns
godot --path games/borrowed-turns -- --presentation=plain
godot --path games/borrowed-turns -- --presentation=paper
godot --path games/borrowed-turns -- --presentation=stage
```

The normal game defaults to the original escape encounter, identified internally as `R2`. The optional **Two pursuers** encounter uses the same rules/model for a playable visual experiment. The original V1–V6 chooser, variant launch modes, discard and wait are removed. The original build at `fd8e91d` and its archive/evidence remain historical records; the working game does not embed a parallel legacy engine.

The former Invert preview is not part of the current core rules; the retired `--invert` option is rejected. There is no progression gate.

The default candidate view is **paper**: a reversible one-shove presentation pilot, not accepted production art. **Paper pilot** switches between that view and the plain renderer. **Stage view** opens the optional theatre; its view selector returns to either baseline. Switching does not reset the encounter, spend points, change a selected command or replay history. It cancels only in-flight visual feedback and restores settled ownership facts. The immutable comparison baseline remains `ba3ab7a`; all views use the same model and selected fixture. Unknown presentation or encounter values are rejected.

Requested window: 1280 × 800; minimum 1024 × 720. Native Controls follow actual viewport dimensions without globally shrinking fonts. A tiling compositor may refuse requested native dimensions. Phone/portrait/gamepad support is out of scope.

## Turn and controls

Reach the exit when it is open. Killing every pursuer is not required.

- **AP** means action points. Release uses 1 AP and no MP.
- **MP** means movement points. A confirmed one-cell cardinal move uses 1 MP and no AP.
- **Capture** is free, including replacement. It can interleave with movement/releases; no arbitrary per-turn cap applies. Each currently announced occurrence can be captured once. Capturing cancels that occurrence, not the source's future announcements.
- A newly captured ability can be released this turn, within that ability's own range/shape.
- **End turn** explicitly resolves due backlash and surviving uncanceled enemy plans, then refreshes AP/MP and announcements. Budgets reaching zero never auto-end the turn. Free capture can still be available at zero AP and MP.

Choose **Move**, **Capture**, **Release** or **End turn**, then choose a source/target if needed. Inspect the predicted board overlay and summary; **Preview** lists exact ordered effects in the right rail, or an upper-stage sheet in stage view. A separate **Confirm** commits. **Cancel** or right click backs out without changing the model. End turn also previews and requires confirmation, even if no points remain. **Recent events** contains committed events only and remains one tab away.

Keyboard: Tab / Shift+Tab traverses controls; Space / Enter activates. M selects Move, C Capture, L Release, E prepares End turn. With board focus, arrows inspect and Enter selects a cell; a separate Enter confirms. Esc cancels, Ctrl+R requests restart. Controls help does not advance play.

## Storage, deadlines and backlash

The single stored ability retains its source identity/direction, range, damage, radius and push capability. The top budget line always shows its exact deadline: **Release before ending turn N**. Capture during T permits release through all of T+1. Ending T+1 discharges storage before enemies; successful ordinary commands do not age an action-count timer.

Capturing while holding an ability immediately discharges the old one at the player's position before attempting acquisition. Burst backlash centers the real area on the player. Line backlash hits the player and its stored direction. Damage and enemy displacement come from the held ability, not a generic fixed penalty. Backlash may harm pursuers and can be deliberate, but it always risks the player; there is no discard route.

Inspect the exact replacement preview. It may acquire the selected source, kill the player without acquiring anything, or discharge successfully but fail acquisition because the selected source died or moved out of reach. **Capture failed** is that legal partial outcome, not a rolled-back or invalid command. The summary exposes it before confirmation; a legal lethal choice remains confirmable.

### Reading the board

- `Y`: you; labeled pawns: pursuers; double doorway labeled `EXIT`: escape. In plain view you are round and enemies square; the paper pilot gives you a narrow coat and shove pursuers a broader cut-paper stance. Other ability kinds retain baseline pawns. Coordinates are `[x,y]`, right/down.
- Rust hatches and dashed arrows: current enemy intentions. Areas show all affected cells rather than a false ray through them. Inspect/select an enemy or intention row to identify its source and footprint.
- **Double rust borders:** held ability's current **Backlash here** footprint, even before its deadline. Moving updates its center, not its deadline.
- Teal outlines/dots: legal candidates. Solid routes, outlined effect cells and hollow pawn positions: the selected command's exact prediction. Cross marks show predicted deaths. The live board changes only after confirmation.
- Cell inspection names overlapping enemy sources and held backlash. The right rail shows ability range/shape/strength and complete current intentions, with scrolling where needed. Complete Preview/history lines also scroll; they are not hidden in tooltips.

Restart restores this fixture, including fresh budgets, empty storage and history. Win/failure leaves the final board/history visible and offers **Replay encounter**, with no confirmation needed for a finished run.

## One-shove shadow-paper pilot

Paper figures stay comparatively still; a jointed arm/open-palm silhouette is the expressive action-shadow. An announcing shover presses forward, capture folds/transfers that gesture to a framed motif beside the provisional artifact token, release unfolds it along the actual model footprint, and backlash discharges from the player with a self-hit emphasis. No ordinary physical cast shadows, generated artwork, lamp identity, lighting mechanics, new abilities or geometry changes are introduced.

Capture removes only that turn's announced gesture. A source that can announce next turn regains it, even while the old captured gesture remains held. Source death prevents a fresh announcement but does not erase a valid stored ability. Replacement shows old backlash before new acquisition; failed/lethal acquisition never produces a transfer. Full footprint markings remain authoritative, including when player death stops later damage processing. Gesture playback on lethal backlash collapses at the player rather than implying later victims were hit.

All finite shadow cues are event-driven and complete independently of persistent idle/held loops. Gameplay input waits for finite feedback, not for an arbitrary scene sleep or an endlessly looping animation. Restart and view changes cancel old visual work. The model commits once on confirmation; animation never decides gameplay results. Backlash/release/transfer duration is part of this bundled presentation experiment, not evidence isolating one visual cause.

FY3 remains **open pending Ronald's visual reaction**, and the next mechanics step remains blocked. Passing technical checks or an agent's visual review is not final style acceptance.

## Optional theatre stage

The approved backdrop, paper floor and transparent foreground are composed in Godot 2D without changing their source pixels. The theatre receives the main viewport width rather than the old board column. Status and action strips remain visible; **Details** explicitly opens the upper-screen sheet, choosing Preview when a command is prepared, otherwise Plans. Selecting a command no longer automatically covers the performers. Long ordered previews, plans and history scroll within the sheet, not over the playable floor.

The grid follows the model's runtime width and height, not an image's painted cell count. Stable crops, quarter-turns, subtle color variation and seams make cells read as separate paper pieces. The floor shader, board marks, actor feet and mouse targeting share one perspective map. This slice does not add a player-facing grid-size setting. On the dark floor, threats use light coral and legal choices use pale mint; their meaning is unchanged.

The original encounter retains its provisional figures/shove feedback. The two-pursuer Stage profile below uses the approved standee candidates and temporary backdrop puppets. Neither introduces a lantern mechanic. Source-art approval does not establish in-game visual acceptance. Minimum-size legibility, overlap and interaction still require Ronald's review.

### Playable two-pursuer visual slice

```bash
godot --path games/borrowed-turns -- \
  --presentation=stage --encounter=two-pursuers \
  --puppet-pack="$PWD/.lore/local/experiments/002-shadow-paper/dual-layer/puppets"
```

The visible encounter selector also opens **Two pursuers** from normal play. Changing encounters explicitly confirms a new run; Cancel keeps the existing one. Restart restores the selected encounter. View changes preserve its state, selected command and history. Omitting `--encounter` still opens the original encounter; omitting `--presentation` still selects paper.

**Local material prerequisite:** the temporary pack must contain native RGBA `a-body.png`, `a-hands.png`, `b-body.png`, `b-hands.png` (290×145) and `p-lantern.png` (145×145). The default directory is the repository-local path in the command above; `--puppet-pack` overrides it. These derivatives and their inspected extraction recipes remain local, not bundled source assets. A fresh checkout alone cannot supply them. Missing/invalid material fails clearly on direct launch; a chooser failure keeps the existing run and reports the setup problem. No generated substitutes or tiny primitive fallback are used for this selected Stage encounter.

The 5×5, wall-free fixture deliberately starts A behind the player and B in front in the same logical column. Both announce existing shoves. The Stage ground plane now yaws about 30 degrees: that column appears staggered, while the accepted standee sizes, source images and native foot anchors remain unchanged. Small **P / A / B** source markers stay at the true actor feet, above overlapping art. Names and current HP appear in an always-visible roster to the right of the grid, below the Director. Click a roster row, visible figure pixels or a foot marker to select the same actor; transparent image padding clicks through. Roster slots stay fixed as figures move, and dead sources lose their row. Hover/focus a rear source to reduce front-piece opacity. With board focus, **[ / ]** cycles figures and Enter selects; arrows still inspect floor cells. **Alt-click** explicitly selects floor through figures. A legal floor target also takes priority when the overlapping actor is not a legal target for the chosen operation.

The upper theatre is not a map projection: A stays left, B right, player central. Only currently player-threatening announcements press forward; others stay watchful. Capture either source on the actual board: its current performance departs into a mint-tethered held motif beside/above the lantern handle, while the other source continues. B's held hands turn outward rather than continue attacking the player. Source ID plus turn distinguishes an old held action from a fresh announcement. No damage occurs during rehearsal or preview.

Confirmed release, backlash and enemy actions follow the shared controller's actual ordered event slices. Player reaction requires recorded player damage/displacement, including zero-damage pushes; enemy-only actions never invent a player hit. Map motion replays recorded movement/displacement and settles at the exact committed state. The ordinary Move/Capture/Release/End turn controls, deadlines, replacement failure, escape/failure and replay remain usable beyond the first exchange. In particular, A-to-B replacement can push B out of capture reach: that real partial failure is not forced into a transfer.

**Composition tradeoff:** taller standees overlap more depth rows. The playable grid begins lower, with an extended ungridded floor apron retaining the stage seam; this separates faces from the performance without moving logical actors apart. Face/lantern identity, rear-source access and source tabs need actual human play review at 1024×720 and normal size. Temporary puppets remain lower-resolution concept cutouts, not a finished matching cast or a general crowd director.

### Angled board and wavefront overlays

Ronald accepted the Director images and standee sizes, then selected the contour/wavefront concept as a starting direction. The normal **Stage / Two pursuers** entry now opens that candidate immediately, without a hidden appearance choice. The earlier ribbon/stamp controls and runtime hand decorations are retired; checkpoint `38d7e3e` preserves that experiment for historical comparison. Source artwork, mechanics and the original escape/plain/paper baselines are unchanged.

Current enemy warnings cover every affected tile edge to edge, beneath the standees. Curved fronts repeatedly travel from the attacker's position along its actual attack direction to the end of that footprint. They do not point at or track the player. **Cool A/diamond** and **warm B/circle**, matching the foot markers and roster, identify the sources. Each announcement has its own moving fronts, including where the affected regions overlap. These exact regions come from model-authored cells, not a convex hull, an extra source square or an invented push destination. The figures remain upright; the floor material, grid, regions, motion, feet, depth sorting and picking share one ground-plane homography.

Capture removes only that source's current region. A fresh announcement may return while an older occurrence is held. Double rust borders still mean held backlash here; mint marks still show legal choices and exact command predictions, not additional enemy wavefronts. Costs, deadline, consequence summary, Confirm/Cancel and explicit Details remain available.

The ungridded apron retains the accepted horizontal theatre seam while sampling the yawed plane. Angle reduces alignment, not every possible overlap; rear-source access still matters. The concept's different character designs were not adopted. This is a playable candidate, not a claim of human legibility or visual acceptance.

The roster replaces the previous large HP/source plates without shrinking the board or actors. It uses the same confirmed actor data for drawing and selection; preview damage does not update its HP before confirmation. The earlier static arrowhead and visibility-placement experiments failed the visual objective and are retired. The moving curves use the existing Director/paper rehearsal phase, not a new game clock: watching them never spends points, damages actors or advances a turn. Their source connection and area readability still require human review in motion, especially B while A is held.

The focused scene runner reuses the existing controls. Its behavioral assertions use controlled fixtures; optional graphical evidence then uses the actual two-pursuer encounter:

```bash
godot --headless --path games/borrowed-turns --script res://tests/board_warning_run.gd
godot --headless --path games/borrowed-turns --script res://ui/board_comparison_smoke.gd
godot --path games/borrowed-turns --script res://ui/board_comparison_smoke.gd -- \
  --capture-dir="$PWD/.lore/local/experiments/002-shadow-paper/source-wave-motion/author/v1"
```

The same local puppet pack is required. Captures include actual initial, A-held, B-held and release-preview states at both 1024×720 and 1600×900. Only scene processing is paused during readback, after normal settlement. Use a graphical renderer and a fresh directory under persistent, gitignored `.lore/local/`; this runner rejects other capture locations. These are injected-control author/test evidence, not physical input, human legibility judgments or independent proof of enjoyment.

For a live motion comparison, use the Stage / Two pursuers launch command above. Watch both sources, then choose Capture, click A's roster/marker/body and Confirm: only A's current tile warning and traveling fronts disappear. Restart and repeat with B. A selected capture preview does not remove warnings. The matching initial/held stills establish composition, but cannot establish readable motion. Any recording should begin after startup is ready and preserve actual elapsed timing, rather than assigning a fixed FPS to slow readbacks.

Focused checks (the real-scene checks require that local pack):

```bash
godot --headless --path games/borrowed-turns --script res://tests/standee_board_run.gd
godot --headless --path games/borrowed-turns --script res://tests/two_pursuer_presentation_run.gd
godot --headless --path games/borrowed-turns --script res://ui/smoke.gd -- --focus=two-pursuers
godot --headless --path games/borrowed-turns --script res://ui/smoke.gd -- \
  --focus=two-pursuers-cli --presentation=stage --encounter=two-pursuers
```

The standalone capture-motion study tool was retired after checkpoint `42702e3`; that checkpoint preserves its original launch and test instructions. The live two-pursuer rig retains the study glow shader.

Focused stage checks and actual rendered captures:

```bash
godot --headless --path games/borrowed-turns --script res://tests/stage_projection_run.gd
godot --headless --path games/borrowed-turns --script res://ui/smoke.gd -- --focus=stage
godot --path games/borrowed-turns --script res://ui/smoke.gd -- \
  --focus=stage --capture-dir=/tmp/opencode/borrowed-turns-stage-inspection
```

Captures named `stage-*-encounter.png` use the actual encounter. `stage-*-shove-preview.png` and `stage-*-shove-held.png` use controlled fixtures. These focused checks do not replace the full rendered completion gate or independent review.

## Provisional production content

`content/escape.gd` is the one integer-typed shared fixture: 7 × 7, player at `[2,3]` with 6 HP, exit `[6,3]` opening on turn 3, and two wall cells. Starting rules are 2 AP, 1 MP and capture reach 1. Bolt, shove and burst sources start adjacent so capture, same-turn release and deliberate area replacement can be explored immediately. Their data differ in geometry, range, damage and displacement.

These content choices are bounded AI implementation assumptions, not balance findings or permanent tuning. The encounter is not a mandatory-kill objective. The independent tester should diagnose escape/capture/replacement routes and dead ends rather than infer engagement from available commands. Smoke assertions use controlled test-owned fixtures, not these production numbers.

## Implementation and focused checks

- `model/encounter.gd`: authoritative legality, budgets, complete intentions/backlash footprint, exact nonmutating assessments and ordered resolution.
- `ui/encounter_ui.gd`: native shell, selection/confirmation, input and presentation lifecycle. Enumerates candidate commands and assesses them; does not simulate geometry or damage.
- `ui/board.gd`: grid rendering, screen/cell conversion and presentation of model footprints/events. Actor movement/death markers follow model events; no displacement convention is reimplemented.
- `ui/presentation.gd`: theme, ability/event formatting and command summaries.
- `ui/shadow_presentation.gd`: detached deterministic `RefCounted` projection with `reset(snapshot, generation)`, `observe(before, command, after, generation)`, `advance(delta)` and `frame()`. Persistent shove announcements/held ownership are separate from finite capture/release/backlash/resolve cues. Inputs/outputs are deep copies; stale generations and unchanged transitions are ignored.
- `ui/shadow_renderer.gd`: runtime polygon paper figures and palm silhouettes, using board screen anchors and model-authored presentation facts. No gameplay geometry, damage or displacement rules.
- `ui/smoke.gd`, `ui/smoke_fixtures.gd`: focused integration checks through actual scene controls with controlled inputs. They contain no alternate gameplay path or test-only production command.
- `scenes/encounter.tscn`: main scene.

```bash
godot --headless --path games/borrowed-turns --editor --quit
godot --headless --path games/borrowed-turns --quit-after 3
godot --headless --path games/borrowed-turns --script res://ui/smoke.gd
godot --headless --path games/borrowed-turns --script res://tests/shadow_presentation_run.gd
godot --headless --path games/borrowed-turns --script res://ui/smoke.gd -- --focus=shadow
godot --path games/borrowed-turns --script res://ui/smoke.gd -- --capture-dir=/tmp/opencode/borrowed-turns-r2-ui
godot --path games/borrowed-turns --script res://tools/capture_shadow_pilot.gd -- --out-dir=/tmp/opencode/borrowed-turns-fy3-evidence
```

Focused UI smoke covers the 2-AP/4-MP interleaving example, repeated/zero-budget free capture, actual area replacement, acquisition failure/death, turn deadlines, explicit End turn, inherited release ranges, same-turn release, reset/history, terminal controls and normal shove preview synchronization. Shadow integration additionally compares plain/paper assessments, model states/events/history for the same real control sequence; checks invalid/canceled selection, duplicate confirmation during feedback, view/restart cancellation, reannouncement while held, and failed/lethal replacement. It activates real button signals and emits board GUI events; it is **not physical OS mouse/keyboard evidence**, the independent model suite, or final acceptance. Controller-only tests cannot establish visual/runtime acceptance.

Capture mode renders explicit-size Godot SubViewports at 1024 × 720, 1280 × 800 and 1600 × 900 plus controlled behavioral states. PNGs establish actual layout/rendering at those dimensions, not compositor-native resizing or HiDPI acceptance. Controlled screenshots deliberately show fixture budgets/HP/actors different from production; filenames name the tested state. Use a graphical renderer for captures, not the headless dummy renderer.

The reusable shadow capture tool drives the actual scene controls, saves production plain/paper comparisons plus labeled controlled lifecycle/paused/overlap/failure states, two 30-fps PNG motion sequences and a `manifest.json` containing fixtures, states, presentation frames, drawn effect footprints and legacy-pulse activity. Paused stills first sample normal scene processing, including the controller, feedback budget and bound board tween, then disable the whole scene subtree during image readback. These are runtime evidence, not shipping art. With an already available ffmpeg, encode each sequence using its manifest frame count, for example:

```bash
ffmpeg -framerate 30 -i /tmp/opencode/borrowed-turns-fy3-evidence/normal-frames/frame-%04d.png -frames:v FRAME_COUNT -c:v libx264 -pix_fmt yuv420p /tmp/opencode/borrowed-turns-fy3-evidence/normal.mp4
```

Use the count from that capture's manifest, not a permanent count; it prevents stale frames from a prior scratch run entering a clip. No ffmpeg installation or asset-pipeline integration is required. The verified `tools/rendered_smoke_gate.py` remains unchanged and still requires the full smoke success summary, clean child exit and terminal `r2-escaped.png` capture; a focused early-exit smoke is not its replacement.

Runtime diagnostics print starts, submitted commands and results to stdout. Event history exists only in memory. The separate read-only tester owns runtime/input evidence; the oracle owns independent correctness and engineering review. See the revision-02 executable and interface briefs in `.lore/work/experiments/001-hook-discovery/` for authority and remaining evidence boundaries.
