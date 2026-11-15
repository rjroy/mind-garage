---
title: "Borrowed Turns revision 02: interface brief"
date: 2026-11-15
status: draft
tags: [game-design, experiment, interface, design-revision]
related: [.lore/work/experiments/001-hook-discovery/design-revision-02.md, .lore/work/experiments/001-hook-discovery/interface-brief.md, .lore/work/experiments/001-hook-discovery/revision-02-executable-rules.md]
---

# Borrowed Turns revision 02: interface brief

## Authority and boundary

This specifies the authorized revision's interface, not production code or executable rules. Ronald supplied the revised shared rules and rejected a capture cap; the AI supplies the interface interpretation below. The rules owner's forthcoming `revision-02-executable-rules.md` fixes remaining mechanical details. No enjoyment, balance, runtime, or accessibility result is asserted for this revision.

Preserve the first build at `fd8e91d`, its archive, original brief and evidence. The current game becomes **one coherent revised baseline**, not six new variants and not a selectable old-rules mode. Remove V1–V6 controls, their bargain descriptions, discard, once-per-turn capture messaging, fixed-target commitment, later-turn-only release, and action-count expiry. Do not conceal obsolete controls behind a legacy menu. The internal `R2` model identifier is provenance, not a player-facing variant choice.

Reuse the current Control shell, native font, floor-plan palette, square grid, source identifiers, selection/confirmation flow, right-rail tabs, event history and restart protection. This remains Borrowed Turns, not Mind Garage. No new art direction, asset production, dependency, telemetry, persistence, progression tree, or tuning editor follows from this brief. This invocation writes only this specification; implementation waits for the finalized model contract and the parent's assignment.

Implementation clarification: the subsequent authorized implementation replaces the old working UI in place. The exact deadline occupies the budget line outside the scrolling rail, while the rail starts with Stored ability. Full prediction refresh is shared by source/target changes. The provisional production room is 7 × 7 with three adjacent, differently equipped sources, two walls, 6 player HP, 2 AP, 1 MP and capture reach 1; these are bounded content assumptions, not playtest findings. Focused UI smoke uses separate controlled fixtures, including the four-MP example. Native Control/SubViewport captures do not establish physical input, compositor resize or HiDPI acceptance.

**Current removal:** Ronald directed that Invert not be part of the core game. This supersedes this brief's earlier optional-preview choice; any future exploration is separate, not an active control or launch mode. Preserve the general BT-COR-001 preview-synchronization lesson.

## Player-facing explanation

The opening remains immediately playable. Keep the story sentence and escape objective. Replace the old variant strip with the short shared rule:

**“Move and act in any order. Capture is free. Replace a held ability or keep it too long, and it discharges where you stand.”**

Show capture reach from configuration, initially 1, rather than embedding a permanent value in the rule. State that a newly captured ability can be released **this turn**. Do not describe backlash as a generic penalty, automatic bad choice, harmless disposal, or a second release button. Its actual ability and footprint are the bargain. Distinguish free repeated capture from repeatedly taking the same announcement: only the model decides which occurrences remain legal.

## Layout and information priority

Keep 1280 × 800 as the primary layout, 1024 × 720 minimum and 1600 × 900 as the large check. Preserve 16 px body text, 14 px supporting labels, current colors and redundant shapes/line patterns. All current threats remain visible on the board; the board never pans or scrolls. Long explanatory text can scroll in the upper rail. Do not solve overflow by shrinking essential text.

- **Top line:** title; health and exit objective; `Turn N`; `Restart`. Win/failure retains the final board and offers `Replay encounter`.
- **Budget line replacing the chooser:** explicit `AP 2 / 2` and `MP 1 / 1`, using actual current/configured maximum values. Expand abbreviations once in the adjacent help: `Action points · Movement points`. Include `Capture: free · Reach 1` with the actual configured reach. Numeric text is authoritative; optional filled/empty marks are supplementary, not required.
- **Board and action controls:** retain the dominant left region. Toolbar order: `Move · M`, `Capture · C`, `Release · L`, then a separated `End turn · E`. No discard, old wait action, combined move-and-capture command, or default basic attack. Under it retain instruction, compact consequence summary, named Confirm, and Cancel.
- **Stored ability:** the first upper-rail section, rather than placing a long rules paragraph ahead of it. Show ability name/kind, source ID, release range and geometry, effect strength, deadline and a short backlash description. Keep the exact deadline and selected-command warning visible near the confirmation area even if the upper rail scrolls.
- **Enemy intentions:** show source ID, materially identifiable ability and concise effect/shape summary. Selecting a row cross-highlights its board source and model-owned footprint. Line attacks, displacement and area attacks must not all read as anonymous “3 cells” entries.
- **Lower rail:** retain `Recent events` and `Preview`. A complete legal selection opens exact ordered Preview; committed events remain one tab away. Target cancellation returns to recent history. Scroll preserves access to complete causes and consequences.
- **Help and configuration:** use the freed chooser space or existing help line for a brief rule explanation and Controls. Preserve the clean-restart confirmation policy, not an unlock ceremony.

