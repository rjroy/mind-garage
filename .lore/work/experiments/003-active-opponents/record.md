---
title: "Experiment 003: Curtain Call active opponents"
date: 2026-11-16
status: draft
tags: [game-design, experiment, curtain-call, combat]
related: [.lore/work/intents/player-brief.md, .lore/work/experiments/002-shadow-paper/record.md, .lore/work/narrative/borrowed-turns/curtain-call-narrative-brief.md]
---

# Experiment 003: active opponents

## Inputs and provenance

- Experiment ID: `003-active-opponents`. Current stage: shared-AP, wide-shove and Stage-only revision technically verified and reviewed; awaiting Ronald's play.
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

First candidate checkpoint: `9450bfe`, implemented and technically reviewed; predecessor baseline is `37026b6`. Keep that version for comparison rather than overwriting the evidence when tuning the next candidate.

Normal launch from the repository root:

```sh
godot --path games/borrowed-turns
```

Close an older running process first to load the changed scripts. Normal entry selects Stage and the active two-pursuer fight. M/C/L/E select Move/Capture/Release/End Turn; inspect the model's preview and Confirm. Capture requires an unthreatened position within reach. Restart/terminal Replay restore the same fixture. The retained escape encounter is available with `-- --encounter=escape`, also in Stage. The second candidate removes the old presentation selectors and `--presentation` option; historical commands below describe their original checkpoint, not current launch instructions.

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

Ronald's first qualitative candidate report follows the technical results below. No enjoyment score, complete command trace, actual damage total or voluntary replay measure was collected.

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

### Human feedback and next budget change

After checkpoint `9450bfe`, Ronald reported: “It was playable, but I'm not sure it was intersting choices. There was no sense of peril.” He described the fight as feeling impossible to lose. This is perceived lack of danger, not a claim that the model has no loss state. Do not infer a specific play route, damage total or completed victory from this report.

Ronald requested removing movement points entirely: each moved tile costs 1 AP, with 3 AP per turn instead of 2 AP plus 2 MP. This is the next intended player-budget rule, not yet implemented at this point in the record. He wants a genuinely fun fight before considering tutorial placement or run structure, and asked for ideas to create peril.

The existing verified no-damage route uses at most two moves and one release per turn, with free capture and End Turn. It therefore still fits the proposed 3-AP pool. The merge creates opportunity costs but does not, by itself, invalidate that safe routine. This is a pre-intervention prediction, not evidence that the requested change is useless.

Next discussion considered interacting threats, coordinated positioning and displacement hazards rather than merely inflating health, adding surprise retargeting, imposing unrelated timers or making capture impossible. Preserve visible full-tile attacks, source-driven waves and the any-threat capture restriction. No new capture, screenshot, video, asset or progression work is included.

### Approved second candidate: shared AP and wide shove

Ronald selected **Wide-shove opponent (Recommended)** with the requested shared 3-AP budget. Keep A's narrow chase/shove and B's maximum-usable-range positioning, but give B a three-tile-wide shove. Health, damage, range/depth, capture reach, enemy one-step budget, starting positions, art and pacing remain unchanged for this first pressure pass. The intended difference is threat interaction and a more useful borrowed shape, not a health sponge or guaranteed damage.

- Remove the player's separate movement resource and active MP schema/copy. Moves cost 1 AP per tile; release costs 1 AP; capture remains free when legal; End Turn remains free and explicit. At zero AP, legal free capture still works; movement/release do not. Enemy `movement_budget` remains its own AI step setting, not a player resource.
- Shove `width` defaults to 1; B uses 3. The affected region covers front depths 1 through range, lateral offsets −1, 0, +1, clipped by board bounds and forward blocking independently in each lane. Do not add the source row or behind-source tiles; safe adjacent flanks must remain possible.
- Preserve width through capture, release, preview and ability-specific backlash. Backlash hits the player once plus the actual wide forward region; existing once-per-actor hit/push rules remain.
- Use that same model geometry for attack announcements and ranged usability. UI consumes exact cells; the full-tile wash and existing source-driven fronts must span the wider region without a new arrow/asset vocabulary.
- Controlled evidence should demonstrate a wide-only tile blocking a formerly safe capture approach, exact borrowed geometry, clipping/push behavior and shared-budget atomicity. The earlier 59-command routine remains the AP-only counterfactual; test whether the wide candidate breaks it for a meaningful reason rather than assume it does.
- Verify one complete feasible candidate fight and a capturable lone-B endgame without silently relaxing safety or adding player attacks. A no-damage solution remains acceptable; human choice quality and felt peril are the actual outcome.

