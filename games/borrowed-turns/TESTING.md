# Borrowed Turns checks

Deterministic checks exercise the real `res://model/encounter.gd` with controlled, test-owned fixtures. They do not assert production tuning, enjoyment or novelty. Current rules and executed evidence are recorded in [experiment 003](../../.lore/work/experiments/003-active-opponents/record.md). Historical revision-02 contracts are not current requirements or another supported rules engine.

From repository root, with Godot 4.7.2 installed:

```sh
/usr/bin/godot --headless --path games/borrowed-turns --script res://tests/run.gd
```

The runner prints check/failure counts and exits 1 on assertion failures. A parse/import error, crash or invalid fixture is not behavior-specific RED. The independent tester owns RED/GREEN execution. Focus the armed-Capture/Shine contract with:

```sh
/usr/bin/godot --headless --path games/borrowed-turns --script res://tests/run.gd -- --focus=armed-capture-shine
```

The model helper checks nonmutating assessment and exact preview-to-commit equality for successfully exercised commands. Invalid commands check rejection and complete atomicity. The full suite also covers armed/held/terminal reset, movement and aim policies, defeat-all victory, geometry, push and source-linked storage.

The candidate pays AP to arm, takes an enemy attack's complete normal effects before acquisition, permits repeated Shine without consuming storage, and loses the held ability when its source dies. Old free acquisition, threat-free adjacency, attack cancellation, expiry and backlash assertions are superseded. UI consumers must use model-authored events/cells, not recompute combat.

The Switcher extension has its own focused model check:

```sh
godot --headless --path games/borrowed-turns --script res://tests/run.gd -- --focus=switcher
godot --headless --path games/borrowed-turns --script res://ui/smoke.gd -- --focus=switcher
```

It protects fixed-cell targeting, singleton masks, atomic exchange before damage/acquisition, invalid Shine targets, repeat use/source death and later independent attacks. Drawing checks must observe actual `_draw()` mask/ray dispatch as well as helper results; a correct returned footprint does not prove the preview consumer draws it.

Invert and the plain/paper display modes are removed. Preserve rejection coverage where applicable, not parallel compatibility paths.

The controlled push-axis regression runs independently with:

```sh
/usr/bin/godot --headless --path games/borrowed-turns --script res://tests/run.gd -- --focus=burst-axis
```

It checks the horizontal tie and dominant horizontal/vertical destinations, plus nonmutating assessment and preview-to-commit equality. The regular model command above also runs this regression. These test-owned positions and ability values do not constrain production tuning.

## Presentation integration

Use the existing headless runners for finite controller order, detached two-source performance, actual drawing commands and scene controls:

```sh
godot --headless --path games/borrowed-turns --script res://tests/shadow_presentation_run.gd
godot --headless --path games/borrowed-turns --script res://tests/two_pursuer_presentation_run.gd
godot --headless --path games/borrowed-turns --script res://tests/shadow_rendering_run.gd
godot --headless --path games/borrowed-turns --script res://tests/board_warning_run.gd
godot --headless --path games/borrowed-turns --script res://ui/smoke.gd -- --focus=armed-capture-shine
```

Important boundaries include full strike/damage/push before acquisition, independent subsequent attacks, persistent/replaced held ownership, repeated Shine, source-loss clearing, generation cancellation and ordered slides. Rendering checks observe actual arrow/tile calls and preserve selected endpoints for narrow, wide and wall-clipped abilities.

The migrated complete scene and board-integration checks run with:

```sh
godot --headless --path games/borrowed-turns --script res://ui/smoke.gd
godot --headless --path games/borrowed-turns --script res://ui/board_comparison_smoke.gd
```

The board-comparison name is historical; it protects Stage geometry, controls and ownership, not a choice of display modes. Reuse unchanged art/projection evidence unless those algorithms or inputs change. A default-content replay demonstrates one complete feasible fight but cannot establish enjoyable decisions or unavoidable damage.

## Evidence boundaries

Current verification does not authorize screenshots, recordings, editor-driven captures or compositor troubleshooting. Older rendered-gate procedures belong to their original checkpoints; a headless pass is not a rendered or physical-input pass. Logs, snapshots and generated manifests stay under ignored `.lore/local/verification/`, never committed or required at runtime. Record exact commands, exits and relevant findings in the experiment record; Ronald's live play supplies the human judgment.
