# Rendered-smoke completion gate evidence: mind-garage-84b

The independent tester's logs, terminal capture and generated manifests are local discussion output under `.lore/local/experiments/001-hook-discovery/evidence/84b/`, if retained; a checkout does not depend on them. The historical local `source-files.sha256` identifies only the gate, its two controlled subprocess-test files, and `games/borrowed-turns/TESTING.md` as they existed at packaging. Its SHA-256 is `1181d1d8b594f1e5242d3275be6d7db3c24685567e86eb96007842748bc2c634`. The four files match tracked commit `29cd5ef`, reproducible with `git archive 29cd5ef -- games/borrowed-turns | tar -x -C <empty-directory>`. The unmodified local `evidence.sha256` describes the original README, manifest, logs and capture, not this subsequently edited README. This is not a source archive or compiled game build.

Commands below were run by the independent tester from the repository root, not rerun while packaging:

| Stage | Command | Recorded result |
| --- | --- | --- |
| Behavior-specific RED against the callable scaffold | `python3 -m unittest discover -s games/borrowed-turns/tests -p 'test_rendered_smoke_gate.py' -v` | Exit 1; 6 tests with 9 assertion failures. The completed control, signal and timeout checks passed. |
| Gate GREEN | `python3 -m unittest discover -s games/borrowed-turns/tests -p 'test_rendered_smoke_gate.py' -v` | Exit 0; 6 tests passed. |
| Actual rendered smoke through the gate | `python3 games/borrowed-turns/tools/rendered_smoke_gate.py --capture-dir /tmp/opencode/borrowed-turns-84b-real --timeout 90` | Exit 0; fresh output directory, child summary 179 checks and 0 failures, and accepted terminal PNG. |

The local `r2-escaped.png`, if retained, is the exact terminal capture from that run, identified as a 1280 × 800 PNG. The rendered harness uses Godot SubViewports and injected events; this does not establish native physical input, compositor-native resize or HiDPI behavior. The earlier incomplete exit-zero runs remain recorded in the [no-Invert notes](../no-invert/README.md): their cause remains unknown, and this gate does not claim to have solved or diagnosed it. The gate instead rejects an incomplete run without the required completion evidence. This package makes no gameplay, balance or enjoyment claim.