Model/UI test-author scopes run separately. Old independent-AP/MP assertions are superseded, not preserved behind a compatibility mode. Minimal old-field absence guards may enable loadable RED setup, but final production must remove those temporary MP consumers. No new run, tutorial, hazard, third opponent, capture cost, health/damage tuning or asset generation is authorized by this choice.

The second candidate's independent focused model RED is clean: `tests/run.gd -- --focus=shared-ap-wide-shove` exited 1 with **87 checks, 21 failures**, without script/import/setup errors. The neutral old model still rejects moves using zero legacy MP; wide geometry and payload tests expose missing cardinal/wall/edge/side-threat/release/backlash/ranger behavior. The main interleaving case returns early on its first rejected move, so its later two-move-plus-release and exhausted-AP checks are not yet exercised; GREEN must reach those branches. Test SHA-256 is `6fccb68f527fbfa8107d9fdc8d8c31a2ea6894faef9da87a439b1031f9689260`. Scoped source/fixture boundaries matched before and after. Evidence is under `.lore/local/verification/active-opponents/shared-ap-wide/model-red/`.

Production model/content implementation is released with those tests frozen. Presentation test authoring remains separate; temporary missing-MP guards in old UI diagnostics/formatting are allowed only for setup and must disappear from the AP-only production version.

### Second-candidate implementation and verification

The model now uses one player AP pool. The UI displays AP-only costs and derives wide-ability descriptions from stored metadata; it does not retain a fallback player movement resource. The generic wavefront renderer already spans the wider region, so no new rendering algorithm or artwork was needed.

An implementation review caught an unintended release-range fork: wide releases initially extended to maximum range while narrow releases stopped at the selected endpoint. This was not authorized. A controlled near-endpoint regression produced **115 checks, two failures** in the focused suite. The correction makes both widths stop at the selected endpoint; enemy announcements and backlash still use their authored range.

Independent model GREEN then passed **115/0** focused checks and **504/0** full regression, both exit 0. Interleaved moves/capture/release, zero-AP free capture, paid-action rejection, cardinal wide regions, lane blocking, clipping, stored width, backlash, ranged usability and endpoint truncation were reached. Model SHA-256: `f59caf51d249f6c01c834425d2fd5b2ecb5e429bfb119c1511c00a92f95ff50e`. Evidence is under `shared-ap-wide/endpoint-red/` and `shared-ap-wide/model-green/` within the local verification directory.

Independent presentation verification passed the shared-AP focus **166/0**, board comparison **4670/0**, board warnings **475/0**, controller **531/0**, rendering **357/0**, pure two-pursuer presenter **568/0**, standee board **302/0**, active-fight UI **250/0**, two-pursuer UI **277/0** and normal-entry CLI **30/0**. All exited 0 without script/import/setup errors; the 95-file boundary remained unchanged. The unfocused UI smoke did **not** pass: **603 checks, four failures**, concerning two corner-targeting and two retained plain/paper intention-row viewport assertions. Their cause is under investigation, not dismissed as unrelated or reported as GREEN. Logs are under `shared-ap-wide/ui-green/`.

Diagnosis reproduced the two corner failures in an isolated `9450bfe` baseline. Opaque player artwork overlapped a corner tile; normal picking correctly selected that actor rather than the floor. The corner mapping test now uses the existing Alt-floor GUI path, retaining its selection/state assertions and leaving ordinary actor/marker/roster tests unchanged. Independent Stage-focused recheck is **312 checks, two failures**, exit 1, exclusively the scroll regressions, with no setup/script errors. This focused invocation does not itself run the separate actor/marker/roster paths.

The two new scrolling failures are real: after restoring plain/paper Plans from Stage Events, content requiring 340 px retains a 291 px allocation and scroll range, placing the button 20 px outside the usable viewport. Additional frames do not cure it. Production correction must refresh layout allocation rather than shorten guidance, weaken visibility checks or add delays. Smoke SHA-256 at isolated RED: `f97f2d93f992d7454f9e1041639f8dcdeadbc177ba180683f22387fbcc77ba3a`. Evidence: `shared-ap-wide/ui-diagnosis/` and `shared-ap-wide/ui-scroll-red/`.

Two bounded layout-refresh attempts did not fix the allocation; both were reverted. Work stopped at the retry limit. On learning that these failures concerned switching to obsolete comparison views, Ronald explicitly authorized removing plain/paper instead: their retention was precisely the cruft he expected the earlier cleanup to remove. This supersedes the proposed scroll repair, not the recorded failure history.

