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
