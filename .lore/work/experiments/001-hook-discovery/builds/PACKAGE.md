# Borrowed Turns source replay package

This is a source snapshot, not a compiled export or binary build. It preserves the directly runnable Godot project as it existed after the Invert preview correction, including all 20 source, scene, documentation and Godot `.uid` metadata files listed and hashed in `source-files.sha256`. The archive excludes `.godot` caches and editor transients; no generated binary, installed plugin or external service is included. `executable-rules.md` is a separately copied reference for the source documentation's contract link. Source is deterministic, without RNG or a saved progression state. The archive includes uncommitted files; its identity is the content hashes, not a Git commit.

- Archive: `borrowed-turns-source.tar.gz`
- Archive SHA-256: `83278bd8a4b0bb5a989818c9e63d858d67aae8da63cfc29d707b8896617d17ab`
- Source manifest SHA-256: `e8c06eed524ae21225d0c853065cb12ade2e80a839520a1ed9b38454a5fa8372`
- Engine: `/usr/bin/godot --version` returned `4.7.2.stable.arch_linux.ed1daf0bf`.
- `package.sha256` hashes the archive, source manifest and copied rules; `../evidence/evidence.sha256` hashes the copied evidence and diagnostic harnesses.

The archive uses sorted paths, normalized mode 0644, owner/group 0, epoch mtime, USTAR and gzip without a timestamp. Extract into an empty directory. From the repository root, for example:

```sh
mkdir -p /tmp/opencode/borrowed-turns-replay
tar -xzf .lore/work/experiments/001-hook-discovery/builds/borrowed-turns-source.tar.gz -C /tmp/opencode/borrowed-turns-replay
cd /tmp/opencode/borrowed-turns-replay
sha256sum -c /absolute/path/to/source-files.sha256
/usr/bin/godot --path games/borrowed-turns
/usr/bin/godot --path games/borrowed-turns -- --variant=V6 --invert
```

Replace the manifest placeholder with its actual absolute path. V1–V6 are directly selectable, as is the Invert preview; there is no grind or persistent progression. Godot and a graphical session are required for interactive play. See the archived `games/borrowed-turns/README.md` for controls. The separately copied rules reference is not inside the archive, so the relative documentation link to the experiment record does not resolve in an isolated extraction.

## Recorded validation, not rerun during packaging

These commands and statuses were supplied from the independent tester's terminal results; copied logs are in `../evidence/` and were compared byte-for-byte with their originals. All commands below were run from the original repository root with the engine above. Test counts and exit status do not establish fun or original design.

| Stage | Command | Recorded result and scope |
| --- | --- | --- |
| Initial behavior-specific RED, before mechanics | `/usr/bin/godot --headless --path games/borrowed-turns --script /tmp/opencode/borrowed-turns-focused-red.gd` | Exit 1; three focused model assertion failures. The copied focused harness is provenance only and is not expected to fail against this corrected source. |
| Independent model | `/usr/bin/godot --headless --path games/borrowed-turns --script res://tests/run.gd` | Exit 0; 83 checks, 0 failures. This model evidence predates the later UI-only correction; model source was unchanged by that correction. |
| Direct launches | `/usr/bin/godot --headless --path games/borrowed-turns --quit-after 3 -- --variant=Vn --invert` for each `Vn` in V1–V6 | Each exit 0. These launch checks predate the later UI-only correction and were not rerun for packaging. |
| Invert regression RED, before UI correction | `/usr/bin/godot --headless --path games/borrowed-turns --script res://ui/smoke.gd` | Exit 1; 181 checks, two stale Preview-text assertions failed. |
| Corrected headless UI | `/usr/bin/godot --headless --path games/borrowed-turns --script res://ui/smoke.gd` | Exit 0; 181 checks, 0 failures. |
| Corrected rendered UI | `/usr/bin/godot --path games/borrowed-turns --script res://ui/smoke.gd -- --capture-dir=/tmp/opencode/borrowed-turns-corrected` | Exit 0; 201 checks, 0 failures. `../evidence/ui-v5-invert.png` is copied from this rendered run. |
| Content diagnostic, final harness | `/usr/bin/godot --headless --path games/borrowed-turns --script /tmp/opencode/borrowed-turns-content-diagnostic.gd` | Exit 0; capture and no-capture traces retained. An earlier V5 harness route failed with exit 1 and was corrected as a harness issue, not a product defect. |

The diagnostic harness was copied to evidence; it imports only the production model and fixture, and supplies explicit strategy commands. Its recorded traces are diagnostics, not enjoyment evidence or a variant-exclusion decision. The corrected rendered run captures fixed-size Godot SubViewports; it does not establish native window-manager resize behavior, native OS pointer/keyboard acceptance, or HiDPI correctness. Independent engineering-quality review was pending when this package was assembled.
