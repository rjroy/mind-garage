---
title: "Borrowed Turns: first prototype interface brief"
date: 2026-11-15
status: draft
tags: [game-design, experiment, interface]
related: [record.md, capture-bargains.md, executable-rules.md]
---

# Borrowed Turns: interface brief

## Scope and authority

Design for Ronald's first individually playable V1–V6 encounters: understand the threats, borrow one plan, inspect its consequences, and attempt escape. The board is the experience; the surrounding controls serve a precise operating task. This brief specifies presentation and input, not executable game rules.

The current build authorization in the assignment supersedes the older documents' unbuilt/planning-only status. The finalized provisional rules and API in `executable-rules.md` govern implementation; older bargain proposals retain provenance. Do not treat this brief as evidence of enjoyment or a progression design.

Use the supplied player brief and encounter records as the discovery answers. Desktop mouse and keyboard, windowed landscape, and the sizes below are design assumptions for this prototype, not previously established player preferences. No interview, generated concept image, asset pipeline, added font, package, or plugin is needed. The original invocation produced only this document; the subsequent authorized UI implementation lives under `games/borrowed-turns/`. Independent runtime and engineering acceptance remain separate.

## Selected direction: the stolen route

A quiet, pale mineral-green floor plan, dark ink figures, ochre exit markings, and two kinds of annotated route: rust-colored enemy intentions and blue-green borrowed actions. Capturing changes the ownership of an existing plan rather than producing a collectible card. The signature moment is the enemy's annotated line becoming a stored blue-green trace, then reappearing from the player's chosen release origin.

Keep the room and every pursuer visible. No camera travel, decorative dashboard, fantasy parchment, neon glow, grain, ornamental border system, splash screen, or card-like ability inventory. The ordinary person is a simple round pawn, not an armored hero. One sentence supplies the story: “They want the artifact back. Reach the exit.” The exact escape requirement immediately follows, supplied by the model.

### Visual tokens and primitives

| Role | Starting value | Treatment |
| --- | --- | --- |
| Window ground | `#DCE3DA` | Flat mineral green |
| Floor / control surface | `#F2F4EC` | Quiet light surface, no shadow |
| Primary ink | `#202E2B` | Text, player, enemy outlines |
| Secondary ink | `#4A5D56` | Supporting labels; never use faint text for rules |
| Grid | `#BAC6B9` | Thin cell separators, no text on this color |
| Wall | `#63756B` | Solid inset rectangle with dark edge |
| Enemy intention / danger | `#A83B2A` | Dashed route, hatch in affected cells, arrowhead |
| Borrowed / selected action | `#00675F` | Solid route, outlined affected cells, source marker |
| Exit | `#7A5D00` | Double doorway outline and `EXIT` label |
| Keyboard focus | Primary ink | Strong outside rectangular outline, distinct from selection |

These are initial implementation tokens, not a claim of measured contrast. Keep all essential text on opaque light surfaces. Confirm contrast and grayscale readability in the later review. Restrict translucent fills to board overlays; pair every color with shape, pattern, text, or line style.

Use Godot's built-in default font throughout, differentiated by size and spacing rather than downloaded faces or invented font availability. Title 28 px; section and action labels 18 px; body and event log 16 px; small coordinates and metadata 14 px. At compact sizes preserve body size, reduce gaps first. Sentence case, short labels, no tiny tracked uppercase text except board identifiers. Use native Label/Button/CheckButton/ScrollContainer controls and simple StyleBoxFlat treatments. Node2D drawing handles the grid, lines, rings, arrowheads, and pawn shapes. No asset files are required.

Player: filled circle with a small hollow diamond beside it for the artifact. Enemy: square body with a readable stable identifier such as `E1`; intention source repeats that identifier. Exit: doorway. Blocker: solid inset rectangle. Health is an explicit model-provided number, not unlabeled pips. Defeated entities do not remain visually indistinguishable from active threats.

## One-screen composition

Open directly into a ready encounter. Do not require a menu or tutorial dismissal before selecting a variant.

