---
title: "Experiment 003: Curtain Call active opponents"
date: 2026-11-16
status: draft
tags: [game-design, experiment, curtain-call, combat]
related: [.lore/work/intents/player-brief.md, .lore/work/experiments/002-shadow-paper/record.md, .lore/work/narrative/borrowed-turns/curtain-call-narrative-brief.md]
---

# Experiment 003: active opponents

## Inputs and provenance

- Experiment ID: `003-active-opponents`. Current stage: candidate implemented, headlessly verified and technically reviewed; awaiting Ronald's fight play.
- Source baseline: `37026b6`, following packaged-resource checkpoint `8587639` and cleanup `144c1a9`. Accepted presentation and 2.7-second telegraph waves are the starting point.
- Input procedures: repository experiment-record template and `implement`/`verification-planning` workflows. This is a revision of the selected capture mechanic, not fresh hook discovery.
- Audience: Ronald only. Godot, existing packaged artwork, no new dependencies or asset generation.
- Human contribution: Ronald supplied the narrative, rejected treating hooks as exhaustive mechanic specifications, and redirected effort from run progression to making one fight fun. A future run should traverse a location with multiple fights and power gains; it is deferred, not reduced to a single-stage run.
- Human-specified intervention: two mobile opponents, chase and maximum-range movement patterns, attacks aimed toward the player, defeat-all default victory, edge-midpoint player start opposite two corner opponents, sliding standee movement, and positional capture restriction.
- Explicit clarification: capture is blocked while the player occupies **any current enemy announced attack footprint**, not merely the chosen source's attack.
- AI-proposed starting assumptions: one cardinal enemy movement step per turn; resolve existing announcements before movement, then aim and announce. Aim direction does not follow player movement during the player turn; displacement of the source still translates its footprint using the existing geometry rules. No frozen-origin attack framework is introduced. Ranged repositioning seeks usable attack range rather than indefinite flight. These are revisable implementation choices, not human-authored permanent rules.
- Runtime/version checks for this revision: pending. Prior iteration used Godot 4.7.2 on Linux; do not present that as a new execution.
- No capture, screenshot, recording or compositor troubleshooting is authorized. Do not recreate the deleted `.lore/local/experiments/` tree.

## Discovery

Not repeated. The current capture/release/backlash mechanic and theatrical presentation remain selected. Adjacent-game research and originality claims are outside this bounded iteration.

The player promise under test is a fight requiring consequential positioning and response to active opponents, rather than avoidance of stationary traps.

## Comparison plan, before results

- Observation: stationary opponents attacking a permanent direction behave like traps; an exit objective can reward bypassing the combat being tested.
- Hypothesis: advancing/repositioning opponents, refreshed player-directed announcements and a safe-position requirement for capture create worthwhile tactical choices.
- Competing explanations: movement may merely prolong pursuit; safe-position capture may remove choices; a retreating opponent may create acquisition stalemate; kill-all may expose a weak combat loop rather than improve it.
- Prediction: Ronald must reposition to obtain attacks and distinguish the two opponent behaviors. This predicts a changed decision problem, not enjoyment.
- Counterevidence: unavoidable damage, impossible capture, indefinite kiting, trivial repeated capture/release, confusing timing, or Ronald finding the fight tedious despite technically active opponents.
- Baseline: the familiar packaged two-pursuer presentation at `37026b6`. Candidate changes combat rules/content together; any enjoyment difference cannot be attributed to enemy movement alone.
- Preserve: player AP/MP separation, free capture when legal, release cost and captured geometry, deadline/replacement backlash, exact assessment/commit agreement, authoritative model events, accepted art, director, board projection and wave pacing unless an explicit conflict is surfaced.
- Mechanical gate: controlled tests for the movement policies, collisions and aimed fixed announcements; any-threat capture rejection; defeat-all completion and death/reset boundaries; exact previews and ordered enemy movement events. Finite presentation must consume those events rather than decide movement.
- Acquisition diagnostics: test controllable chase/range/crossfire positions and whether the requested start permits attack acquisition and fight completion. Automated findings can expose a deadlock, not establish fun or universal strategy quality.
- Human gate: Ronald plays a complete fight and reports whether the opponents create interesting choices, what becomes repetitive, and whether another fight is wanted. Enjoyment, desire to continue and actual voluntary replay remain separate observations; no scores or replay are assumed.
- Exposure: Ronald knows the baseline; learning and order effects cannot be reset. No new telemetry, recruitment or live personal-data collection is introduced.
- Stop/escalate on an unavoidable acquisition deadlock, a consequential unresolved rule choice, or the implementation workflow's correction limits. Do not solve those by silently adding player attacks, changing capture range or introducing progression.

