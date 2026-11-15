# Rendered-smoke completion gate evidence: mind-garage-84b

These files preserve the independent tester's logs and terminal capture for the completion gate. `source-files.sha256` identifies only the gate, its two controlled subprocess-test files, and `games/borrowed-turns/TESTING.md` as they existed at packaging. Its SHA-256 is `1181d1d8b594f1e5242d3275be6d7db3c24685567e86eb96007842748bc2c634`. This is an identity manifest, not a source archive or compiled game build. `evidence.sha256` covers this README, the manifest, logs and capture.

Commands below were run by the independent tester from the repository root, not rerun while packaging:

| Stage | Command | Recorded result |
| --- | --- | --- |
| Behavior-specific RED against the callable scaffold | `python3 -m unittest discover -s games/borrowed-turns/tests -p 'test_rendered_smoke_gate.py' -v` | Exit 1; 6 tests with 9 assertion failures. The completed control, signal and timeout checks passed. |
| Gate GREEN | `python3 -m unittest discover -s games/borrowed-turns/tests -p 'test_rendered_smoke_gate.py' -v` | Exit 0; 6 tests passed. |
| Actual rendered smoke through the gate | `python3 games/borrowed-turns/tools/rendered_smoke_gate.py --capture-dir /tmp/opencode/borrowed-turns-84b-real --timeout 90` | Exit 0; fresh output directory, child summary 179 checks and 0 failures, and accepted terminal PNG. |

`r2-escaped.png` is the exact terminal capture from that run, identified as a 1280 × 800 PNG. The rendered harness uses Godot SubViewports and injected events; this does not establish native physical input, compositor-native resize or HiDPI behavior. The earlier incomplete exit-zero runs remain recorded separately under `evidence/no-invert/`: their cause remains unknown, and this gate does not claim to have solved or diagnosed it. The gate instead rejects an incomplete run without the required completion evidence. This package makes no gameplay, balance or enjoyment claim.