- **Top line:** Borrowed Turns at left; objective and health centrally; turn number and phase at right. A quiet `Restart` button is always available. Keep the experiment identity in documentation, not as the game title.
- **Variant strip:** Six equally weighted buttons, `V1` through `V6`, all visible and individually selectable, followed by `Invert preview` configuration. Active variant has a filled ink tab and explicit selected state, not merely a different hue. Below/within the strip show its neutral short rule name. No recommended badge, winner, unlock lock, or ranked ordering.
- **Main left, approximately 70%:** Board, centered in a square allocation, with coordinates along its edges. Immediately below: action toolbar, current targeting instruction, consequence summary, `Confirm` and `Cancel`. No vital instruction belongs solely in a tooltip.
- **Main right, approximately 30%:** A stable vertical rail: current bargain summary; one flat `Stored action` region; compact enemy intention list; `Recent events`. Flat sections and spacing separate these regions, not a pile of rounded cards.
- **Persistent help:** One small line near the controls: `Tab: controls · Arrows: board cursor · Enter: select / confirm · Esc: cancel`. A `Controls` button reveals the full bindings without advancing play.

Implementation clarification: the lower rail uses native `Recent events` and `Preview` tabs. A complete legal selection opens the exact ordered Preview; committed history stays one tab away and becomes active again after confirmation/cancel. This avoids hiding the preview below long rule/slot text. The upper rail can scroll at compact sizes; the tactical board always displays all current threat cells. The shared production fixture is a small GDScript content dictionary so integer coordinates retain the model's required types.

At 1280 × 800 use 20 px outer margins, 12 px region gaps, a roughly 360 px right rail, a 52 px top line and a 44 px variant strip. Let the remaining height go to the play area. Reserve roughly 110 px below the board for actions and preview, rather than overlaying controls on cells. Main labels may wrap to two lines without displacing the board offscreen.

Support a minimum 1024 × 720 window: right rail approximately 300–324 px; shrink gaps and board allocation, not font sizes. Fit all board cells into the available square using the actual model dimensions; never crop or scroll the tactical board. Target cells of at least 36 logical px at the minimum window. If the agreed board cannot fit that budget, resolve the encounter/layout mismatch before shipping rather than quietly reducing it to unreadable cells. At 1600 × 900 or wider, enlarge the board up to 64 px cells and use the remaining space as margins; do not stretch rectangular cells. No phone/portrait layout is promised.

Use Control containers/anchors for the shell and a board drawing rectangle with a single coordinate transform for both rendering and hit testing. Logical UI sizing must follow the chosen Godot stretch configuration; the implementation owner verifies that configuration rather than assuming a web-style breakpoint system. Enforce the minimum window size and test resize and high-DPI behavior.

## Information that stays visible

1. **Objective:** The actual escape condition and its current progress. Do not substitute “defeat all enemies.”
2. **Phase:** `Your action`, `Free capture available` where applicable, `Resolving`, or the terminal outcome. Distinguish a free operation from an action that advances time. After V5 capture say `Capture complete · Your action remains`; releasing the newly captured plan is still unavailable until a later turn.
3. **Threats:** Every active enemy's announced occurrence, affected cells, source, direction, and model-defined timing/order. On overlap, show a count plus the participating source IDs in the inspection text. Do not merge overlapping attacks into one anonymous danger patch.
4. **Stored action:** `Empty` or its action name, source ID, geometry/effect, active constraint, and readiness. Display `Release` and `Discard` consequences beside their controls. This is a single instrument readout, not a hand of cards.
5. **Selection:** Persistent selected pawn/cell/intent outline. Hover is transient inspection and never replaces committed selection. The right rail and board cross-highlight the same source occurrence.
6. **Recent events:** At least the newest four readable lines, grouped by turn, with scroll access to retained earlier events. The gameplay log is visible regardless of whether optional research telemetry is enabled; it is not consent to upload or persist analytics.

## Input and transaction rules

Default interaction is **choose action → choose target → inspect → Confirm**. No hovering, inspection click, shortcut, invalid click, or canceled selection advances the simulation. A single target click prepares a preview, never immediately commits a turn. Buttons include their action names, not icons alone. `Confirm` says what it will do, for example `Confirm capture`, and is enabled only for a complete legal transaction. Target/phase changes invalidate stale previews.

