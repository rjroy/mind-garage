---
title: "Borrowed Turns: capture-motion study"
date: 2026-07-02
status: completed
tags: [borrowed-turns, motion-study, shadow-puppets, visual-exploration]
related: [.lore/work/design/borrowed-turns-art/visual-systems-direction.md, .lore/work/experiments/002-shadow-paper/record.md]
---

# Borrowed Turns: capture-motion study

## Authorization and boundary

Ronald selected **Build the motion study**: temporary cutouts/background removal, a simple rig, one actual capture and subsequent legitimate announcement on the accepted stage, then a recording and replayable opt-in study for human review. No further still-image refinement or image generation. Current authorization covers this bounded pilot's temporary materials and rig, not a production cast or integration into the normal game view.

The initial phase prepared local art and the implementation/test contract. Following focused test authoring, neutral setup and independent behavioral RED, the authorized pilot is implemented in isolated study scripts and an opt-in tool. Normal game scripts remain unchanged. The parent owns Beads and the experiment record; source approval and author checks do not establish human motion acceptance.

Protect the stage/floor accepted at `dcbd13e`, all three source PNGs under `games/borrowed-turns/assets/stage/`, normal plain/paper/stage behavior, default paper selection, authoritative model/content and C01–C03 effect ordering. No new abilities, lantern mechanics, telegraph-art pass, standee-animation pass or automatic director.

## Temporary material package: prepared and inspected

Directory: `.lore/local/experiments/002-shadow-paper/capture-motion/` (gitignored).

Only the **original native** `director-exploration/storyboard-candidate.png` supplies pixels: 1024×1536 RGB, SHA-256 `6d18ad9385747855507ad32234f14928ac113b4196260153e8bac80b3df7737c`. The later ownership image, SHA-256 `0e9c129f1f208153d862905e26eff6e2bb7fd9f6a1227459c92a2f9ee6803912`, remains an unchanged direction reference, not a second hand pose. Keeping one hand source avoids an identity-changing crossfade.

| Local derivative | Native canvas | SHA-256 |
| --- | --- | --- |
| `a-body.png` | 290×145 RGBA | `183a86540b7611c47b8a8de3ba6da791e3c78e6025a9b38109c474defa1c0e3e` |
| `a-hands.png` | 290×145 RGBA | `3396932a1a8ae490b217100c79ce55a1490bde376c7896a62b6450f9f85b564f` |
| `p-lantern.png` | 145×145 RGBA | `0675257136cff1f7375b8b621dffb64f4296940e29fe3b9ddf9c4e6a4cf0f588` |

`prepare-cutouts.sh` is the exact local recipe, SHA-256 `62c3b32a2b2198de2bfad408d961f32d12acde813a53270c97f1cb832d216a70`, executed with ImageMagick **7.1.2-34 Q16-HDRI**, build `c5d4ca8a0:20261014`. It checks the source hash; crops A at `290x145+165+100` and P at `145x145+445+100`; excludes captions/architecture/floor-edge pixels with region masks; thresholds grayscale at 37%, inverts, closes with `Diamond:1`, fills enclosed holes, then uses `-blur 0x0.35 -level 5%,95%` for alpha. A binary hand-region partition separates the forearms from the body without recoloring or reconstructing artwork. PNG date/time metadata is excluded for reproducible hashes. All output canvases retain their original padding.

Verification: all three decode, with real transparent/opaque/partial pixels. Counts respectively: body **32348/8222/1480**, hands **37561/3444/1045**, P **13021/6206/1798**. Reassembled body+hands match the extracted whole A exactly, **AE=0**. Two recipe runs matched all three output hashes. Source hashes remained unchanged. No installation, repainting or generative repair was needed.

Inspected `inspection-light.png`, `inspection-dark.png`, `inspection-body.png`, and `inspection-stage-rehearsal.png` / `inspection-stage-held.png`. The latter are **static asset composites**, not Godot behavior or model-correct scene evidence; their underlying board is an existing runtime screenshot, not the forthcoming controlled study fixture. They establish source readability and a beside-lantern destination at minimum display size. `inspect-cutouts.sh` records their recipe; `asset-report.txt`, `assets.sha256` and logs retain local provenance.

Limitations: the native source clips both figures at the original backdrop/floor seam; hide these lower cuts behind the accepted floor, not with reconstructed anatomy. The body has exposed upper-arm joins during separation, so it fades as the hands depart. Dark-background inspection confirms these dark silhouettes are intended for the warm parchment screen. Native height is only 145 pixels; larger views may soften edges. Heroic/spiky reference styling remains provisional, not final cast approval. RGB samples are retained and treated as display-referred sRGB for this pilot; source has no embedded ICC/sRGB profile. Glow is a separate runtime effect, not baked into these cutouts.

Fresh checkout limitation: concept originals, recipe and temporary cutouts are local, not bundled source assets. Hashes are not substitutes for those files. The future tool must require an explicit local pack and fail clearly if missing/mismatched; never generate replacements or fall back to primitives. Sharing/promotion is a separate decision, not a blocker for this authorized local pilot.

