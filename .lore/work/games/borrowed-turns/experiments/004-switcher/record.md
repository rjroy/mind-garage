---
title: "Experiment 004: Switcher opponent"
date: 2026-11-17
status: draft
tags: [game-design, experiment, borrowed-turns, opponents]
related: [.lore/work/games/borrowed-turns/design/borrowed-turns-opponents.md, .lore/work/games/borrowed-turns/experiments/003-active-opponents/record.md]
---

# Experiment 004: Switcher opponent

## Inputs and provenance

- Stable ID: `004-switcher`. Stage: Ronald reports the candidate is fine and defers polish; the next discussion concerns a configurable opponent-component library.
- Game baseline: accepted 7×7 Stage `8275a48`; design/feedback checkpoints `14ee86c` and `3565320`. Existing prototype: `games/borrowed-turns`.
- Human contribution: Ronald requested opponent variety after finding the earlier fight engaging and puzzle-like, accepted the larger board, and selected the recommended Switcher-first direction with “Great. Lets see it.” The shortlist and damaging-swap proposal originated with AI; no originality claim follows.
- Scope: one Switcher, checked alone and then paired with existing B, directly selectable through the current encounter UI. The other five shortlist roles are not authorized builds.
- Audience/constraints: Ronald only, Godot, existing artwork, no dependencies, no telemetry additions, no progression, healing, basic attack, terrain engine or new assets. No screenshots, recordings, editor-driven captures or compositor operations.
- Orchestrator/model: GPT-6.1 Sol, `openai/gpt-6.1-sol`. Implementation and UI specialists execute bounded lanes; independent testing and fresh correctness review are separate. Runtime version will be recorded from independent execution; existing baseline uses Godot 4.7.2 on Linux.
- Input snapshots, SHA-256:
  - Player brief: `5b04af7e2e5bab9d32102143b5144d6b5ea0b773bc12473e412471248da74575`.
  - Experiment brief: `582ecb3de70d4ac8be4874e299147c793e86d9865495c833a41286d9c7a46b0f`.
  - AI/novelty/fun note: `83a6648df5644d85ebb947410d13c881e06ac671f739af16fa2dc5ba6cfe4f67`.
  - Games/fun research note: `e3b32f57b330fdef7d39594e600da835ebb2b12436ec87dcf95e96f2f8483612`.
  - Project mechanic-exploration procedure: `2cd5063a128dbe1b153c85800ea74dade488bfebe0abaf5743e012927372fe9b`.

## Discovery

Fresh hook discovery and external adjacent-game research are not repeated. The existing Capture/Shine bargain remains selected. The bounded opponent promise is a positional exchange that makes both occupied cells consequential and supplies a different borrowed movement tool.

Pure non-damaging exchange was rejected during shortlist reconciliation: under defeat-all, no independent basic attack and source-linked abilities, a final utility-only opponent can become unkillable. A damaging exchange preserves solo completion in principle, still requiring actual checks.

## Comparison plan, before results

- Observation: accepted A/B attacks are both damaging shoves. Ronald wants encounters to pose different puzzles rather than demand replay of one solved room.
- Hypothesis: a damaging exchange creates useful relocation choices and a reason to preserve its source, especially beside B's wide threat.
- Competing explanations: exchanging positions is merely a chore; repeated Shine is automatic; forced relocation makes damage unavoidable; the borrowed tool is confusing or kills its source before becoming useful.
- Prediction: player and target positions both matter to acquisition and Shine. In a paired fight, an exchange can alter exposure to B's already announced attack without secretly retargeting it.
- Counterevidence: unclear damage cells/endpoints, deadlocks or an unfinishable last opponent, hidden retargeting, invalid occupancy, capture occurring before full consequences, or Ronald finding the exchange tedious.
- Preserve: 7×7 Stage, existing standee scale/art/Director/pacing, 3 AP, Move/Capture/Shine each 1 AP, damage-before-acquisition, reusable held ability, source-death clearing, deterministic enemy order and exact assessment/commit.
- Candidate starting assumptions: Switcher HP5, damage1, range2, one-step existing chase movement. These are implementation assumptions, not validated balance.
- Solo isolates acquisition/targeting/finish; Switcher+B exposes interaction. Those are encounter scenarios using one selected rule, not alternative mechanic versions.
- Human comparison is informal sequential play. Ronald knows A/B and the bargain; learning/exposure cannot be reset. No statistical, retention or general-player claim.
- Stop on a rule-level deadlock, unresolved consequential choice, or two failed correction attempts on one finding/three correction rounds. Do not silently add healing or change AP to manufacture success.

