---
title: "Experiment 005: Opponent library trials"
date: 2026-11-17
status: draft
tags: [game-design, experiment, borrowed-turns, opponents]
related: [.lore/work/games/borrowed-turns/experiments/004-switcher/record.md, .lore/work/shared/audience/player-brief.md]
---

# Experiment 005: Opponent library trials

**Historical scope:** This record describes the ten-encounter build tested below. After that comparison Ronald retired the Original encounter (`escape`) rather than maintain it. Its recorded results still stand; the current parity recipe covers only the three surviving controls.

## Inputs and provenance

- Stage: comparison plan recorded before candidate results. Baseline source: `6def00f`, including the player brief and project procedures at that revision. The existing game is `games/borrowed-turns`.
- Inputs: [player brief](../../../../shared/audience/player-brief.md), [experiment brief](../../../../shared/method/ai-game-design-experiment.md), [hook discovery procedure](../../../../../../.agents/skills/discover-game-hook/SKILL.md), [mechanic exploration procedure](../../../../../../.agents/skills/explore-mechanic/SKILL.md), and [Switcher record](../004-switcher/record.md). Their baseline versions are preserved at `6def00f`.
- Ronald is the sole intended player. He requested a broadly useful stock library, including new movement ideas and the existing ability set, rather than adding opponents one at a time. The proposed trial bundles below are AI-selected; record further human choices, diagnoses, and rejections as they occur. Agent/model identity for the original proposals is not established here.
- Preserve existing Stage art, 7×7 board, 3 AP, and the Capture/Shine mechanic. No new telemetry or external data; automated execution is headless only. No new assets or progression are assumed.
- Candidate: uncommitted opponent-library changes on `experiment/borrowed-turns-prototype` over `6def00f`. Headless engine: `4.7.2.stable.arch_linux.ed1daf0bf`, Linux. No candidate commit is claimed.

## Discovery

This is a bounded follow-up to Borrowed Turns, not a fresh hook selection. The existing promise is to survive an announced attack, capture it, and use it through Shine. The library tests whether different combinations of movement and abilities offer distinct positional matchups. Adjacent-game research and new hook discovery were not repeated; no originality claim follows.

## Comparison plan, before results

- **Question and hypothesis:** Can stock opponent bundles produce readable, completable solo matchups that give Ronald different positional choices? Different movement and attack combinations are expected to change where he wants to stand and when he captures.
- **Competing explanations:** Variety may be cosmetic, confusing, repetitive, or frustrating; a different matchup may reflect difficulty, familiarization, or encounter geometry rather than a particular component. Bundled changes confound causal attribution to movement or ability alone.
- **Prediction and counterevidence:** Each opponent should announce its attack, allow a successful capture and useful Shine, and admit at least one reproducible win. An unclear announcement, an invalid state, an unreachable capture or win, or a borrowed ability that cannot finish the encounter contradicts the mechanical prediction. Ronald finding the choices tedious or indistinguishable would counter the experience hypothesis.
- **Reference and controls:** Compare informally with prior solo Switcher and A+B. Keep the existing Stage art, board size, AP and Capture/Shine rules constant. The candidate changes opponent movement and ability bundles, so this is not a controlled isolation of individual components.
- **Pre-offer threshold:** Each of the six independent solo trial IDs must have one reproducible successful capture/Shine win using actual candidate content. Check playable startup, reset, and attack announcements for each, and no impossible board states or regressions in existing behavior. A missing route or failed check blocks offering the affected candidate until corrected and rechecked. Mechanical checks establish neither balance nor fun.
- **Human comparison:** Ronald already knows A+B and Switcher. Record build, trial, order, prior experience and requested versus voluntary play. Ask separately about enjoyment, desire to continue and actual voluntary replay; requested comparisons do not count as voluntary replay. Order and learning cannot be reset. No candidate play has occurred yet.
- **Consent and data:** No new telemetry or external data collection. Any player report is voluntary and recorded with consent; missing reports and unknown replay remain unknown. No event definitions are added.
- **Stop and decision:** Do not offer an unplayable or mechanically invalid trial. After evidence and any consented play, decide keep, revert, or investigate for each bundle, recording contradictory observations and human intervention. Any change to these criteria starts a separately documented comparison.

## Six mechanic alternatives

These six bundles use the existing Capture/Shine mechanic, not six formal alternatives to it. The table preserves the proposals made before testing. The combinations do not isolate causes.

| Solo trial ID | Proposed bundle | Prediction and counterevidence |
| --- | --- | --- |
| `flanker` | Seek the nearest firing line; narrow shove/bolt. | Approaching a firing line should change positioning choices; a hidden or unreachable threat would counter readability or feasibility. |
| `lantern-guard` | Patrol a relative route; wide shove. | Patrol and a wide threat should make route timing matter; indistinguishable or invalid patrol states would counter that expectation. |
| `circler` | Clockwise orbit; wide shove. | Orbit should change the threatened approach over time; blocked or invalid orbit and unreadable threats are risks. |
| `deadeye` | Existing keep-maximum-range movement; long bolt and short swap with a fixed announced choice. | Range-dependent pressure should invite different approaches; an ambiguous choice or unreachable capture would counter the prediction. |
| `anchor` | Stationary; burst area. | A fixed source and area threat should make approach selection matter; an impossible approach or unavoidable deadlock would counter it. |
| `puller` | Chase; damaging cardinal pull, shared by Shine. | Pulling should change relative positions for both enemy and player use; illegal occupancy or an unusable borrowed pull would counter it. |