AP and MP are independent, not a pair of alternate costs. A confirmed move changes MP according to the model; release changes AP; capture costs neither, including replacement. Do not disable Capture merely because the slot is occupied or AP/MP are zero. Availability follows legal commands, including replacement. Do not display a capture-use counter or imply that two captures exhaust a budget.

## Explicit player-ended turns

Never auto-end after a move, release, capture, resource exhaustion, animation, idle time or click outside the board. Exhausting one pool does not exhaust the other. Even at `AP 0 · MP 0`, free capture may remain legal; say **“No AP or MP left. Capture is still free; End turn when ready.”** Do not gray every control or silently advance enemies.

Selecting `End turn` or pressing E prepares the real model's `end_turn` command and its exact prediction. It does not immediately execute it. The confirmation label is `Confirm end turn`. The summary states unspent budgets, any due stored-ability backlash, enemy consequences and predicted terminal/next-turn state. Spending remaining points first is optional; a second modal warning is unnecessary because this is already an explicit preview/confirm transaction.

Do not carry the original “every ordinary action resolves enemies and advances the turn” assumption into summaries or animation. Show `After move`, `After capture`, `After release` or `After end turn` with predicted AP, MP, health, position, turn and storage as appropriate. Only the finalized model defines resolution boundaries. Enemy execution and budget refresh shown for End turn must match its returned ordered events.

## Input and preview transactions

Preserve **choose operation → choose source/target if needed → inspect → Confirm**. Mouse inspection, selection, legal-candidate enumeration, preview, shortcuts and cancellation never mutate the model. Reassess immediately before committing once. Invalid commands retain the useful selection and show the model's reason; they never spend points, discharge storage or consume an announcement.

Move uses the model's defined movement command. Initially present single-cell destinations if that is its contract; repeated confirmed moves can interleave with capture/release. Do not add UI pathfinding, multi-step movement, reserved movement or an atomic approach operation without model support. The human's four-MP example must be possible with an appropriate test-owned fixture, not forced into the production starting budget.

Capture always selects an announced source, whether the slot is empty or occupied. Release chooses the captured ability's legal target/direction using its own range and shape, not the old universal three-cell ray. Same-turn capture/release is permitted when assessment allows it. Selected sources, canceled occurrences, live intentions, stored abilities and target candidates refresh after every confirmed command without assuming the turn changed.

Keyboard retains Tab/Shift+Tab, native Space/Enter activation, M/C/L, board-focused arrows, separate Enter for selection and confirmation, Esc/right click cancellation, and Ctrl+R restart. Add E for End turn, which previews rather than commits. Keep End turn separate from native focus navigation and ignore key-repeat submission. Modal/help input remains isolated. No gamepad promise is added.

### BT-COR-001: all prediction views stay synchronized

Use one current command and one authoritative `assess` result for every preview surface: point-cost summary, health/position/outcome, stored-slot result, board footprints, displacement/death markers, exact ordered event text, warning and Confirm enabled state. Target, source, mode, restart or live-state change refreshes or clears them together. Never retain a previous source or target's effects. A legal assessment can predict failure; do not misrepresent that as an invalid command or disable an intentional legal risk.

## Replacement and actual ability backlash

An occupied slot changes the instruction to **“Capture replaces [held ability]. Inspect its discharge before confirming.”** It does not hide Capture, add Discard or auto-release the old ability toward the new source. The model validates the pre-state, discharges the held ability at the player's position, resolves survival/source changes, and reports whether acquisition succeeds.

For a replacement preview show these distinct stages in the ordered Preview tab, with actual actor IDs, damage, displacement and resulting HP:

1. **Held discharge:** old ability name, player-centered footprint and all self/enemy effects. The live player remains the center marker; a forecast is not a committed explosion.
2. **Survival and source result:** player death, or any selected-source death/displacement/reach change produced by the discharge.
3. **Acquisition:** the new held ability and deadline if acquired, or explicit `capture_failed` wording with the model's reason and the predicted empty slot. No optimistic acquired badge when the discharge prevents acquisition.