## Six mechanic alternatives

Not applicable to this iteration: the human selected concrete revisions to the existing capture bargain and two opponent movement patterns. No six new core alternatives were requested or tested. Do not describe the two opponent roles as six-way mechanic exploration.

## Build and replay manifest

Candidate implemented and technically reviewed. Replay the source checkpoint containing this record and the active-opponent model/content/UI/tests; predecessor baseline is `37026b6`. The candidate is checkpointed before human feedback so a later revision need not overwrite it.

Normal launch from the repository root:

```sh
godot --path games/borrowed-turns
```

Close an older running process first to load the changed scripts. Normal entry selects Stage and the active two-pursuer fight. M/C/L/E select Move/Capture/Release/End Turn; inspect the model's preview and Confirm. Capture requires an unthreatened position within reach. Restart/terminal Replay restore the same fixture. The explicit old escape comparison remains `-- --encounter=escape --presentation=paper`; presentation changes preserve the current model.

Godot 4.7.2 on Linux; existing packaged game/source assets, no new dependencies, RNG, save/progression or unlock system. No seed is needed: sequential fixture order and left/up/down/right ties are deterministic. New temporary verification output belongs outside the retired scratch tree, under `.lore/local/verification/active-opponents/`. No graphical gate or physical-input claim accompanies headless checks; Ronald must judge the live slides and fight.

### Implementation and evidence boundary

- Authoritative model: keep `assess()` cloning/executing the same command pipeline as commitment. No UI AI or separate turn simulator.
- Content join: top-level `objective` is `defeat_all` or explicit `escape`; enemy `movement_pattern` is `chase_player` or `keep_max_range`, with per-enemy `movement_budget` initially one. Missing movement pattern remains stationary for authored comparison content and controlled fixtures.
- Movement events reuse `{type: "move", actor, from, to}`; ability displacement remains `displace`. Current intention shape remains unchanged.
- Deterministic choices: sequential enemy fixture order, current occupancy, stable cardinal ties; chasing seeks a free player-adjacent cell, ranged positioning seeks a reachable usable firing position using existing attack geometry. Dominant-axis cardinal aiming uses horizontal ties; diagonal targets need not be hit.
- Capture must also recheck safety after irreversible replacement backlash. If displacement makes a different current enemy attack cover the player, acquisition fails with a threatened reason while discharge effects and empty storage remain. Pre-command rejection remains atomic.
- Check defeat-all after a player command's complete effects, including replacement outcomes, with player loss taking precedence. No decorative exit or escape-only victory wording in combat.
- Presentation extends the existing finite event timeline with ordered movement cues. Keep fresh next-turn announcements quiet while old attacks/slides play; show settled authoritative intentions afterward. No new clock or animation-driven model changes.
- Test authoring runs in separate scopes: model/core fixtures and controlled movement/capture/objective checks; UI/controller/presentation fixtures and cue/selection/replay checks. Old successful-capture fixtures must use safe flanks, not bypass the new rule. Overlap-only fixtures remain useful for inspection.
- Independent evidence budget: focused behavioral RED/GREEN, full model regression, affected controller/presenter/mixed-effect checks and headless fight integration. Reuse unchanged projection/art/pixel verification unless those consumers change. Add a bounded actual-content command trace for acquisition, both opponent roles, defeat-all and a lone-ranged endgame. Search failure is an investigation signal, not proof of impossibility.
- Final technical correctness review, then separate refactor and engineering-quality assessment. Human live play, not automated scores, judges whether the fight is fun.

