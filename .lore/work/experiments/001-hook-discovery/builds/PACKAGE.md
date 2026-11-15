# Borrowed Turns source replay package

The first prototype is preserved at Git commit `fd8e91d`, not as a required archive. All 20 game files in its historical source manifest were verified byte-for-byte against that commit. Source is deterministic, without RNG or saved progression. The generated archive, manifests, logs and screenshot were moved to gitignored `.lore/local/experiments/001-hook-discovery/` if retained; they are local discussion evidence and are not required for a checkout or replay. This is a source project, not a compiled export.

- Historical local archive, if present: `.lore/local/experiments/001-hook-discovery/builds/borrowed-turns-source.tar.gz`
- Archive SHA-256: `83278bd8a4b0bb5a989818c9e63d858d67aae8da63cfc29d707b8896617d17ab`
- Source manifest SHA-256: `e8c06eed524ae21225d0c853065cb12ade2e80a839520a1ed9b38454a5fa8372`
- Engine: `/usr/bin/godot --version` returned `4.7.2.stable.arch_linux.ed1daf0bf`.
- Historical local manifests under `.lore/local/experiments/001-hook-discovery/builds/` and `evidence/` describe the package and copied evidence at that time. They are retained unmodified, so checks covering documentation edited during this relocation do not validate the current documentation as a set.

The former local archive used sorted paths, normalized mode 0644, owner/group 0, epoch mtime, USTAR and gzip without a timestamp. For replay without that local output, extract the verified commit into a new directory from the repository root:

```sh
replay="$(mktemp -d /tmp/opencode/borrowed-turns-first-replay.XXXXXX)"
git archive fd8e91d -- games/borrowed-turns .lore/work/experiments/001-hook-discovery/executable-rules.md | tar -x -C "$replay"
cd "$replay"
/usr/bin/godot --path games/borrowed-turns
/usr/bin/godot --path games/borrowed-turns -- --variant=V6 --invert
```

In this historical commit, V1–V6 are directly selectable, as is the former Invert preview; there is no grind or persistent progression. Godot and a graphical session are required for interactive play. See the extracted `games/borrowed-turns/README.md` for controls. This does not restore Ronald's prior experience or describe the current baseline.

## Recorded validation, not rerun during packaging

These commands and statuses were supplied from the independent tester's terminal results; local logs, when retained, are under `.lore/local/experiments/001-hook-discovery/evidence/`. The source diagnostic harnesses remain tracked under `.lore/work/experiments/001-hook-discovery/evidence/`. All commands below were run from the original repository root with the engine above. Test counts and exit status do not establish fun or original design.

| Stage | Command | Recorded result and scope |
| --- | --- | --- |
| Initial behavior-specific RED, before mechanics | `/usr/bin/godot --headless --path games/borrowed-turns --script /tmp/opencode/borrowed-turns-focused-red.gd` | Exit 1; three focused model assertion failures. The copied focused harness is provenance only and is not expected to fail against this corrected source. |
| Independent model | `/usr/bin/godot --headless --path games/borrowed-turns --script res://tests/run.gd` | Exit 0; 83 checks, 0 failures. This model evidence predates the later UI-only correction; model source was unchanged by that correction. |
| Direct launches | `/usr/bin/godot --headless --path games/borrowed-turns --quit-after 3 -- --variant=Vn --invert` for each `Vn` in V1–V6 | Each exit 0. These launch checks predate the later UI-only correction and were not rerun for packaging. |
| Invert regression RED, before UI correction | `/usr/bin/godot --headless --path games/borrowed-turns --script res://ui/smoke.gd` | Exit 1; 181 checks, two stale Preview-text assertions failed. |
| Corrected headless UI | `/usr/bin/godot --headless --path games/borrowed-turns --script res://ui/smoke.gd` | Exit 0; 181 checks, 0 failures. |
| Corrected rendered UI | `/usr/bin/godot --path games/borrowed-turns --script res://ui/smoke.gd -- --capture-dir=/tmp/opencode/borrowed-turns-corrected` | Exit 0; 201 checks, 0 failures. The screenshot, if retained, is local under `evidence/ui-v5-invert.png` within the local experiment directory. |
| Content diagnostic, final harness | `/usr/bin/godot --headless --path games/borrowed-turns --script /tmp/opencode/borrowed-turns-content-diagnostic.gd` | Exit 0; capture and no-capture traces retained. An earlier V5 harness route failed with exit 1 and was corrected as a harness issue, not a product defect. |

The diagnostic harness was copied to evidence; it imports only the production model and fixture, and supplies explicit strategy commands. Its recorded traces are diagnostics, not enjoyment evidence or a variant-exclusion decision. The corrected rendered run captures fixed-size Godot SubViewports; it does not establish native window-manager resize behavior, native OS pointer/keyboard acceptance, or HiDPI correctness. Independent engineering-quality review was pending when this package was assembled.