### Selected rule interpretation

- `ability.kind = "swap"`. At announcement, lock one board cell: the player's current cell only when cardinal, within range and wall-clear; otherwise no valid swap intention. Publish source/current origin, target and exact hit cells. Only the target cell is a damage region, not the intervening path or source pad.
- The board cell stays locked, not the actor. If empty at resolution, miss; a different living combatant in that same cell can be hit instead. Never follow a moving player. Current source position/range/wall validity still applies; no general frozen-origin framework.
- Resolve **exchange first, then damage the target actor** at its new cell. Both actors change cells atomically. This makes a source-killing Shine complete relocation without moving an already dead actor. Ordinary terminal/source-loss cleanup follows.
- Authoritative effect event: `swap {actor, other, from, to}`, with the other actor travelling from `to` to `from`. It belongs to its resolving enemy attack or Shine, not two fabricated voluntary moves.
- A preceding `mask {actor, kind: "swap", cells, from, target}` publishes the exact threatened cell and intended endpoints, rather than mislabelling it a ray. A geometrically valid empty target still produces its one-cell mask but no exchange/damage; invalid range/wall geometry produces no hit cells. This lets finite miss feedback remain honest without UI targeting guesses.
- Enemy attacks retain normal consequences. Armed Capture acquires only after an actual enemy hit on the player finishes and the player/source survive. Another victim does not consume arming; player Shine cannot acquire itself.
- Player Shine must target an occupied enemy cell, cardinal/in-range/wall-clear; empty, self, off-board, diagonal, blocked and out-of-range commands reject atomically. Intermediate combatants do not become new wall blockers for this teleport.
- Held swap is reusable and loses its source normally. No new capture rule, status system or last-enemy exception.
- Reuse accepted A artwork provisionally with explicit Switcher name/ability; B remains unchanged. No artwork generation is implied.

## Six mechanic alternatives

Not a formal six-version exploration. Ronald selected the specific Switcher-first implementation after a six-role opponent shortlist and a recommendation to check it alone then paired. This bounded follow-up implements that selected opponent; it does not claim to have compared six swap alternatives or screen unbuilt roles as failures. Reopen mechanic exploration explicitly if that becomes the next question.

## Build and replay manifest

Core/content and UI integration are independently verified and technically reviewed. Encounter IDs are `switcher` and `switcher-b`, independently selectable with clean reset/Replay; solo is the initial entry. Existing A/B and escape encounters remain available as real comparison content, not old rule modes.

This record is included in the local checkpoint with commit subject `mind-garage-ds5: add Switcher solo and paired encounters`. From the repository root:

```sh
godot --path games/borrowed-turns
godot --path games/borrowed-turns -- --encounter=switcher-b
```

Close an older game process first. Default is solo Switcher; use the existing encounter selector for Switcher+B, baseline A+B or escape. M/C/S/E prepare Move/Capture/Shine/End Turn, then Preview/Confirm; Cancel does not commit. Shine with held Swap targets an occupied enemy cell on a clear cardinal line within range 2. Restart/Replay restore the selected fixture without an unlock or save gate. Independent core/route logs identify Godot `4.7.2.stable.arch_linux.ed1daf0bf` on Linux. No seeds, saves, grind or unlock gate are introduced.

Temporary scripts, logs and manifests belong under ignored `.lore/local/verification/switcher/`, not committed evidence or required runtime inputs.

## Sessions and evidence

Ronald has now tried the candidate and reports: “It's fine. I think there's some polish to be made, but I don't know if nows the time.” No enjoyment score, command trace, completion count, desire-to-continue report or voluntary replay measure was collected. Do not infer those outcomes from this qualitative report.

Initial independent focused model RED (`tests/run.gd -- --focus=switcher`) exits 1 with **95 checks, 16 failures**, without setup/script errors. It exposes missing fixed-cell announcements, exchange and ordering. Some Shine rejection checks incorrectly assume the missing initial exchange had succeeded, and one event-order comparison permits a missing-event index of −1; those are test-isolation defects, not independent evidence of missing Shine validation. A test-only repair gates dependent checks on the asserted initial exchange, makes event presence explicit and adds the agreed mask assertions. Independent RED recheck precedes production. The ten-file core boundary remains unchanged during execution; initial evidence is local at `switcher/model-red/`.