## Sessions and evidence

No candidate human play session yet. The user observations above concern the baseline and design direction; technical results follow.

### Model behavioral RED

The first focused run exposed an old mandatory-exit access in the new no-exit fixture. Its assertion failures were not accepted as clean RED because script errors contaminated the combat cases. A minimal neutral setup guard makes the old escape check return when no exit exists; it does not implement defeat-all victory or the requested AI/capture changes.

The independent recheck then exited 1 with **142 checks, 23 behavioral failures**, without script/import/setup errors. Failures cover any-threat capture, post-backlash acquisition, chase/range movement, aim lock and defeat-all outcomes. The frozen test SHA-256 is `9bd9bf3ab8ff9eeadf6ffecd2c1a72dc17911b3498c739f43a59ffeda3683745`; neutral model SHA-256 is `ace456df83a50bcb81441690e5d5cfadde93c5792b421d11bea0a161defd8c77`. Model/content/test/fixture boundaries matched before and after. Exact command and logs: `.lore/local/verification/active-opponents/model-red-recheck/`, runner `tests/run.gd -- --focus=active-opponents`. Existing escape-win coverage was not invoked by this focused run and must be revalidated in the full model regression.

Production model/content implementation follows with tests frozen; presentation test authoring continues in a separate write scope. No candidate enjoyment evidence exists.

### First model verification

The production model/content pass passed syntax and independent focused behavior **142/0**. Full model regression reached **444 checks, one failure** in the old deadline burst-damage case, so full GREEN and the actual-content winning-route diagnostic are not yet claimed.

The controlled burst enemy initially faces away, but now correctly re-aims after the first turn. On the next end-turn it may damage the player in addition to stored backlash, invalidating the old total-HP assumption. The test-author repair must distinguish ability-scaled backlash from that fresh enemy attack while retaining meaningful combined damage/event coverage; do not revert the new aim rule or weaken the assertion to fit. Production model/content remain frozen during this test-isolation check.

The repaired full model regression passed **446/0**, exit 0. Independent `assess`/`act` replay confirms player HP 20→18 from backlash, then 18→16 from the refreshed enemy burst, with both ordered 2-damage events. The test now protects individual effects, their order and combined controlled total; no production behavior was changed to satisfy it.

A bounded actual-content diagnostic examined 12,000 states in 37.4 seconds and hit its cap without establishing the requested complete winning route. Its result is **unknown**, not impossible; no capture-plus-both-roles or lone-ranged route is claimed from it. Logs, the actual configuration and replay script remain at `.lore/local/verification/active-opponents/model-green-recheck/`. A bounded follow-up investigates search limitations versus a real acquisition/stalemate problem before live handoff; no silent rule relaxation, player attack, range change or health tuning is authorized by a search timeout.

### Actual-content feasibility replay

A guided public-API replay subsequently established a complete route through the unchanged candidate: **59 legal commands, victory on turn 14, all 8 HP retained**, five captures/releases from each source, with both opponents emitting real movement events. Every assessment was nonmutating and every commitment matched its assessment exactly. The replay exited 0; model/content before-after hashes matched. No tuning, strategy framework or game/test edits were used.

The first manually predicted continuation misread B's tie-break and failed; its evidence remains separate, not rewritten as success. The earlier breadth-first search was poorly matched to a 59-command route: harmless release branches, repeated route reconstruction and absolute-turn state keys consumed its cap. Do not expand it or infer universal recoverability from this one successful path.

For reproducibility without depending on local logs, the following route uses the actual open 5×5 candidate, player `[0,2]`, A `[4,0]`, B `[4,4]`, player HP 8, enemy HP 5 each, 2 AP/2 MP, capture reach 1, existing range-2 damage-1 shove, enemy movement budget 1 and deterministic left/up/down/right ties. Perform listed moves in order, then capture/release where shown, and End Turn except after turn 14.

