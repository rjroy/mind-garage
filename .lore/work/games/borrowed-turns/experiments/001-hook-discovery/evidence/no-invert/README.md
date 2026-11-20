# Invert removal: retained evidence

The independently recorded logs, three screenshots and generated manifests are local discussion output under `.lore/local/experiments/001-hook-discovery/evidence/no-invert/`, if retained; a checkout does not depend on them. The guarded rendering wrapper remains tracked alongside this document. These observations document the focused removal of Invert, not a new game-design or enjoyment result. The historical local `source-files.sha256` identifies the then-current 22 game files, including source, tests, documentation, scenes and `.uid` metadata. Its SHA-256 is `9296984405808cedbf052777769b4e987b71e293a984b3ef0b4cafaa128b21c8`. All 22 files match tracked commit `66f90e8`; no source archive or compiled export is required. The unmodified local `evidence.sha256` describes the original README, source manifest and evidence files, not this subsequently edited README.

Engine recorded in the logs: `4.7.2.stable.arch_linux.ed1daf0bf`. Commands and exit statuses below are independent tester reports. Packaging did not rerun tests. Commands were run from the repository root. The two behavior-specific RED runs preceded the removal; the then-current tests used the old three-argument configure API. They are historical observations, not expected results for the current source.

| Evidence | Exact command | Recorded status |
| --- | --- | --- |
| Model RED | `/usr/bin/godot --headless --path games/borrowed-turns --script res://tests/run.gd -- --focus=no-invert` | Exit 1; 23 checks, 4 failures. |
| UI RED | `/usr/bin/godot --headless --path games/borrowed-turns --script res://ui/smoke.gd -- --focus=no-invert` | Exit 1; 21 checks, 3 failures. |
| Model GREEN | `/usr/bin/godot --headless --path games/borrowed-turns --script res://tests/run.gd` | Exit 0; 271 checks, 0 failures. |
| Headless UI GREEN | `/usr/bin/godot --headless --path games/borrowed-turns --script res://ui/smoke.gd` | Exit 0; 153 checks, 0 failures. |
| Normal startup | `/usr/bin/godot --headless --path games/borrowed-turns --quit-after 3` | Exit 0. |
| Retired option | `/usr/bin/godot --headless --path games/borrowed-turns --quit-after 3 -- --invert` | Exit 2; explicit unsupported-option error. |

## Rendered observations

Two earlier foreground runs reported process exit 0 but **did not complete the smoke harness**: neither produced the final summary or `r2-escaped.png`. Their logs remain as inconclusive observations, not passes. The cause of their early termination is unknown. Both used a 120,000 ms foreground command timeout, with shell pipeline status preserved:

```sh
set -o pipefail; /usr/bin/godot --path games/borrowed-turns --script res://ui/smoke.gd -- --capture-dir=/tmp/opencode/borrowed-turns-no-invert-rendered 2>&1 | tee /tmp/opencode/borrowed-turns-no-invert-rendered-green.log; exit "${PIPESTATUS[0]}"
set -o pipefail; /usr/bin/godot --path games/borrowed-turns --script res://ui/smoke.gd -- --capture-dir=/tmp/opencode/borrowed-turns-no-invert-rendered-recheck 2>&1 | tee /tmp/opencode/borrowed-turns-no-invert-rendered-recheck.log; exit "${PIPESTATUS[0]}"
```

A subsequent guarded foreground run completed, again with a 120,000 ms command timeout and pipeline status preserved:

```sh
set -o pipefail; /usr/bin/godot --path games/borrowed-turns --script /tmp/opencode/borrowed-turns-no-invert-window-diagnostic.gd -- --capture-dir=/tmp/opencode/borrowed-turns-no-invert-window-diagnostic 2>&1 | tee /tmp/opencode/borrowed-turns-no-invert-window-diagnostic.log; exit "${PIPESTATUS[0]}"
```

Recorded exit 0, 179 checks, 0 failures, final summary and `r2-escaped.png`. The unchanged copied wrapper extends `res://ui/smoke.gd`; it sets `auto_accept_quit = false`, observes window-close notifications/signals and adds a 90-second watchdog. It does not change smoke expectations. The run reported X11 and did not log a close request or watchdog firing. That observation does **not** establish why the previous runs stopped early. The retained guarded captures are `r2-1280-start.png`, `r2-normal-shove.png`, and `r2-escaped.png`.

To repeat the guarded run, extract `66f90e8` into an empty directory with `git archive 66f90e8 -- games/borrowed-turns | tar -x -C <empty-directory>`, then substitute the absolute path to the tracked `.lore/work/games/borrowed-turns/experiments/001-hook-discovery/evidence/no-invert/borrowed-turns-no-invert-window-diagnostic.gd` wrapper and a fresh output directory in the command above. The historical local source manifest can check that extracted snapshot if present. Historical first-build and revision-02 source commits and notes remain separate.

Screenshots are rendered Godot SubViewports and smoke uses injected events. They do not establish physical OS input, native compositor resize or HiDPI behavior. Correctness and lightweight engineering-quality reviews accepted this removal; no refactor was requested. The nonblocking incomplete-run detection concern remains separate future harness work. This evidence makes no balance, fun, replay or progression claim.
