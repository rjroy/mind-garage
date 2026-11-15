# Borrowed Turns

One small turn-based escape encounter built around stealing announced enemy abilities. This is revision 02's coherent shared baseline, following Ronald's rules revision. It is not a new six-way comparison or evidence of enjoyment. Mind Garage names the research effort, not this game.

## Run

Requires the installed Godot 4.7.2 executable. No packages, external services, downloaded fonts, generated assets, telemetry or persistent saves.

From the repository root:

```bash
godot --path games/borrowed-turns
godot --path games/borrowed-turns -- --presentation=plain
godot --path games/borrowed-turns -- --presentation=paper
```

The normal game opens directly into one baseline, identified internally as `R2`. The original V1–V6 chooser, variant launch modes, discard and wait are removed. The original build at `fd8e91d` and its archive/evidence remain historical records; the working game does not embed a parallel legacy engine.

The former Invert preview is not part of the current core rules; the retired `--invert` option is rejected. There is no progression gate.

The default candidate view is **paper**: a reversible one-shove presentation pilot, not accepted production art. **Paper pilot** switches between that view and the plain renderer without resetting the encounter, spending points, changing a selected command or replaying history. A view switch cancels only in-flight visual feedback and restores settled ownership facts. The immutable comparison baseline remains `ba3ab7a`; both current view modes use the same model and fixture. Unknown presentation values are rejected.

Requested window: 1280 × 800; minimum 1024 × 720. Native Controls follow actual viewport dimensions without globally shrinking fonts. A tiling compositor may refuse requested native dimensions. Phone/portrait/gamepad support is out of scope.

## Turn and controls

Reach the exit when it is open. Killing every pursuer is not required.

- **AP** means action points. Release uses 1 AP and no MP.
- **MP** means movement points. A confirmed one-cell cardinal move uses 1 MP and no AP.
- **Capture** is free, including replacement. It can interleave with movement/releases; no arbitrary per-turn cap applies. Each currently announced occurrence can be captured once. Capturing cancels that occurrence, not the source's future announcements.
- A newly captured ability can be released this turn, within that ability's own range/shape.
- **End turn** explicitly resolves due backlash and surviving uncanceled enemy plans, then refreshes AP/MP and announcements. Budgets reaching zero never auto-end the turn. Free capture can still be available at zero AP and MP.

Choose **Move**, **Capture**, **Release** or **End turn**, then choose a source/target if needed. Inspect the predicted board overlay and summary; the right rail's **Preview** tab lists exact ordered effects. A separate **Confirm** commits. **Cancel** or right click backs out without changing the model. End turn also previews and requires confirmation, even if no points remain. **Recent events** contains committed events only and remains one tab away.

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
