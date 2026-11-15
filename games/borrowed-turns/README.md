# Borrowed Turns

One small turn-based escape encounter built around stealing announced enemy abilities. This is revision 02's coherent shared baseline, following Ronald's rules revision. It is not a new six-way comparison or evidence of enjoyment. Mind Garage names the research effort, not this game.

## Run

Requires the installed Godot 4.7.2 executable. No packages, external services, downloaded fonts, generated assets, telemetry or persistent saves.

From the repository root:

```bash
godot --path games/borrowed-turns
```

The normal game opens directly into one baseline, identified internally as `R2`. The original V1–V6 chooser, variant launch modes, discard and wait are removed. The original build at `fd8e91d` and its archive/evidence remain historical records; the working game does not embed a parallel legacy engine.

The former Invert preview is not part of the current core rules; the retired `--invert` option is rejected. There is no progression gate.

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

- Round `Y`: you; square labeled pawns: pursuers; double doorway labeled `EXIT`: escape. Coordinates are `[x,y]`, right/down.
- Rust hatches and dashed arrows: current enemy intentions. Areas show all affected cells rather than a false ray through them. Inspect/select an enemy or intention row to identify its source and footprint.
- **Double rust borders:** held ability's current **Backlash here** footprint, even before its deadline. Moving updates its center, not its deadline.
- Teal outlines/dots: legal candidates. Solid routes, outlined effect cells and hollow pawn positions: the selected command's exact prediction. Cross marks show predicted deaths. The live board changes only after confirmation.
- Cell inspection names overlapping enemy sources and held backlash. The right rail shows ability range/shape/strength and complete current intentions, with scrolling where needed. Complete Preview/history lines also scroll; they are not hidden in tooltips.

Restart restores this fixture, including fresh budgets, empty storage and history. Win/failure leaves the final board/history visible and offers **Replay encounter**, with no confirmation needed for a finished run.

## Provisional production content

`content/escape.gd` is the one integer-typed shared fixture: 7 × 7, player at `[2,3]` with 6 HP, exit `[6,3]` opening on turn 3, and two wall cells. Starting rules are 2 AP, 1 MP and capture reach 1. Bolt, shove and burst sources start adjacent so capture, same-turn release and deliberate area replacement can be explored immediately. Their data differ in geometry, range, damage and displacement.

These content choices are bounded AI implementation assumptions, not balance findings or permanent tuning. The encounter is not a mandatory-kill objective. The independent tester should diagnose escape/capture/replacement routes and dead ends rather than infer engagement from available commands. Smoke assertions use controlled test-owned fixtures, not these production numbers.

## Implementation and focused checks

- `model/encounter.gd`: authoritative legality, budgets, complete intentions/backlash footprint, exact nonmutating assessments and ordered resolution.
- `ui/encounter_ui.gd`: native shell, selection/confirmation, input and presentation lifecycle. Enumerates candidate commands and assesses them; does not simulate geometry or damage.
- `ui/board.gd`: grid rendering, screen/cell conversion and presentation of model footprints/events. Actor movement/death markers follow model events; no displacement convention is reimplemented.
- `ui/presentation.gd`: theme, ability/event formatting and command summaries.
- `ui/smoke.gd`, `ui/smoke_fixtures.gd`: focused integration checks through actual scene controls with controlled inputs. They contain no alternate gameplay path or test-only production command.
- `scenes/encounter.tscn`: main scene.

```bash
godot --headless --path games/borrowed-turns --editor --quit
godot --headless --path games/borrowed-turns --quit-after 3
godot --headless --path games/borrowed-turns --script res://ui/smoke.gd
godot --path games/borrowed-turns --script res://ui/smoke.gd -- --capture-dir=/tmp/opencode/borrowed-turns-r2-ui
```

Focused UI smoke covers the 2-AP/4-MP interleaving example, repeated/zero-budget free capture, actual area replacement, acquisition failure/death, turn deadlines, explicit End turn, inherited release ranges, same-turn release, reset/history, terminal controls and normal shove preview synchronization. It activates real button signals and emits board GUI events; it is **not physical OS mouse/keyboard evidence**, the independent model suite, or final acceptance.

Capture mode renders explicit-size Godot SubViewports at 1024 × 720, 1280 × 800 and 1600 × 900 plus controlled behavioral states. PNGs establish actual layout/rendering at those dimensions, not compositor-native resizing or HiDPI acceptance. Controlled screenshots deliberately show fixture budgets/HP/actors different from production; filenames name the tested state. Use a graphical renderer for captures, not the headless dummy renderer.

Runtime diagnostics print starts, submitted commands and results to stdout. Event history exists only in memory. The separate read-only tester owns runtime/input evidence; the oracle owns independent correctness and engineering review. See the revision-02 executable and interface briefs in `.lore/work/experiments/001-hook-discovery/` for authority and remaining evidence boundaries.