## Assembly and motion contract

Use the accepted stage's current fitted canvas. Put the puppet layer **after the backdrop but before the floor and foreground**, so existing floor/frame occlusion hides the source's clipped lower edges. Do not change the floor quadrilateral, source textures, factual board overlays or map figures.

Native local anchors, origin at each PNG's top-left, +x right and +y down:

- A body baseline `(105,145)`; detachable forearm-pair hinge `(171,96)`. Body and hands use the same 290×145 canvas and initially reconstruct A without recentering.
- P baseline `(56,145)`; lantern handle `(105,60)`.
- Held hand hinge `(143,74)` in P's native coordinate system, **outside/beside the lantern**, facing outward to the right. Hand scale is initially 0.45 of the source's stage scale. Do not rotate hands around the lantern or form an ornamental ring.
- Starting composition: A baseline near `(0.29,0.45)` and P near `(0.54,0.45)` of the stage canvas. Stage scale initially makes the 145-pixel source about 30% of canvas height. These are local study tuning, not mechanical or permanent art requirements. Apply native anchors and scale once; recompute screen placement on resize without restarting the occurrence or clock.

One continuous sequence:

1. A rehearses a restrained forward press, stopping before P. No board movement or damage occurs while deciding.
2. Actual successful capture interrupts that occurrence. The **same keyed hands** peel away; A's remaining puppet body fades, while its map standee remains alive. Hands keep their articulated identity during travel.
3. A pale-mint outline and curling, trailing glow follow the hands. The trail links their departure to P, then contracts into a tether toward the lantern handle. It is not a projectile, ordinary cast shadow or gameplay light radius.
4. Hands settle beside the lantern, facing outward, with a small unfinished press/twitch rather than orbiting the lantern. Persistent held motion must not keep finite feedback busy.
5. Actual next-turn announcement restores A's source puppet and a **new occurrence**, while the old keyed hands remain held beside P. No release/backlash sequence is added to the review clip.

Reuse the existing `ShadowPresentation` event projection and clock. Read its active capture `cue.progress` for departure/travel/settling; use its loop phase for persistent rehearsal/held motion. Do not implement another rules simulator, event queue or independent duration gate. For this study only, replace the existing expressive board-shadow pass with the backdrop rig, while delegating the existing map figure drawing unchanged; factual board intentions, previews, deadlines and effect footprints remain untouched. An isolated study renderer adapter may do this through the board's existing renderer injection surface. Normal game instances retain their normal renderer.

## Proposed isolated runtime interfaces

These are the isolated study interfaces, implemented after independent RED.

`res://studies/capture_motion/projection.gd`, `RefCounted`:

```gdscript
func compose(snapshot: Dictionary, frame: Dictionary, expected_generation: int, source_id: String) -> Dictionary
```

Pure, detached output:

```text
{generation, source_occurrence, held_occurrence, transfer, busy, loop_phase}
occurrence = {source: String, turn: int, kind: "shove"}
transfer = {} or {occurrence: occurrence, progress: float}
```

`source_occurrence` is the studied source's current announcement, using its announcement turn. `held_occurrence` uses stored source and `captured_turn`, not the current turn. `transfer` exists only for the active, matching committed shove-capture cue and actual acquired storage: its event index must identify that source's real capture in `snapshot.events`, and snapshot storage must agree with the frame's held occurrence. While that occurrence's capture is active or still queued, suppress its settled held display. Never derive transfer from a button press, prediction or storage alone. `busy` copies shared finite-controller state, never idle animation activity. Wrong generation returns `{}`. No commands, timers, model calls, pixels or actor selection algorithm belong in this projector.

`res://studies/capture_motion/rig.gd`, `Node2D`:

```gdscript
func configure_assets(textures: Dictionary, assembly: Dictionary) -> bool
func present(description: Dictionary, stage_rect: Rect2) -> void
func hand_instances() -> Array
```

Texture keys: `a_body`, `a_hands`, `p_lantern`. Assembly supplies native canvases/anchors and tunable scales above; missing/invalid input fails rather than inventing art. `present` consumes the projector's descriptor and shared progress, with no model access. Keep one visible hand instance per occurrence, moving its role rehearsal → transfer → held; a fresh announcement gets a distinct keyed instance. `hand_instances()` reports **actual drawn instance** occurrence, role, transform and visibility for tests/recording, not a parallel test projection. New generation/empty descriptor cancels stale hands/trails. P's fixed watchful puppet may remain. Configure synthetic test-owned textures/assembly in unit tests, not live local art.

The focused test author made the assembly keys concrete: `a_canvas`, `p_canvas`, `a_baseline`, `a_hinge`, `p_baseline`, `p_handle`, `held_hinge` are `Vector2`; `held_scale` and `height_fraction` are floats; `a_position` and `p_position` are normalized `Vector2` positions. Actual hand-instance rows contain `occurrence`, `role` (`rehearsal`, `transfer` or `held`), `transform: Transform2D` and `visible: bool`. These are compact study seams, not a production rigging format.