Each diagnostic is an independently reproducible capture/Shine win plus the common startup, reset, announcement, state-validity and regression checks above. These checks do not measure enjoyment.

## Build and replay manifest

From the repository root, import the packaged textures once with `godot --headless --editor --path games/borrowed-turns --import`. Start a fresh fight with `godot --path games/borrowed-turns -- --encounter=circler`, substituting any trial ID. No unlocks, saves, external services or local experiment files are needed. See [controls and restart](../../../../../../games/borrowed-turns/README.md#turn-and-controls).

The [route runner](../../../../../../games/borrowed-turns/tests/stocked_routes_run.gd) contains the exact ordered commands. It creates a fresh model per trial using the real encounter registry; no random seed or adjusted fixture is used. To replay, print each move and inspect HP and outcomes:

```sh
godot --headless --path games/borrowed-turns --script res://tests/stocked_routes_run.gd
```

## Sessions and evidence

Two independent processes replayed the same 45 player commands across the six trials. Both exited 0, with identical logs: every route survived capture, dealt damage through Shine, and won with the opponent at 0 HP.

| Trial | Captured on the verified route | Final player HP |
| --- | --- | ---: |
| Flanker | Bolt | 7 |
| Lantern Guard | Wide Shove | 9 |
| Circler | Wide Shove | 9 |
| Deadeye | Bolt | 8 |
| Anchor | Burst | 8 |
| Puller | Pull | 8 |

The movement correction invalidated the original Flanker route: two Shines missed, leaving the opponent at 2 HP. A replacement route endured the first attack before arming Capture and borrowing Bolt. No encounter tuning or relaxed assertion was needed. The other five routes still worked. Anchor and Puller even admit the same short command sequence; different effects alone do not establish different player choices.

The four original encounters were replayed against the frozen `6def00f` model with the same commands: 13 episodes, 476 recorded rows, 1,562 checks per replay. Escape, Two pursuers, Switcher and Switcher + B matched on the compared mechanical fields, including capture ownership, damage, displacement, previews, terminal outcomes and reset. The comparison excludes new metadata and is not exhaustive. To compare the controls supported by the current checkout:

```sh
sh .lore/work/games/borrowed-turns/experiments/005-opponent-library/parity/run.sh
```

No human candidate play, enjoyment score, desire-to-continue report or voluntary replay is recorded. The previous Switcher report belongs to its own record.

Headless runners used `godot --headless --path games/borrowed-turns --script res://<script>.gd`. All of the following exited 0:

| Runner | Passed checks |
| --- | ---: |
| `tests/run` (full model) | 580 |
| `tests/run -- --focus=swap-range` (focused invocation) | 13 |
| `tests/stocked_opponents_run` | 137 |
| `tests/stocked_scene_run` | 165 |
| `tests/mixed_stage_roles_run` | 65 |
| `tests/two_pursuer_presentation_run` | 913 |
| `tests/shadow_presentation_run` / `tests/shadow_rendering_run` | 374 / 2,947 |
| `ui/board_comparison_smoke` / `ui/smoke` | 4,414 / 936 |

Direct startup for all ten IDs exited 0 using `godot --headless --path games/borrowed-turns --quit-after 5 -- --encounter=<id>`. Injected scene controls and transform checks do not establish physical input or visual acceptance.

## Revision log

Before candidate results, Ronald broadened the requested library to include new movement ideas and the existing ability set. The six bundles, controls, predictions and pre-offer thresholds above define this comparison.

Headless review exposed faults that the six winning routes did not distinguish. The Board and Director disagreed about mixed placements; opposite-slot kits faced outward. Tests now compare roster slots, accents and body/hand transforms. For movement, evaluating the last announcement could send a two-ability enemy closer even when it already had a firing line. The focused check distinguishes preserving the committed attack from choosing the next one. Director tests distinguish a named source from its ability and a finishing cast from the later loss of its source. These were agent diagnoses, not human playtest feedback.

## Findings and next decision

- Game outcome: unknown until Ronald plays and reports; mechanical feasibility alone cannot establish fun.
- Method outcome: the six feasibility predictions held on at least one route each. Review found movement and presentation defects despite those routes succeeding; dedicated regressions were needed. No enjoyment prediction has been confirmed.
- Next decision: offer the bundles for comparison, not as accepted gameplay. Try Circler and Lantern Guard close together: both have wide shove, so ask whether the different movement changed where Ronald chose to stand. Record order and distinguish requested play from voluntary replay.
- Limits: one player, prior learning, exposure order and bundled changes prevent broad or component-specific causal claims.

## Repeatability handoff

Baseline `6def00f` preserves the inputs and reference game. Use the candidate sources, the route runner and the portable parity recipe above for mechanical reproduction. To repeat the wider method, reopen selection decisions rather than treating these bundles as formal mechanic alternatives. Player learning cannot be reset, and repeating AI generation need not reproduce proposals.
