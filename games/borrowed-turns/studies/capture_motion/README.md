# One-source capture-motion study

An opt-in, disposable study, not the normal game or an automatic director. It uses the accepted stage, one controlled shove source, temporary cutouts and the existing model/UI/controller. No production character assets or new rules.

## Local inputs

The three cutouts are **not included in a fresh checkout**. Supply the authorized local pack:

```text
.lore/local/experiments/002-shadow-paper/capture-motion/
  a-body.png       290×145 RGBA
  a-hands.png      290×145 RGBA
  p-lantern.png    145×145 RGBA
```

The tool checks the exact source hashes recorded in the [study brief](../../../../.lore/work/design/borrowed-turns-art/capture-motion-study-brief.md), dimensions, decoding and actual partial alpha. Missing/mismatched inputs fail with exit 2, not replacement artwork. The original concept, extraction recipe and inspections remain local. Source stage PNGs are unchanged; normal Godot texture import is still required after a fresh checkout.

## Replay

From the repository root, with a graphical renderer:

```sh
godot --path games/borrowed-turns --script res://tools/capture_motion_study.gd -- \
  --presentation=stage \
  --study-assets="$PWD/.lore/local/experiments/002-shadow-paper/capture-motion"
```

Capture A at `[3,2]`, then Confirm. Watch the hands leave A and settle beside the lantern. End turn and Confirm to restore A's new announcement while the old hands remain held. Restart resets/replays this fixture. The next End turn would reach the real held deadline; it is not part of the demonstration.

The source's disappearance means one announcement was stolen, not death or permanent disarmament. Puppet positions are manually staged, not projected board bearings. Map figures/telegraphs remain the existing provisional presentation. Only this tool instance replaces the expressive board-shadow pass; returning to plain/paper restores its original renderer. Normal startup never loads study art.

## Record

Use a **fresh absolute output directory** and whole-engine fixed FPS:

```sh
godot --fixed-fps 30 --path games/borrowed-turns \
  --script res://tools/capture_motion_study.gd -- \
  --presentation=stage --study-size=1024x720 \
  --study-assets="$PWD/.lore/local/experiments/002-shadow-paper/capture-motion" \
  --record-dir=/tmp/opencode/borrowed-turns-capture-motion-fresh
```

`--fixed-fps 30` preserves normal scene/UI/controller processing with one shared clock while preventing synchronous PNG writes from advancing simulation time faster than the recorded frames. The tool checks the effective 1/30 scene delta before creating output and at every saved frame; Godot consumes engine flags, so user-argument inspection is not sufficient. Without fixed FPS, nominal 30-fps playback would speed up the transfer. Do not use the headless dummy renderer for capture.

Recording mode drives actual controls for Capture and End turn, verifies assessment/commit equality, saves numbered frames plus `final.png` and `manifest.json`, then exits. Success requires a clean log, `complete=true`, zero failures, a matching frame count, every numbered frame, the final still and the explicit completion summary. Exit 0 alone is not evidence. A finite recording watchdog guards incomplete runs.

The manifest records the controlled fixture, actual events/controller progress, current generation, actual hand-instance transforms/identities, scene delta, code/art hashes and frame count. Use that count when encoding the short recording with an already installed FFmpeg. Keep all output local; do not commit videos, frames or manifests.

## Focused validation

```sh
godot --headless --path games/borrowed-turns --script res://tests/capture_motion_run.gd
```

The focused suite uses synthetic textures and test-owned inputs, not local artwork. It does not establish visual appeal. Independent GREEN, capture verification and fresh review remain separate from author checks; Ronald judges actual motion.

The 145-pixel source figures have clipped lower bodies and provisional styling. The unchanged floor hides the source cuts; scaling can soften edges. The review question is action continuity and ownership with an uncanny glow, not final cast approval, general relevance selection or a production animation system.