`res://tools/capture_motion_study.gd`, dedicated opt-in `SceneTree` entry:

- Instantiate the existing stage encounter and a controlled, one-shove fixture: P `[3,3]`, A `[3,2]` facing `[0,1]`, shove range 3 with push, empty storage, no walls/other enemies, enough health, exit away from the exchange. Values belong to the study fixture, not production tuning.
- Exercise real selection/assessment/confirmation and End Turn through existing UI/model boundaries. Compare each committed result with its actual assessment. No fabricated capture/announcement events or direct mutation of model internals.
- The existing Restart can replay/reset the study. Manual mode retains controls. Optional recording mode drives exactly this sequence, waits for shared finite feedback, records rehearsal/peel/travel/held/fresh+held, then exits with a verified summary.
- Validate required cutout files, hashes, dimensions and alpha before playing. Log attempt/outcome. Missing assets or failed loading exits clearly; normal startup never loads this tool or its local pack.

Replay command:

```sh
godot --path games/borrowed-turns --script res://tools/capture_motion_study.gd -- \
  --presentation=stage --study-assets="$PWD/.lore/local/experiments/002-shadow-paper/capture-motion"
```

For recording, also pass Godot's **`--fixed-fps 30` before `--`**, and `--record-dir=<fresh-absolute-local-or-temporary-directory>` after it. This fixes the whole scene's normal processing clock, not just the rig. The recorder verifies 1/30 process delta before creating output and on every saved frame. A preliminary real-time recording exposed synchronous PNG IO accelerating 30-fps playback; it is retained locally as superseded timing diagnostics, not a presentation candidate. No normal startup/default changes. Save exact frame counts and use an available encoder only. Manifests identify source/code/art hashes, fixture, generation, actual events, controller frames, scene deltas and actual hand instances. They are local evidence, not committed assets or documentation. Full run/record instructions: [study README](../../../../games/borrowed-turns/studies/capture_motion/README.md).

## Verification boundaries

Focused `tests/capture_motion_run.gd` was authored and neutral interfaces established before independent behavioral RED. No missing-script/import failure counts as RED. Its frozen source remains unchanged during implementation.

Use controlled snapshots/frames and injected synthetic textures/assembly for unit tests. Verify detached inputs/outputs; matching source and announcement/capture-turn identity; preview/failed/lethal acquisition never inventing transfer; no premature held duplicate while capture is queued/active; no duplicate visible hands for one occurrence; finite capture vs persistent loops; reset/stale-generation cancellation; and old-held/fresh-source coexistence. Reuse the existing controller and its test-owned fixtures for the few real-event boundaries. Do not clone the full C01–C03 mixed-effect suite or freeze artistic durations, colors, amplitudes and endpoints as game rules.

One isolated actual-scene integration path verifies source-asset load, model-assessment equality for capture and End Turn, interruption/replay, current-generation rig facts, unchanged authoritative footprints and normal renderer isolation. Fixture values are controlled, not mutable production content. Missing local inputs are setup errors, not behavioral RED.

The independent tester owns RED/GREEN and actual-consumer capture at 1024×720 plus a normal-size view, including normal game regression checks proportionate to the isolated boundary. Capture normal scene processing, not just the rig clock; inspect departure/mid-transfer/arrival/fresh+held stills and the actual clip. Fresh correctness/engineering review follows. No normal runtime acceptance is inferred from source preparation or technical passes.

Human review is one combined motion checkpoint: **can Ronald follow which action leaves A, recognize the same action arriving under P's control, retain the liked uncanny quality, and understand A's new rehearsal coexisting with the old held action?** This manually staged one-source pilot cannot establish an automatic director, general crowd handling, finished cast appeal or production feasibility. Stop after presenting actual motion rather than starting another asset/perfection loop.

## Delivered pilot and limits

Independent focused tests passed 94/0. The actual-scene fixed-30-fps recording completed at 1024×720: 237 frames, 730 checks/0 failures, 7.9 seconds, full decode successful. Real Capture and End Turn assessments match commits; old turn-1 held hands coexist with turn-2 rehearsal without duplicate visible instances for one occurrence. A separate actual Restart check restored the exact fixture, cleared stale held/trails and permitted capture again.

Fresh correctness review, a separate refactoring assessment and lightweight engineering-quality assessment found no material blocker or worthwhile pre-feedback refinement for this disposable study. No profiling claim is made. Normal-game paths and approved stage PNGs are unchanged. Physical input, native resize, HiDPI, general casting and production-art appeal are not established.

The replay instructions require the local temporary cutout pack; a fresh checkout alone cannot supply it. Recording and preparation outputs remain local. The actual clip was presented for Ronald's ownership judgment; technical verification does not supply that answer.

## Human checkpoint

Ronald selected **“Yes, direction is clear”** when asked whether the motion communicates the action being stolen and held well enough to continue, explicitly not as finished animation. This completes the pilot's communication checkpoint. It does not approve production artwork, a general director or further implementation. Leave the temporary study as-is rather than polishing it.