| Operation | Interaction and required feedback |
| --- | --- |
| Inspect | Hover a cell/enemy or focus it with the board cursor. Show coordinates, occupant, associated intentions and affected cells. Click selects persistently. Selecting a rail intention does the same thing. |
| Move | `Move` or `M`, then choose a legal destination. Highlight legal destinations and the model-provided path. Show the resulting position and known remaining threats before confirmation. No UI-authored path legality. |
| Capture | `Capture` or `C`, then select a capturable occurrence via its source or intention row. Show which exact attack will be canceled, capture cost, and threats left active. If a source has multiple occurrences, require the row/occurrence choice rather than guessing. |
| Release | `Release` or `L`, then choose the model-defined target/direction. Preserve the action's geometry. Preview origin, affected cells, targets, movement endpoints, and consequences exposed by the model. Illegal targets retain the selection with a concrete reason and no turn cost. |
| Wait | `Wait` uses the same preview/confirm pattern. The contract defines move, wait, capture, release and discard only. Do not add a basic attack, diagonal movement, or separate end-turn action. |
| Discard | If defined, label the immediate cost and any backlash before confirming. Especially in V5, never use an unqualified trash icon or imply discarding is harmless. |
| Cancel | Visible `Cancel`, Esc, or right click cancels targeting only. Retain the underlying game state and restore the idle instruction. No undo of an already committed action is implied. |
| Restart | `Restart` or Ctrl+R restores the same variant, fixture/seed, and preview configuration. During an unfinished changed run, require `Restart this encounter?` / `Keep playing`; canceled selection alone is not a changed run. |

Keyboard: Tab/Shift+Tab traverses controls with visible focus; native activation uses Space/Enter. Enter board focus through a focusable board control; arrow keys move a visible inspection cursor one cell and never execute movement. Enter on the board selects the cursor cell. Once selection is complete, focus moves to the confirmation button; the next separate Enter confirms. Ignore key-repeat for confirmation and action shortcuts. Esc backs out one targeting stage, then returns to idle; it never quits or resets. Do not process board shortcuts while a modal or text-focused control consumes input. Mouse and keyboard flows must offer the same choices. Gamepad bindings are out of scope.

Disabled actions remain visible with an adjacent status reason, such as `Slot occupied`, `No stored action`, or `Resolving`. If native disabled controls cannot receive keyboard focus, repeat the reason in the stored-action/status text so keyboard users can discover it. An out-of-board click does nothing; a blocked/illegal cell gives a short explanation without clearing the player's mode.

## Variant-specific presentation, not new mechanics

Use neutral rule labels and identical visual prominence. Keep enjoyment hypotheses, predicted winners, and diagnostic policy advice out of the play surface. These are interface labels for the finalized provisional bargains; preserve V1–V6 IDs when their wording differs from the original proposal titles. Every variant must explain that a captured plan can only be released on a later turn.

| Variant / label | Persistent rule summary | Critical targeting/state detail |
| --- | --- | --- |
| V1 · Action cost | `Capture uses your action. One stored plan; no expiry.` | Show occupied-slot prevention and discard's action cost. |
| V2 · Adjacent capture | `Capture beside the source, with an optional one-cell approach.` | Select source first, then one of the model's legal approach endpoints, including stay if allowed. Preview the step and captured occurrence together; commit atomically. Esc returns to source selection without moving. |
| V3 · Two-action expiry | `Release within two later actions or lose the plan.` | Use model-provided `2 actions left` / `1 action left`, plus `Release now avoids expiry` at the boundary. Show what a proposed non-release will consume. No wall-clock timer or ambiguous “turns left.” |
| V4 · Source linked | `The stored plan is lost if its source dies.` | Link the stored readout to source ID and its board outline. Distinguish an attack already captured from that enemy's newly announced attack. Source-loss event must name the reason. |
| V5 · Delayed backlash | `Capture is free once per turn. Release by the second action after capture or take 1 damage.` | The ordinary action on the capture turn counts as the first action; show that explicitly. Show whether free capture remains available and what action remains afterward. Both bolt and shove backlash deal 1 direct damage without displacement. Discard triggers that damage immediately; preview it. |
| V6 · Fixed target | `Choose the release cell when you capture. It stays fixed.` | Capture selection includes target-cell commitment before confirmation, as one atomic transaction. Draw a persistent marker labeled with its coordinate. Later release uses that cell, never tracks an actor or offers silent retargeting. Show why a commitment is currently invalid and retain move/discard recovery. |

Variant switching is always reachable, not gated by completion. Clicking a different variant shows its rule summary and `Start Vn` confirmation only when an unfinished changed encounter would be replaced. Otherwise switch directly to that variant's initial fixture. Do not advance automatically to the next variant, impose a recommended play order, preserve a stolen action across variants, or imply completion unlocked the others. Keep stable V1–V6 IDs in the UI and event context.

### Optional Invert preview

`Invert preview` is an encounter configuration, off initially and directly available for every variant. Changing it restarts the same initial fixture under the shared capability, with the same replacement confirmation policy as variant switching. Display `Invert preview: on` throughout the encounter so base and advanced trials cannot be mistaken for each other.

