# Burst displacement axis regression: mind-garage-2nx

The controlled regression promotes the earlier revision-02 independent axis diagnostic into the current model suite. It characterizes already-correct production behavior: horizontal wins a tie, otherwise the dominant coordinate axis determines burst displacement. It uses a test-owned board and ability data, checks the affected actors' final positions and the nonmutating assessment/commit contract, and does not change the production model. The earlier diagnostic remains unchanged in `evidence/revision-02/`; its historical API is not live code. No RED result is claimed or manufactured for this characterization.

The independent tester reported both commands below from the repository root, using Godot `4.7.2.stable.arch_linux.ed1daf0bf`. The logs, if retained, are byte-for-byte under `.lore/local/experiments/001-hook-discovery/evidence/2nx/`; they are local discussion output, not checkout requirements. The relevant tracked source is at commit `ba3ab7a` and can be restored with `git archive ba3ab7a -- games/borrowed-turns | tar -x -C <empty-directory>`.

| Check | Command | Recorded result |
| --- | --- | --- |
| Focused | `/usr/bin/godot --headless --path games/borrowed-turns --script res://tests/run.gd -- --focus=burst-axis` | Exit 0; 14 checks, 0 failures. |
| Full model suite | `/usr/bin/godot --headless --path games/borrowed-turns --script res://tests/run.gd` | Exit 0; 285 checks, 0 failures. |

The local `source-files.sha256`, if retained, identifies only the test runner and its `TESTING.md` instructions at packaging; its SHA-256 is `e1c3b67847078da03b4de16cc6869e523810d3088c4fdd6ac98388aae227772a`. The historical local `evidence.sha256` describes the original README, source manifest and copied logs; it does not validate this subsequently edited README. This is not a source archive or compiled build. The checks establish the specified displacement behavior, not balance or enjoyment.