Stage is now the sole supported presentation. The implementation removes obsolete modes, selectors, flat rendering branches and the comparison capture tool rather than merely hiding them. Switching-only tests are retired; distinct gameplay, escape-objective, picking, animation and presentation coverage is migrated to Stage. The shared shadow renderer still serves the escape encounter and is retained. The substantially useful board-comparison runner is retained despite its historical name. Independent final verification and technical review remain pending.

Independent Stage-only verification passed all changed runners: projection **1018/0**, standee board **297/0**, board warnings **473/0**, rendering **351/0**, full UI smoke **483/0**, board comparison **3787/0**, active-fight UI **247/0**, shared-AP UI **88/0**, two-pursuer UI **267/0** and normal-entry CLI **32/0**. Each uses `godot --headless --path games/borrowed-turns --script res://<runner>` with the corresponding focus arguments and exits 0. The full smoke does not include the focused paths, so those were executed separately. Body, foot-marker, overlap and roster picking are exercised; actual roster clicks and escape victory pass.

Main-scene startup with `--quit-after 3`, both normally and with `-- --encounter=escape`, exits 0 in Stage. Retired bare `--presentation` and `--presentation=paper` exit 2 with an explicit unsupported-option message. No supported documentation launch examples or old mode consumers remain in the checked game scope; historical records are not rewritten. The 93-file game/assets manifest is unchanged before/after, SHA-256 `43c66bf9026525076555c65ec8bf75d8f01fca52e03d25f8ebe52fd7a738f067`. Model/content hashes remain unchanged, preserving model **504/0** and the actual-route comparison. Controller and pure-presenter results are reused, not claimed as new executions. Exact commands, exit files, logs and scans: `.lore/local/verification/active-opponents/stage-only-cleanup/independent/`.

Fresh correctness review found G1: release-ray rendering uses the final affected cell as its endpoint. Wide regions end on a lateral cell, so an otherwise correct cardinal release can display a diagonal arrow in preview and finite feedback. For example, origin `[2,4]`, selected endpoint `[2,2]`, width 3 ends its cell array at `[3,2]`. The exact affected tiles and model outcomes remain correct. A focused regression and correction must derive the ray from the owning release event/cue, preserving the selected endpoint and clipped footprint. No other material defects were reported; G1 remains open.

Independent G1 RED reached **542 checks, 24 failures**, exit 1, exclusively wide-release endpoints in preview and finite feedback at two board extents, covering near/full targets and a wall-clipped side lane. Narrow control, valid fixture actions, exact footprint coverage and model purity pass. Tests observe the inherited renderer's actual arrow/tile calls through a test-owned subclass; no production testing seam or duplicate endpoint algorithm was added. The production correction changes only the board's release-ray consumer: finite playback uses the release cue's origin/target; preview uses the actual release event's target and pre-release player origin. The footprint tile loop is unchanged. Independent GREEN and focused review remain pending. Evidence: `stage-only-cleanup/g1-red/` and `g1-author/`.

Independent G1 GREEN passed rendering **542/0**, board comparison **3787/0** and full UI smoke **483/0**, all exit 0. All 24 prior endpoint failures are reached and pass; exact cells and narrow control remain covered. The 93-file before/after manifest matches, SHA-256 `c1c52108d8dcedd28d3f61a3ec85d4f0d5fe7ab282ccc590161243e186014970`. A fresh focused correctness review closed G1 and found no remaining correction-scope defect; it inspected the logs, actual consumers/tests and matching frozen source rather than claiming new test execution. Evidence: `stage-only-cleanup/g1-green/`.

The subsequent separate read-only refactor assessment found no worthwhile further change before play. Independent engineering-quality assessment found the shared geometry/command pipeline and direct Stage construction appropriate, with no material findings. The shared renderer and distinct test boundaries are retained for actual consumers, not hypothetical compatibility. Performance remains unprofiled; no measured bottleneck justifies a caching or AI framework. All 93 frozen source entries still match. No source changes followed these assessments.

Second-candidate handoff: launch normally, without presentation arguments, after closing an older process. Judge whether shared AP and interacting wide/narrow threats create worthwhile choices and felt danger, and whether the lone-opponent phase becomes repetitive. Do not coach the recorded winning route unless requested. `mind-garage-jkv` stays open at the human checkpoint; run/progression work remains deferred under `mind-garage-7am`.

### Controlled pressure comparison and feasibility

Cloning the current configuration and changing only B's width to 1 preserves the old 59-command, turn-14 victory with 8 HP and no damage. In the actual width-3 candidate, the same routine rejects command 11: capture A on turn 3 from `[3,1]`, with 1 AP remaining. B at `[3,3]` faces upward and covers columns 2–4, rows 1–2. This first denial is on the centre lane: width also changes which ranged positions are usable, so it is not evidence of lateral coverage alone.