The independent repaired RED exits 1 with **81 checks, 16 failures**, now covering missing fixed targets, paired exchange, exact valid/empty/displaced-source masks and non-vacuous ordering without downstream Shine false failures. Borrowed-Swap setup still returns on the missing initial exchange; legal/invalid Shine, repeated activation and source-death branches must be reached in GREEN, not claimed from this run. No setup/script errors occur; the ten-file core boundary is stable. Evidence: `switcher/model-red-recheck/`. Production implementation is released with tests frozen.

Independent core GREEN passes focused Switcher **111/0** and full model **526/0**, both exit 0. Previously masked borrowed-Swap setup, invalid targets, two Shine exchanges and lethal source loss are reached. Valid hit, empty locked cell and displaced-source masks pass; replacement occupant and later-attack ordering pass. The model tests do not separately assert every replacement-occupant or Shine mask field, so those are not independent mask-variant coverage claims. No script/setup errors occur; all twelve scoped model/content/test-fixture files remain unchanged before/after. Model SHA-256: `d8e15e9aed096144a9bb199bc31348a01179f2430638900f98eda18aa60724e4`. Evidence: `switcher/model-green/`.

### Actual-content feasibility and partner interaction

Guided public-API replays complete both unchanged encounters: solo **13 commands, T5, HP7**; pair **30 commands, T9, HP5**. Solo uses one acquisition and five Swap Shines. Pair acquires A, uses five Swap Shines, loses storage when A dies, then acquires B after its actual shove and uses five wide Shines to finish. Every assessment is pure and every commit exactly equals its preview. Source/model/content hashes remain unchanged, with no search, hidden tuning, rejected continuation or failed batch. Diagnostic commands exit 0. This proves one feasible route each, not optimality, unavoidable damage, encounter balance or enjoyment.

For reproducibility without depending on generated logs, use the following sequences. `M` is Move, `S` Shine, `C` arm Capture. End Turn after each row except the winning row.

| Turn | Solo commands |
| --- | --- |
| 1 | M `[1,3]`, M `[2,3]`, C |
| 2 | M `[3,3]` |
| 3 | No command before End; acquire A |
| 4 | S `[3,3]`, S `[4,3]`, S `[3,3]` |
| 5 | S `[4,3]`, S `[3,3]`; victory |

| Turn | Paired commands |
| --- | --- |
| 1 | M `[1,3]`, M `[2,3]`, C |
| 2 | M `[2,2]`, M `[2,1]`, M `[2,0]` |
| 3 | No command before End; acquire A |
| 4 | S `[3,0]`, S `[4,0]`, S `[3,0]` |
| 5 | S `[4,0]`, S `[3,0]` defeats A, C |
| 6 | M `[3,1]`, M `[3,2]`, M `[3,3]`; acquire B at End |
| 7 | S `[3,4]`, M `[3,3]`, S `[3,5]` |
| 8 | S `[3,5]`, M `[3,4]`, S `[3,6]` |
| 9 | S `[3,5]`; victory |

A separate seven-command branch after the paired T3 acquisition checks the promised cross-opponent use, not only damage back at A: T4 move `[4,1]`, `[4,2]`, `[4,3]`, End; T5 move `[3,3]`, Shine B at `[3,5]`, End. Shine exchanges P `[3,3]` with B `[3,5]`, damages B, and leaves A alive as the held source. B's translated upward shove then hits A, damages/pushes it, not the player. After movement P is `[3,5]` HP7, A `[2,0]` HP4 and B `[2,3]` HP4; held Swap remains. B's fresh threat returns, so this is a positional interaction, not permanent safety or evidence of a superior strategy.

Drivers, generated snapshots, exact CLI/exit records and unchanged-hash proofs are local under `switcher/route-investigation/`. Do not coach either winning route before first play unless Ronald requests help.

### Presentation behavioral RED