| Turn | Move destinations | Capture → release target |
| --- | --- | --- |
| 1 | `[1,2]`, `[2,2]` | — |
| 2 | `[2,1]`, `[2,0]` | A → `[3,0]` |
| 3 | `[2,1]`, `[3,1]` | A → `[3,0]` |
| 4 | `[4,1]`, `[4,0]` | A → `[3,0]` |
| 5 | `[4,1]`, `[3,1]` | A → `[3,0]` |
| 6 | `[4,1]`, `[4,0]` | A → `[3,0]`; A dies |
| 7 | `[3,0]`, `[2,0]` | — |
| 8 | `[1,0]`, `[0,0]` | B → `[0,1]` |
| 9 | `[1,0]`, `[1,1]` | — |
| 10 | `[1,2]`, `[1,3]` | B → `[0,3]` |
| 11 | `[0,3]` | B → `[0,2]` |
| 12 | `[1,3]`, `[1,2]` | — |
| 13 | `[1,1]`, `[1,0]` | B → `[0,0]` |
| 14 | `[0,0]` | B → `[0,1]`; victory |

Detailed temporary replay/snapshots are under `.lore/local/verification/active-opponents/route-investigation/`. This is mechanical feasibility evidence, not enjoyment or a dominance proof. The repeated flank/capture/release rhythm is a human-play question. Do not coach Ronald through this route before his first candidate fight unless he asks for help.

### Presentation behavioral RED

The test-author pass uses the existing move-event dictionary, adds only absence-safe UI/board exit guards for loadable no-exit scenes, and isolates old successful-capture cases to safe flanks. New movement, announcement gating, objective wording and normal-entry behavior remain unimplemented for RED.

Independent headless results: controller **343/71 failures**, rendering **229/21**, pure two-source presenter **378/69**, active-fight UI **78/11**, two-pursuer UI **244/1**; the existing board-comparison integration already passes **4515/0**. All runners were free of script/import/setup errors. Missing finite movement segmentation, premature fresh warnings/rehearsals, the old escape/paper default and incorrect combat/partial-failure wording explain distinct valid REDs. Any-source threatened-capture rejection, disabled confirmation and atomic history/model checks already pass. C01 still protects real backlash damage/displacement before the later lethal attack.

The active UI victory sequence contains a separate fixture error: after the surviving source re-aims at the player, it attempts to capture again without first leaving that threat. The resulting terminal/replay failures are not accepted as behavioral RED. Repair the test using real movement to a safe adjacent flank before acquisition; do not disable targeting or bypass the capture rule. Logs and scoped source hashes are at `.lore/local/verification/active-opponents/ui-red/`. No production presentation implementation is released until that sequence is valid.

The repaired sequence proves the blocked attempt is atomic, then uses two normal moves to a safe adjacent flank while the source's aim stays locked. Independent active UI recheck reached `won` and passed Replay; remaining RED is **97 checks, eight failures**, exit 1, exclusively the unimplemented defaults/copy/movement sequencing. No setup/script errors occurred, and other game files matched the prior run. Smoke test SHA-256 is `47c8ef516c5dca16e9e600b78491fc91023a21b06b86ecb5eb696895cd852129`. Evidence: `.lore/local/verification/active-opponents/ui-red-recheck/`. The other valid REDs and already-passing comparison test are reused. Presentation production is now released with these tests frozen.

### Presentation implementation

The designer's production pass adds enemy-only finite move cues on the existing clock and event indices, preserving displacement inside its owning ability cue and player-step pacing. The frame exposes `announcements_deferred` only while a changed-turn transition still has finite feedback; board warnings, Plans/inspection and director presentation share that gate. Same-turn capture still leaves the other source's current announcement active. No new combat planner or clock is introduced.

Normal entry now selects the Stage two-pursuer defeat-all fight. Explicit plain/paper/escape comparisons remain. Objective-bearing state/events drive visible goal, remaining foes and victory/history wording; capture rejection and post-backlash threatened-acquisition failure remain distinct. Syntax checks passed; model/content, frozen tests and assets were not edited in this presentation pass. Independent combined headless verification follows the source freeze. Plain view now waits for the same finite feedback queue rather than unlocking ahead of the other views.

