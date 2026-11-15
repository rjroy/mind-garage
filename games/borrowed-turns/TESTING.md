# Borrowed Turns model checks

These are deterministic, test-owned unit fixtures for the real game model, not a second implementation or tests of production board tuning. The executable rule and API contract is [executable-rules.md](../../.lore/work/experiments/001-hook-discovery/executable-rules.md). `tests/fixtures.gd` owns the board data; `tests/run.gd` instantiates the production model directly and exits nonzero on assertion failures. Assertions cover legal and invalid actions, preview purity/equivalence, cancellation and release geometry, all six bargains, Invert, outcomes and reset/isolation. They do not establish enjoyment or substitute for a human UI playtest.

## Prerequisites and command

Godot 4.7.2 stable is installed at `/usr/bin/godot`. Before this suite can be run, the separate implementation owner must add `games/borrowed-turns/project.godot` and a loadable `games/borrowed-turns/model/encounter.gd` conforming to the contract. The project root must resolve `res://tests` and `res://model` inside `games/borrowed-turns`. Model scaffolding can expose unimplemented methods for the independent tester's behavior-specific RED check; a missing import, parse error or failure to start is a setup failure, not a meaningful RED result.

From repository root, after prerequisites exist:

```sh
/usr/bin/godot --headless --path games/borrowed-turns --script res://tests/run.gd
```

The runner prints individual failures and a check/failure count; exit 0 means all assertions passed, exit 1 means at least one assertion failed. Godot may return another nonzero status for startup, parse or runtime errors; treat those separately, never as passing checks. The independent validation owner records command, output and exit status for RED and GREEN. No production-level board values are asserted here.

## Boundary

`assess` is deliberately the same contract the UI uses for action legality, rejection reasons and exact prospective state/events. `act` performs that action on the same model. An assessment must not mutate the model, and its predicted snapshot must equal the subsequent result if no intervening action occurs. Current snapshot `intentions` supplies complete announced rays even when an earlier enemy could end the run; `ray` events show only rays that actually resolve. Effects, cancellation, terminal status and turn order come from model events. Interface code must not implement alternative geometry or decisions. V2 approach/capture and V6 target commitment/capture are atomic commands.

This suite cannot be executed as a behavioral test before the project and model exist. The independent tester owns actual RED/GREEN validation; this author does not claim RED from absent files. Additional gameplay/UI integration, manual input, session evidence and telemetry consent remain outside this test runner.

The provisional production encounter is unbalanced and untested. Static rays could permit a simple escape without meaningful capture. Separately diagnose the actual production encounter with controlled no-capture versus capture strategies and retain the traces; this is a content and decision-opportunity diagnostic, not a permanent tuning constant for these unit fixtures or grounds by itself to exclude a variant or infer enjoyment.