The compact summary beside Confirm must include the material result, not just “free”: for example `Free capture replacement · You lose 2 HP · A loses 2 HP · New ability acquired`, or `Backlash kills B · New capture fails · Slot ends empty`. These are copy patterns, not invented numerical predictions. On legal lethal replacement say `This discharge kills you. No new ability is acquired.` Keep confirmation available for that legal choice; normal preview/confirm is the safeguard, not an additional modal or UI veto.

Draw backlash footprints from the model, not from UI radius/range math. Keep rust for danger, but distinguish **backlash** with an extra outer boundary and the label `Backlash here`; ordinary enemy plans retain dashed routes and source IDs. Use the held ability's recognizable line/area/displacement presentation and show self-hit, enemy hits and actor endpoints/death separately. Teal remains the borrowed release/selection layer. Where footprints overlap, inspection names the stage and sources instead of merging them into an anonymous patch.

The stored readout states the actual backlash effect, shape and strength. A stronger area ability must visibly carry its larger footprint/effect, not reuse the old `1 direct damage; no displacement` formatter. Distinguish at least the finalized fixture's ray, displacement and area abilities through names, short effect summaries and real footprints. Do not create extra abilities or tune damage merely to produce impressive UI. The content/rules owners supply materially different abilities, including AOE.

## Deadline measured at turn end

The provisional timing supplied by the rules lane is: capture during turn T permits release for the rest of T and the full following player turn T+1; ending T+1 discharges the held ability before enemy resolution. The release action count is irrelevant. Finalize wording against `deadline_turn`, not a local action counter.

- Always show **`Release before ending turn N`**, using the stored deadline. This is less ambiguous than “two turns left.”
- On the deadline turn, use **`Backlash when you End turn`** near the stored readout and End-turn confirmation, with the actual ability name. AP/MP movement and release previews remain available as the model allows.
- Ending capture turn T does not imply expiry. Ending deadline turn T+1 previews discharge and subsequent enemies in exact order; deaths can stop that sequence.
- Moving changes where an eventual self-centered discharge would occur, not its turn deadline. Releasing/replacing refreshes storage/deadline only as returned by the model. The UI never independently ages a stored ability.

Intentional expiry can be useful. Label its effects neutrally and display enemies damaged/killed alongside the player's risk. Never call it a misplay, automatically prevent End turn or silently release the stored ability to save the player.

## Model binding and concrete dependencies

The API is `configure(fixture, "R2")`, `snapshot()`, `assess(command)`, `act(command)` and `reset()`. No UI variant parameter or parallel mechanics implementation is needed. Exact command schemas and event names come from the executable specification, subject to the current removal above; do not assume old V2/V6 or Invert fields remain legal.

Required data/capabilities, using the names already supplied where available:

- **Budgets/configuration:** snapshot `action_points`, `movement_points` and `rules`, including maximum budgets and capture reach under the finalized field names. Fixture rules initialize these values; snapshot rules supply the display's authoritative configuration. Do not hardcode 2/1 or 2/4 or calculate current availability from remaining points alone.
- **Ability description:** stable kind/name and actual `range`, `damage`, `radius`, `push` or the finalized equivalent. Enemy direction and explicit model-owned footprints explain what the ability does. UI label formatting may name fields; it may not derive target legality, AOE cells, ray length, damage, displacement or backlash equivalence.
- **Stored state:** complete captured ability, source identity, `captured_turn`, `deadline_turn`. Acquisition/failure events and the predicted stored snapshot must distinguish replacement success, discharge-with-no-acquisition and terminal failure.
- **Current intentions:** complete alive/noncancelled announced occurrences with source, ability identity and affected cells, even if an earlier effect would kill the player. Rendering must support area cells without drawing a misleading ray through them. A model-provided shape/kind mapping must identify directional versus area presentation.
- **Assessment:** exact post-command snapshot and ordered events for movement, free capture/replacement, release and `end_turn`, with legality and concrete rejection reason. The UI may enumerate candidates and assess them, including commands whose legal outcome is lethal or `capture_failed`. It must never simulate backlash or roll back a successful discharge locally.
- **Stage-labeled effect geometry:** use the finalized event types and documented ordering to distinguish enemy execution, borrowed release and held backlash. The supplied assessment exposes the full discharge footprint before damage, then ordered acquisition/`capture_failed`/loss as applicable. Existing markers/order can supply display stage labels; no separate phase-label API is requested. Preserve damage, displacement, death, slot loss, deadline, turn and budget refresh facts as actually emitted. Do not infer acquisition from a source click or rewrite a failure as a rejected command.
- **Backlash-at-current-position inspection, resolved:** `snapshot.backlash_footprint` is empty `{}` or `{type: "ray" | "area", cells: [...]}`. It supplies full current-player-centered geometry even before the deadline or when discharge would be lethal. Render its explicit type/cells for the stored readout's `Backlash here` overlay; do not obtain this from an early `assess(end_turn)` that does not yet discharge storage. Exact command consequences still come from assessment, not the inspection overlay. No UI geometry helper, extra preview simulation or new query is needed.
- **Isolation:** reset restores fixture/budgets/deadlines/announcements/configuration and clears selection, prediction and current-run history. Presentation generation tokens continue to cancel stale callbacks. History appends events once per confirmed command, including repeated free captures within the same turn; redraws and assessments never append history.