### Combined headless verification

Independent UI GREEN passed every requested runner without script/import/setup errors:

| Runner | Checks / failures |
| --- | --- |
| `tests/shadow_presentation_run.gd` | 531 / 0 |
| `tests/shadow_rendering_run.gd` | 357 / 0 |
| `tests/two_pursuer_presentation_run.gd` | 568 / 0 |
| `ui/smoke.gd -- --focus=active-opponents` | 244 / 0 |
| `ui/smoke.gd -- --focus=two-pursuers` | 269 / 0 |
| `ui/board_comparison_smoke.gd` | 4512 / 0 |
| `tests/board_warning_run.gd` | 419 / 0 |
| `tests/standee_board_run.gd` | 302 / 0 |
| `ui/smoke.gd -- --focus=two-pursuers-cli --presentation=stage --encounter=two-pursuers` | 26 / 0 |

Each command uses `godot --headless --path games/borrowed-turns --script res://<runner>` with the listed user arguments; all exited 0. The earlier full model command `res://tests/run.gd` remains 446/0 with unchanged model/content. Full projection and artwork pixel suites were not rerun because those algorithms/assets were unchanged.

The 95-file game/source/test/assets boundary matched before and after the UI batch. The default-entry log reports `two-pursuers` in `stage` and loads `res://assets/puppets/two-pursuers`. Finite slides, warning deferral, input lock/cancellation, atomic rejected capture, real safe-flank acquisition, combat victory/replay and mixed-ability C01 paths were reached. Exact commands, exits, logs and hashes: `.lore/local/verification/active-opponents/ui-green/`. Parent edits after that batch only clarify README status/copy, not executable code.

No new screenshots, recordings, compositor operations or regenerated scratch experiment tree were used. These results establish exercised mechanics/presentation logic, not physical-input reliability, live visual acceptance or enjoyment.

### Final technical review and handoff

Fresh correctness review found no blocking defect. It identified one leftover exit-only hint in retained plain/paper views, J1. A copy-only correction now says to complete the displayed goal; existing objective-aware header guidance remains explicit for both combat and escape. Independent active UI recheck passed **248/0**, exit 0, with only that hint literal changed in executable source. Fresh targeted review closed J1; broader GREEN evidence remains valid.

The subsequent separate refactor assessment found no worthwhile change before play. Separate engineering-quality assessment found the model-owned deterministic search, shared command pipeline and event-driven finite presentation proportionate to this small fight. Path copying, linear visited checks and assessment cloning are unprofiled trade-offs, not measured performance defects or justification for a larger AI framework.

The next evidence is Ronald playing one complete fight without being coached through the verified route. Ask whether active opponents and safe-position capture create worthwhile choices and where play becomes repetitive or unclear. Do not start run/progression work, add attacks/abilities, tune difficulty or polish visuals without that feedback. `mind-garage-jkv` remains open for this human checkpoint; `mind-garage-7am` stays deferred.

## Revision log

- Initial intervention authorized through the requested opponent/objective changes and explicit any-enemy capture clarification. Technical reconnaissance precedes controlled tests and implementation.

## Findings and next decision

Game outcome: unknown. Method outcome: the human diagnosed the stationary-trap problem and chose the intervention; do not attribute these design contributions to an autonomous AI diagnosis.

The next decision is whether one complete fight is engaging enough to iterate or to support later multi-fight run design. Narrative implementation and run progression remain deferred.

## Repeatability handoff

- Replay: use this candidate's source checkpoint, follow the normal launch above and use Restart/Replay for an empty-storage, full-budget start. A fresh checkout must first import the shipped textures as described in the game README. Restore `37026b6` only for the earlier stationary/escape baseline comparison.
- Repeat method: use controlled fixtures and the same human fight questions; reopen tuning rather than hardcoding the first candidate's values into tests.
- Limits: one experienced player, bundled rule changes, prior exposure and no claim that automated play predicts enjoyment.
- Actionable work: `mind-garage-jkv`. Deferred run/progression discussion: `mind-garage-7am`.
