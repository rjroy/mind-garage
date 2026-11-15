# Borrowed Turns

A first playable capture-bargain comparison for one small, turn-based escape encounter. This is a prototype, not evidence that any variant is enjoyable or original. Mind Garage is the research effort, not the game title.

## Run

Requires the installed Godot 4.7.2 executable. There are no packages, downloaded fonts, plugins, generated art, persistence, analytics, or network services.

From the repository root:

```bash
godot --path games/borrowed-turns
godot --path games/borrowed-turns -- --variant=V2
godot --path games/borrowed-turns -- --variant=V6 --invert
```

`--variant=V1` through `--variant=V6` launch each bargain independently. `--invert` enables the freely selectable push/pull preview; otherwise it starts off. The GUI provides the same six variant buttons and preview configuration without completing or unlocking anything. Changing configuration starts a clean encounter; a changed unfinished run first asks for confirmation. No other launch flags alter the rules or fixture.

Default requested window: 1280 × 800. Minimum: 1024 × 720. Native Control layout uses actual viewport dimensions without reducing text through a global stretch factor. A tiling compositor may override requested native window dimensions. Portrait, phone and gamepad support are not part of this prototype.

## Play and inspect

The top line shows health, exit position/opening turn, turn and action status. Reach the exit while it is open; defeating every pursuer is not required.

1. Choose **Move**, **Capture**, **Release**, **Wait**, or **Discard**.
2. Choose a cell or, for capture, an enemy square/intention row.
3. Inspect the predicted board overlay, health/position/outcome summary and the right rail's **Preview** tab. It lists the exact ordered effects from the model. **Recent events** remains available in the other tab and shows only committed events.
4. Press **Confirm** to act. **Cancel** or right click backs out without advancing play.

Rust dashed arrows and hatched cells show every current enemy intention. Teal outlines mark legal targets; solid arrows and hollow pawns mark exact predicted movement/effects, not the live state. The numbered grid is `[x,y]`, increasing right/down. `Y` is you; squares `A` and `B` are pursuers. A teal cross marks V6's committed release cell. Overlap numbers count threatening plans; inspecting a cell names their sources.

Capture cancels one current attack, not the source's future attacks. Stored plans can only be released on a later turn. There is one storage slot, no deck and no basic attack. Read the active bargain and stored-plan constraints in the right rail. Its upper information region scrolls when longer rules/constraints exceed the available height.

- **V1 · Action cost:** Capture and discard each use an action; no expiry.
- **V2 · Adjacent capture:** Choose a source, then a legal optional approach endpoint if needed. Step and capture confirm together.
- **V3 · Two-action expiry:** Use the plan by the second action after capture or lose it harmlessly.
- **V4 · Source linked:** The source must survive until release consumes the plan.
- **V5 · Delayed backlash:** One free capture per turn, then an ordinary action. That same-turn action counts toward the two-action deadline. Discard or missing the deadline deals 1 direct damage.
- **V6 · Fixed target:** Choose a release cell as part of capture. Later release must use that same cell; reposition or discard if it becomes invalid.

With Invert preview enabled, a held shove offers **Pull instead of push** during release targeting. It changes only displacement, not damage or V6's committed cell. Bolt cannot invert. Selection and preview are free; only a confirmed model command changes the encounter.

**Restart** restores the same fixture, variant and preview configuration. A finished encounter offers **Replay this variant** without a replacement dialog. Win/failure leaves the board and history visible; all variants remain directly accessible.

### Keyboard

Tab / Shift+Tab traverses native controls; Space / Enter activates them. M selects Move, C Capture, L Release. When the board has focus, arrows move its inspection cursor without moving the player; Enter selects the cell and focuses Confirm. A separate Enter commits. Esc backs out one targeting stage; Ctrl+R requests restart. Controls help is available without advancing play. Mouse hover is inspection only.

## Structure and evidence boundaries

- `content/escape.gd`: the one shared provisional production fixture, preserving integer coordinate types. Tests own their separate fixtures. Content has not been tuned for engagement.
- `model/encounter.gd`: authoritative rules, legality, footprints, resolution and nonmutating predictions.
- `ui/encounter_ui.gd`: native control composition, targeting transactions and presentation state.
- `ui/board.gd`: drawing and screen/cell conversion only; receives model footprints and event geometry.
- `ui/presentation.gd`: theme and display formatting.
- `scenes/encounter.tscn`: runnable main scene.

The UI enumerates candidate commands and calls `assess`; it does not reproduce movement, capture or ray legality. Current threats come from `snapshot.intentions`; actual predicted and committed rays come from ordered events. The production encounter is intentionally unchanged from the executable rules. A no-capture route may exist; that is a content/experiment diagnostic, not permission to silently tune the board or claim meaningful capture choices.

The lifecycle and run logs printed to stdout describe starts, submitted commands and results. They are runtime diagnostics, not stored player telemetry. History exists only in memory for the current encounter.

## Focused UI checks

```bash
godot --headless --path games/borrowed-turns --editor --quit
godot --headless --path games/borrowed-turns --quit-after 3 -- --variant=V6 --invert
godot --headless --path games/borrowed-turns --script res://ui/smoke.gd
godot --path games/borrowed-turns --script res://ui/smoke.gd -- --capture-dir=/tmp/opencode/borrowed-turns-ui
```

The smoke runner instantiates the real scene, activates actual button signals and emits board GUI events. It checks selection/confirmation, nonmutating previews, variant isolation, V2/V6 staged capture, V5 free capture, Invert, history, restart protection and terminal controls against the real model. It has no alternate game behavior or gameplay shortcut. It does not replace native OS pointer/keyboard testing or the separate model suite in `TESTING.md`.

Capture mode uses explicitly sized rendered Godot SubViewports because a tiling compositor can ignore native window resize requests. PNGs cover 1024 × 720, 1280 × 800 and 1600 × 900 plus targeting/stored/terminal states; they demonstrate actual Control layout and rendering, not native window-manager resize acceptance or high-DPI correctness. Do not use `--capture-dir` with the headless dummy renderer. The independent tester owns final native input/runtime checks, and the independent oracle owns correctness/engineering review.