Independent controlled/scene RED has no setup/script errors: controller **353/15 failures**, rendering **1260/29**, pure presenter **696/16**, warnings **506/5**, Switcher scene **120/18**, board integration **4376/1**, each exit 1. Missing behavior includes mask-owned attack stages, singleton warnings, Swap identity/preview endpoints, shared paired movement and default/chooser access. The board integration's sole failure is default encounter identity; its retained geometry checks pass.

Missing chooser entries mask those profile-selection branches. Separate controlled real-model scenes nevertheless reach solo/pair arm-and-hit, solo repeated Shine/victory and miss/restart, and exact model event order passes. Without a Swap cue, midpoint paired interpolation/depth/foot/body-picking branches remain unexercised, not accepted coverage. Retained G1 cases report no failures. All 92 game files remain unchanged before/after, SHA-256 `9b0eaa3982076b0e362b5b895781d87ab21208116488ef5fadfcbb7fc56cb56e`. Evidence: `switcher/ui-red/`. Production UI work follows with these tests frozen.

The production UI pass changes seven existing scripts, not source art, model/content, tests or projection. It adds solo/pair selector access and explicit Switcher naming; consumes mask endpoints directly for a target-only wash and non-damaging hollow exchange pads; replays both actor positions in one finite attack/Shine cue before impact, acquisition or source-loss; preserves held-state ownership and independent B geometry. New Swap feedback lasts 0.60 seconds on the existing controller, while the existing 1.8-second Director loop and 2.7-second shove waves remain unchanged. Independent post-change checks must reach the formerly masked interpolation/picking and profile paths before any GREEN claim. Author manifests are local at `switcher/author-green/`.

### Independent combined presentation GREEN

All commands use `godot --headless --path games/borrowed-turns --script res://<runner>` with the listed focus:

| Runner | Checks / failures | Exit |
| --- | --- | --- |
| `tests/shadow_presentation_run.gd` | 374 / 0 | 0 |
| `tests/shadow_rendering_run.gd` | 2968 / 0 | 0 |
| `tests/two_pursuer_presentation_run.gd` | 828 / 0 | 0 |
| `tests/board_warning_run.gd` | 506 / 0 | 0 |
| `ui/smoke.gd -- --focus=switcher` | 306 / 0 | 0 |
| `ui/board_comparison_smoke.gd` | 4376 / 0 | 0 |
| `ui/smoke.gd` | 937 / 0 | 0 |

Formerly masked tests now reach shared mid-exchange interpolation, depth, projected feet/marker picking, source-killing Shine and actual solo/pair chooser paths. Singleton/empty misses, exact authoritative masks versus decorative pads, and exchange-before-damage/acquisition pass. No script/setup errors occur. Main-scene startup with `--quit-after 3`, normally and with each of `-- --encounter=switcher-b`, `two-pursuers` and `escape`, exits 0 with the expected Stage profile.

All declared hashes match and the 92-file game before/after manifest is stable, SHA-256 `d008498dd66239cab15b23e67494dee1d16442d6c88a6c0642c85251c5537b1c`. Unchanged core/projection/art results are reused, not claimed as new runs. Evidence: `switcher/ui-green/`. Fresh correctness review follows; no visual or enjoyment acceptance is inferred.

### Correctness correction SW-C01

Fresh correctness review identifies SW-C01: the actual preview drawing loop still dispatches only ray/area events even though the footprint projection includes masks. Swap-only previews omit their target wash; in mask-then-B-ray previews the ray consumes the earlier mask row, misassigning/omitting B's predicted footprint. Existing helper-level checks do not cover this consumer dispatch. A test-only actual inherited Canvas-draw regression must cover Swap-only and mixed previews before the bounded board dispatch fix; no model or targeting change is needed.

Independent actual-draw RED exits 1 with **2999 checks, six failures**: dispatch count and ordered actor/type/stage/cells for Swap-only, mask-then-ray and authentic empty-mask-then-ray previews. All three Canvas cases are reached, real-producer setup commands are legal/exact, and footprint projection, link endpoints, purity, G1 and finite feedback pass. Missing footprint dispatch masks downstream actual tile drawing; do not count that as passed. No script/setup errors occur. Evidence: `switcher/sw-c01-red/`. Production correction is limited to including masks in that existing dispatch/index loop.