The supplied replacement semantics settle a crucial case: if the player survives but the selected new source dies or leaves capture reach during discharge, the command succeeds with `capture_failed` and empty storage. Its effects are not rolled back. Assessment and ordered events supply this preview, including legal lethal replacements. The held-footprint and maximum-budget presentation gaps are resolved by the supplied snapshot fields. Bind ability target semantics, announcement identity/recapture legality and command/event keys to the executable specification and current removal above; do not invent them in the UI. No additional player interview or phase-label extension is requested.

Utility unlocks such as more MP or capture reach are **future possibilities**, not built features. Do not show disabled upgrade slots, prices, a progression tree, earned unlock language or unsupported controls.

## Bounded validation handoff, not results

The UI implementer adds focused checks after the model contract is finalized. The separate read-only tester supplies runtime results/screenshots; the oracle independently reviews correctness and engineering quality. No tests or runtime checks run in this specification-only invocation. Preserve old evidence and regression intent without running the new baseline against obsolete V1–V6 expectations.

| Focused case | Required UI evidence |
| --- | --- |
| Baseline startup | One coherent encounter, no chooser/legacy mode/discard/wait, Invert control or obsolete rule text. AP/MP/capture reach derive from the fixture. |
| Budget interleaving | A controlled 2-AP/4-MP fixture supports move 2, capture, move 1, release, move 1, ending with 1 AP and 0 MP. Every step uses real UI selection/confirmation and model commands. Use actual starting-budget content separately, not a permanent 4-MP requirement. |
| Zero budgets / End turn | Exhaust either pool independently, then both. Verify no automatic turn ending; legal free capture remains reachable. End turn previews unspent budgets and exact boundary effects; Cancel changes nothing; Confirm advances exactly once. |
| Repeated capture / replacement | More than two legal captures in one turn are not blocked by UI caps. Preview self/enemy effects, successful acquisition, source-death/out-of-reach `capture_failed`, and player-death/no-acquisition. Confirm matches the preview; invalid capture has no discharge or partial mutation. |
| Ability diversity | Inspect and release each finalized ability kind, including AOE and displacement. Range, shape and effects reflect the held ability. No universal three-cell ray, generic backlash formatter or misleading area arrow. |
| Turn deadline | Capture-turn End turn remains safe from expiry; arbitrary legal commands do not decrement an action clock. On the following deadline turn, release is available before End turn; End turn previews/commits actual discharge before enemies. Moving updates the backlash center, not its deadline. |
| BT-COR-001 | Change source and target selection. Compare command, summary, board, health/storage results and complete Preview text with the current assessment. Repeat after invalid target, cancel and reset; no stale effects remain. |
| Input / recovery | Mouse and keyboard-only flows select Move/Capture/Release/End turn, inspect, confirm separately and cancel. Arrow keys inspect, E only prepares End turn, repeats do not double-submit, dialogs do not leak input. Restart during presentation clears callbacks/state/history. Win/failure preserves board/history and replay. |

Capture a bounded set of actual renders: startup at 1024 × 720, 1280 × 800 and 1600 × 900; one same-turn capture/release preview with AP/MP visible; one area replacement showing self and enemy consequences; one `capture_failed` result; one deadline End-turn preview; one lethal outcome; and one normal shove preview. Use minimum-size captures for the longest warning/deadline layout. Verify PNG dimensions, not filenames alone. If explicit-size SubViewports are required because the compositor refuses native resizing, label that limitation instead of calling it native resize acceptance.

Check at native scale that budgets, deadline, Confirm/Cancel/End turn, selected-command warning and current board remain readable without clipped controls or color-only meaning. Scrollable details must not hide the only deadline or acquisition-failure warning. Review all assigned captures together, fix material defects in one bounded batch, and recapture affected states. Record skipped native OS input, resize, HiDPI or unavailable scenario coverage explicitly; injected GUI-event checks are not physical mouse/keyboard evidence. Stop before tuning the encounter or claiming enjoyment from correctness.
