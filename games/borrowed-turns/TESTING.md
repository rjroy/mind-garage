# Borrowed Turns revision 02 model checks

These deterministic checks exercise the real `res://model/encounter.gd` with test-owned fixtures and data-owned ability parameters. They do not assert production board tuning, enjoyment, or novelty. The [revision 02 executable contract](../../.lore/work/experiments/001-hook-discovery/revision-02-executable-rules.md) defines this suite. The original six-variant source, executable rules and results remain in their historical package; this suite replaces superseded assertions instead of maintaining a second live rules engine.

From repository root, with Godot 4.7.2 installed:

```sh
/usr/bin/godot --headless --path games/borrowed-turns --script res://tests/run.gd
```

The runner prints the check and failure counts and exits 1 on assertion failures. A parse error, import error, crash, or setup failure is not a behavior-specific RED. The independent tester owns RED and GREEN validation. Before the model revision is implemented, a focused check can demonstrate the changed explicit turn and budget behavior without depending on unimplemented new snapshot fields or an alternate test model:

```sh
/usr/bin/godot --headless --path games/borrowed-turns --script res://tests/run.gd -- --focus=budget
```

Expected old-model RED: successful movement advances the old turn and has no revised AP/MP fields, failing `movement does not advance turn`, `movement spends only one MP`, and `enemy does not resolve on movement`. If there is a parse/import/runtime error instead, report it separately; do not count it as the requested RED. Once implemented, both commands must exit 0. The test runner's `apply` helper checks nonmutating assessment and exact preview-to-commit equality for every successfully exercised command; invalid commands check reason and complete atomicity.

The suite covers four movement points interleaved with free capture and same-turn AP release; unlimited distinct capture occurrences and refresh; area replacement, stronger damage, source death/displacement and lethal outcomes; exact two-turn release/expiry boundary; range, LOS, budgets and no discard; complete lethal intentions/backlash footprints; ordered enemy turns; reset, isolation, normal shove, and rejection of removed inversion command fields. Each scenario uses controlled test data. The UI must consume model intentions, `backlash_footprint` and assessed event footprints, including a legal lethal replacement, rather than recomputing geometry. Native UI behavior and actual human enjoyment require separate validation.

Invert was explicitly removed from the live baseline. Focused removal regressions run with `-- --focus=no-invert` on either the model test runner or UI smoke runner. Historical builds and evidence may still contain the earlier optional feature; they are not current requirements.

The controlled burst-push axis regression, promoted from the retained revision-02 diagnostic, runs independently with:

```sh
/usr/bin/godot --headless --path games/borrowed-turns --script res://tests/run.gd -- --focus=burst-axis
```

It checks the horizontal tie and dominant horizontal/vertical destinations, plus nonmutating assessment and preview-to-commit equality. The regular model command above also runs this regression. These test-owned positions and ability values do not constrain production tuning.

## Rendered smoke completion gate

The two earlier rendered runs recorded in `evidence/no-invert/README.md` exited 0 without a full summary or terminal capture. Their cause is unknown; they are not passes. The gate below protects automation without changing normal game window-close behavior or requiring desktop changes.

The intended CLI is `games/borrowed-turns/tools/rendered_smoke_gate.py`, run with Python 3 standard library only. Required `--capture-dir` names a **new, nonexistent** directory; reject an existing path before launching rather than accepting stale images. Optional `--godot` defaults to `/usr/bin/godot`; optional `--timeout` is a positive number of seconds, default 120. The gate creates the fresh directory, invokes the actual project runner with `--path <absolute-game-root> --script res://ui/smoke.gd -- --capture-dir=<absolute-new-dir>`, captures and forwards combined stdout/stderr, and terminates/reaps the child on timeout. Do not forward a focused smoke flag: this gate accepts the full rendered run only.

Exit 0 is permitted only when the child itself exits 0 within the timeout, its output includes exactly one whole-line full-run summary of the form `R2 UI smoke: N checks, 0 failures. Injected GUI events, not physical OS input.` with positive integer N, and that new run produced a nonempty `r2-escaped.png` with the PNG file signature. Reject missing, malformed or embedded summaries, zero checks, missing or non-PNG terminal capture, output lines beginning `ERROR:` or `SCRIPT ERROR:`, nonzero or signal termination, and timeout. Rejections exit nonzero and explain why. Checking the caller-selected new directory avoids stale output; no persistent marker or nonce is needed. A pre-existing output path must remain untouched.

Once implemented, run a full rendered check from the repository root with a unique path that does not yet exist:

```sh
python3 games/borrowed-turns/tools/rendered_smoke_gate.py --capture-dir /tmp/opencode/borrowed-turns-rendered-unique
```

The test-owned fake executable in `tests/fake_smoke_process.py` supplies controlled subprocess outcomes and is not a game implementation. `tests/test_rendered_smoke_gate.py` drives the actual gate CLI, checking successful completion, clean early exit, stale/missing/corrupt screenshots, nonzero assertions, malformed/fake summaries, runtime errors, signal interruption and timeout. It uses test-owned temporary inputs and no production level data. Run the focused tests with:

```sh
python3 -m unittest discover -s games/borrowed-turns/tests -p 'test_rendered_smoke_gate.py' -v
```

During test-first development a separate setup invocation created a callable pass-through CLI before RED execution. The completed-child control passed while missing acceptance checks failed as assertions; missing files or imports were not treated as RED. The gate then gained its completion checks without weakening tests. Independent execution owns the resulting RED/GREEN and real rendered integration evidence, recorded in the experiment record rather than inferred from this contract.