The one-line dispatch correction independently passes rendering **2999/0**, full UI **937/0** and board integration **4376/0**, all exit 0. All six former failures and three Canvas preview cases are reached, including an empty A mask preceding B's ray; exact rows/link endpoints pass without an invented source wash. No script/setup errors occur. Only the board changed since RED; the 92-file before/after manifest is stable, SHA-256 `769aed36fc0ab9e4d72ddcaba821063a2211535a4bdc9a134831be2a67484952`. Evidence: `switcher/sw-c01-green/`. Fresh focused correction review follows, with unchanged core/controller/presenter/warnings/startup evidence reused rather than rerun.

A fresh focused read-only correction review closes SW-C01. It inspects actual draw dispatch and regression code, recorded RED/GREEN exits, both supplied file hashes and all 92 current source entries; reversing only the dispatch correction reproduces the prior RED board hash. No further correction-scope defect is reported and no new test execution is claimed. Refactor and engineering-quality assessments remain separate from correctness and human visual acceptance.

The subsequent separate refactor assessment recommends no further change before play. Independent engineering-quality assessment finds the shared model/cleanup, finite exchange timing, event-driven drawing and independently attributable content proportionate to this bounded candidate, with no material findings. It verifies all 92 frozen entries and reads existing GREEN evidence without claiming new execution; frame-time impact remains unmeasured. Ronald then asks how opponent ability, movement, combat model and visuals are abstracted. The read-only explanation distinguishes existing data-selected movement/ability behavior and separate artwork from duplicated encounter definitions, single-ability assignment, kind-derived names and A/B presentation assumptions. He explicitly requests deferring that revisit to `mind-garage-g9s`, committing this candidate and receiving test instructions. No architecture changes are made.

Final handoff: try solo to learn the locked-cell exchange, then Switcher+B to judge positional consequences and whether the borrowed ability offers useful choices. Observe whether the target wash, exchange pads, movement-before-damage and acquisition are understandable. A completed diagnostic route is not a human enjoyment or replay finding. Only documentation/status wording changes after the final verified executable freeze.

Ronald accepts the current candidate as sufficient to move on rather than authorizing polish. He finds one-opponent-at-a-time development laborious and wants a configurable library. Before implementation, he explicitly asks to agree the components: base stats, abilities, movement patterns, standee/puppet references, names and any other necessary parts. This advances `mind-garage-g9s` to component-model discussion, not authorization for a framework or code migration.

Verification budget:

- Controlled model tests: exact target/occupancy/walls/range, locked-cell miss and changed occupant, atomic paired exchange, effect/damage/death/acquisition order, repeatable Shine/source loss, later independent attacks, assessment purity and reset.
- Event-driven UI/controller tests: published hit cells versus exchange pads, both actors' common finite progress and authoritative endpoints, capture anchors/later B origins, held-stage ownership, input lock/generation cancellation, chooser/default/solo/pair/reset and provisional name/source identity.
- Reuse unchanged projection/art checks unless their inputs/algorithms change. Preserve existing shove/area/G1 coverage, rather than replacing the old suite with swap-only checks.
- Independently establish behavioral RED and GREEN; use fresh correctness review, then separate refactor and quality assessment. No full-suite repetition without an affected boundary.
- One bounded actual-content solo and paired feasibility replay with pure assessment/exact commit; no broad search or hidden stat tuning. Mechanical feasibility is not enjoyment.

## Revision log

Initial rule and comparison criteria recorded before results. Technical reconnaissance precedes tests; production stays frozen while the first behavioral tests are authored.

## Findings and next decision

Game outcome: Ronald reports the candidate is fine, with possible polish deferred. No stronger enjoyment or replay conclusion is supported. Method outcome: shortlist reconciliation identified a utility-only last-enemy deadlock risk and preview consumer review found SW-C01. Human feedback now redirects effort from adding roles individually to agreeing a reusable component model.

Next decision: agree the opponent component model under `mind-garage-g9s` before building the library. Further Switcher polish remains unselected.

## Repeatability handoff

Preserve the accepted 7×7 baseline checkpoint and input hashes above. Record final direct launch, runtime version, exact checks and concise replay recipes without depending on local logs. Repeating a requested comparison is not voluntary replay and cannot restore first exposure.

Completed Switcher checkpoint: `mind-garage-ds5`. Current component-model discussion: `mind-garage-g9s`. Run/progression discussion `mind-garage-7am` remains deferred.