A separate actual turn-5 state demonstrates the side-lane effect. From player `[3,1]`, AP1, A `[3,0]` and B `[2,2]` aiming right, B's lateral row blocks capturing A. Ending immediately reduces HP7 to HP6; spending the final AP moving to `[2,1]` before ending preserves HP7 but gives up that turn's capture/release opportunity. An earlier turn-3 detour also avoids damage. These are avoidable positioning costs, not evidence of unavoidable hits or enjoyable decisions.

One complete actual-candidate route wins on turn 16 after **71 commands, HP7, one total damage**, five captures/releases from each source. Both enemies move; the lone-B endgame remains capturable. Every assessment is nonmutating and every committed result exactly matches it. Model/content hashes remain unchanged. The following recipe preserves replayability without requiring local generated JSON. Each row ends with End Turn except T16; execute actions in the stated order.

| Turn | Moves | Capture/release |
| --- | --- | --- |
| 1 | `[1,2]`, `[2,2]` | — |
| 2 | `[2,1]`, `[2,0]` | A → `[3,0]` |
| 3 | `[2,1]`, `[3,1]` | —; take one damage |
| 4 | `[4,1]`, `[4,0]` | A → `[3,0]` |
| 5 | `[4,1]`, `[3,1]`, `[2,1]` | — |
| 6 | `[1,1]`, `[1,0]` | A → `[2,0]` |
| 7 | `[1,1]`, `[2,1]` | A → `[2,0]` |
| 8 | `[3,1]`, `[3,0]` | A → `[2,0]`; A dies |
| 9 | `[2,0]`, `[1,0]`, `[0,0]` | B; hold at AP0 |
| 10 | After release: `[1,0]`, `[2,0]` | Release B → `[0,2]` first |
| 11 | `[1,0]`, `[0,0]`, `[0,1]` | B; hold |
| 12 | After release: `[1,1]`, `[2,1]` | Release B → `[0,3]` first |
| 13 | `[1,1]`, `[0,1]`, `[0,2]` | B; hold |
| 14 | After release: `[1,2]`, `[2,2]` | Release B → `[0,4]` first |
| 15 | `[1,2]`, `[0,2]` | B → `[0,3]` |
| 16 | `[0,3]`, `[0,4]` | B → `[1,4]`; victory |

Temporary scripts, snapshots, commands and exit statuses are under `shared-ap-wide/route-comparison/`. One diagnostic JSON-number decoding setup error is retained separately; coordinates were converted to the existing integer command contract, not accepted through a gameplay relaxation. No search, tuning, graphics or game/test changes were used. This establishes feasibility and disruption of one known routine, not strategy dominance, felt peril or enjoyment.

## Revision log

- Initial intervention authorized through the requested opponent/objective changes and explicit any-enemy capture clarification. Technical reconnaissance precedes controlled tests and implementation.
- Candidate `9450bfe` is technically feasible but human feedback finds insufficient choices/peril. Proposed next budget is one 3-AP pool with movement costing 1 AP; opponent-pressure intervention remains to be selected.
- Ronald selected the second candidate: shared 3 AP plus B's three-wide borrowed shove. Baseline `9450bfe` is retained; test the changed threat interaction before any damage/health calibration.

## Findings and next decision

Game outcome: playable, but Ronald is unsure it offers interesting choices and reports no sense of peril. Enjoyment, continuation and voluntary replay remain unmeasured. Method outcome: technical checks established feasibility but not enjoyment; the human diagnosed both the stationary-trap issue and the subsequent lack of peril, and supplied the shared-AP change. Do not attribute those design contributions to an autonomous AI diagnosis.

The next decision is whether one complete fight is engaging enough to iterate or to support later multi-fight run design. Narrative implementation and run progression remain deferred.

## Repeatability handoff

- Replay: use this candidate's source checkpoint, follow the normal launch above and use Restart/Replay for an empty-storage, full-budget start. A fresh checkout must first import the shipped textures as described in the game README. Restore `37026b6` only for the earlier stationary/escape baseline comparison.
- Repeat method: use controlled fixtures and the same human fight questions; reopen tuning rather than hardcoding the first candidate's values into tests.
- Limits: one experienced player, bundled rule changes, prior exposure and no claim that automated play predicts enjoyment.
- Actionable work: `mind-garage-jkv`. Deferred run/progression discussion: `mind-garage-7am`.