For a compatible held shove, expose a two-state `Push` / `Pull` control beside the release preview, with normal behavior selected initially. Changing it previews only; the confirmed release carries `invert: true` for pull. Both forms still deal the same damage. Show old and proposed endpoints with labeled arrows. For bolt show `Invert unavailable: this plan is not push/pull`. Do not invent an inverse for damage. In V6 this control changes displacement only, never the committed target cell. No progression tree, unlock animation, or grind.

## Resolution, history, and endings

Keep telegraphs readable at rest. On confirmation, lock gameplay submission while the model resolves; show `Resolving`, preserve the chosen action summary, then present the ordered result and fresh intentions. A short 120–180 ms ownership/route accent is enough for capture and release. Avoid camera shake, flashes, damage-number storms, or mandatory long playback. Animation is presentation only: no timer advances the game, and no effect callback determines correctness. Restart remains usable and cancels stale presentation callbacks.

Use model-provided resolution order. If effects are simultaneous, say so rather than fabricating sequential priority. Record readable lines such as `E2's push captured; E1's attack remains`, with actual IDs and effects supplied by events. State inspection and the event log must explain canceled attacks, damage, displacement, expiry, source loss, and backlash. Do not infer those events by comparing only final pawn positions. Present deterministic model facts as facts; if a preview cannot expose a later consequence, label that limitation rather than promise safety.

Recent events scroll vertically and wrap. Do not truncate the event's cause or conceal it in a hover tooltip. Auto-follow only while the user is at the newest entries; otherwise show `New events` to return to the end. Restart clears the current encounter's display history and adds its start/variant/configuration line. Retention beyond the current encounter follows the separately agreed telemetry policy, not this UI brief.

On terminal state, freeze gameplay inputs and leave the final board, active rule, stored action, and history inspectable. Place a compact outcome strip above the action toolbar, not a full-screen obscuring victory panel: `Escaped` or the rules owner's failure label, followed by the concrete cause. Offer `Replay this variant` and retain all six variant buttons. No automatic restart, confetti, forced survey, completion-as-enjoyment metric, or assumed unlock reward. Recovery after failure is one explicit activation; replay of a finished encounter needs no destructive-action dialog.

## Implementation dependencies and handoff

The UI must consume the authoritative model, not reimplement rules. Its required capabilities are readable state and complete telegraphs, legal target assessment with reasons, exact nonmutating previews, atomic commands, explicit stored-plan constraints, ordered events, and isolated restart/configuration. The binding below supplies these capabilities without demanding redundant model fields. There is no random seed in the current deterministic contract; replay restores the fixture and configuration.

### Binding to the available model contract

`executable-rules.md` now settles the mechanics listed in the original design discussion. The supplied API is sufficient for atomic commands and exact consequence previews:

- Instantiate `res://model/encounter.gd` as a `RefCounted`; initialize with `configure(fixture, variant, invert_enabled)`. Use `snapshot()` for live state and `reset()` for same-configuration replay. A configuration switch initializes an independent encounter with the same fixture data.
- Assemble only supported command keys: `move` with `to`; `wait`; `capture` with `source`, optional V2 `approach` or required V6 `target`; `release` with `target` and optional `invert`; `discard`. Coordinates are `[x,y]`, increasing right/down. V6 release may omit target or repeat its exact commitment.
- Call `assess(command)` during selection. It returns `legal`, a human-readable `reason`, and the exact predicted post-command `preview` snapshot, including ordered events. Render actual release/enemy ray cells from those events, damage and final ghost positions from the preview, and costs/terminal outcomes from the returned state. The preview includes enemy resolution and end-of-turn effects, not just the selected action. Never call `act` to build a preview or write a second simulation.
- On explicit confirmation call `act(command)` once, then refresh `snapshot()`. Append its `events` once to the UI's current-encounter history, including V5's separate free-capture event batch. Do not replace history with the latest batch, append assess results, or append again on each redraw. Use a UI-owned encounter generation/selection token to invalidate stale previews and delayed presentation after restart; this is presentation state, not a new model revision requirement.
- `status` is `playing`, `won`, or `lost`. The UI owns the temporary `Resolving` presentation lock, not a new simulation phase. Display health and objective from `player` and `exit`. A terminal cause can be explained by its ordered damage/backlash/outcome events; do not require a nonexistent outcome-message field.
- In this contract each enemy has one fixed announced action per turn. A UI selection identity can use `(turn, source ID)`; no new occurrence ID field is required. `cancelled` contains sources canceled this turn. Capture affects only that occurrence. Check legal availability through `assess`, not UI distance calculations.
- The production fixture is currently 7 × 7 with two stationary enemies, player 4 HP, and an exit opening on turn 4. Read all of this from fixture/snapshot data; layout and help must not hardcode it as permanent content. Enemy IDs `a` and `b` can display as `A` and `B` while commands retain exact IDs. Stored state provides `kind`, `source`, `captured_turn`, `actions_elapsed` and a V6 target cell. Deadline wording may format these documented fields, while `assess` remains authoritative for legality and actual consequences.
- Capture-turn release is illegal in every variant. In V5 the capture-turn ordinary action consumes the first lifetime action. V4 release consumes storage before its damage, so releasing against the source can succeed. Escape can end the encounter before enemy attacks or deadline effects; the preview, not a generic warning banner, determines that result.

The announcement-footprint dependency is resolved by `snapshot.intentions`: an array of `{source: String, kind: String, cells: Array[[int,int]]}` in fixture order. Draw these complete current telegraphs directly, independent of lethal preview outcomes. They include every alive, noncancelled current announcement, are empty on terminal states, remove only the captured source after V5 free capture, and restore fresh announcements on the next turn/reset. Use intentions for current threats and `ray` events for actual predicted/committed resolution. Never derive the complete threat map from `assess(wait)`, which may stop on player death, or duplicate ray geometry in the UI.

For release effects, a ray event whose `actor` field is the string `player` distinguishes the borrowed ray from enemy rays. Distinguish selected-command preview from new intentions in the resulting snapshot. Displayed post-command ghosts must not replace the authoritative current board until confirmation. These notes describe capabilities, not a separate task backlog.

## Assigned later read-only UI/runtime checks

These checks are a handoff specification, not results. No game runtime or screenshot validation was performed for this planning-only artifact. The later tester should report commands, build identity, input method, viewport, observed result, screenshots, and skips. Use controlled states supplied by the rules lane, not solver predictions of enjoyment. The independent oracle owns correctness and engineering review separately.

| Check | Required observations |
| --- | --- |
| Startup / variants | Open directly to a usable board. Select and start every V1–V6 independently without completing another. Correct rule label and initial fixture/configuration, no stale slot or selection. |
| Viewports | Capture 1280 × 800, 1024 × 720, and 1600 × 900; resize between them and check a nonmatching aspect such as 1280 × 720. All threats, objective, controls, rule summary and newest log lines remain visible; board stays square and hit testing matches drawn cells. Note high-DPI coverage or an explicit skip. |
| Input parity | Complete one encounter interaction sequence with mouse and another using keyboard only. Inspect, select, preview, cancel each stage, confirm, inspect history and restart. Verify focus, separate Enter presses, no key-repeat double turn, no modal click-through and no accidental arrow-key movement action. |
| Invalid / overlapping | Click blocked and out-of-board cells, unavailable actions and overlapping intentions. No simulation advance; clear reasons; exact occurrence can be selected. Long reasons and event lines wrap without covering controls. |
| Variant edges | V2 approach cancel/confirm; V3 final expiry boundary; V4 source loss; V5 free capture followed by an ordinary action, final release and discard/backlash; V6 commitment and later invalid release recovery. Verify presentation agrees with the supplied model cases, without independently inventing rules. |
| Invert | Enable it in each variant without an unlock requirement, select a compatible plan, compare push/pull direction and endpoints, cancel and confirm. Inspect incompatible-action explanation and V6 contract behavior. Configuration remains identifiable. |
| Resolution / reset | Multiple remaining enemy attacks, expiry/backlash and displaced entities remain explainable in board and log. Attempt repeated input during resolution; only one action commits. Restart while presentation runs; no old callbacks alter the new encounter. |
| Win / failure / history | Reach both terminal states using supplied fixtures or recorded legal sequences. Final board/history remains inspectable; replay and variant switch work. Scrolling older events is not interrupted by new entries; `New events` returns to latest. No softlock after canceling a restart dialog. |
| Legibility | Check at native scale and grayscale. Player/enemy/exit, enemy versus borrowed effects, overlaps, selection and keyboard focus remain distinguishable without color alone. Assess essential text contrast against its actual opaque surface. |

The tester reports defects rather than editing production files. Missing fixtures, GUI access, high-DPI support, or model preview support are named limitations, not implied passes. No dependency installation or new asset work follows from this matrix.
