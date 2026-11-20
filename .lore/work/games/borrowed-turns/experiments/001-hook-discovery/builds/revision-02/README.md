# Borrowed Turns revision 02: source replay package

The revision-02 source checkpoint is Git commit `009311b`, before Invert removal. Its 22 game files and four provenance documents were verified byte-for-byte against the historical source and input manifests. The generated archive, manifests, logs and screenshots were moved to gitignored `.lore/local/experiments/001-hook-discovery/` if retained; they are local discussion evidence, not checkout or replay requirements. The original input snapshots remain separately tracked. This is a source project, not a compiled export.

- Historical local archive, if present: `.lore/local/experiments/001-hook-discovery/builds/revision-02/borrowed-turns-r2-source.tar.gz`, 44,109 bytes.
- Archive SHA-256: `41bf019d551f2df6d5df17fc24476e7248fb3394905b630a137d56efbdf8c604`.
- Source-manifest SHA-256: `bebe67799d8f3cfc785c975c2da28ffe92b07fee16d6e77133055e3a08f02efe`.
- Input-manifest SHA-256: `7ecfe30df6538bb567eb6ec2461e48c0e40ad5e84b8438f8445e036dded61561`.
- Engine: `/usr/bin/godot --version` returned `4.7.2.stable.arch_linux.ed1daf0bf`.
- Historical local manifests under `.lore/local/experiments/001-hook-discovery/builds/revision-02/` and `evidence/revision-02/` describe the package and copied evidence at that time. They are retained unmodified, so checks covering documentation edited during this relocation do not validate the current documentation as a set.

The former local archive used sorted entries, USTAR, mode 0644, owner/group 0, epoch mtime and gzip without a timestamp. Godot `.godot` caches, editor transients and generated binaries were excluded. There are no installed plugins, external services or generated assets.

## Extract and run

From the repository root, save the path to the tracked diagnostic harnesses before entering a fresh extraction directory:

```sh
evidence="$(realpath .lore/work/games/borrowed-turns/experiments/001-hook-discovery/evidence/revision-02)"
replay="$(mktemp -d /tmp/opencode/borrowed-turns-r2-replay.XXXXXX)"
git archive 009311b -- games/borrowed-turns .lore/work/experiments/001-hook-discovery/design-revision-02.md .lore/work/experiments/001-hook-discovery/revision-02-executable-rules.md .lore/work/experiments/001-hook-discovery/revision-02-interface-brief.md .lore/work/intents/player-brief.md | tar -x -C "$replay"
cd "$replay"
/usr/bin/godot --path games/borrowed-turns
/usr/bin/godot --path games/borrowed-turns -- --invert
```

The game opens the single revised `R2` baseline. Invert is an optional directly accessible preview, not an unlock or progression tree. There are no V1–V6 launch modes in this source. Reset restores the fixture; there are no saves or RNG. A graphical session and Godot are needed for interactive play. See the archived game's README for controls. The two diagnostic harnesses are preserved unchanged outside the archive and import the extracted project's `res://` paths; from the extraction root they can be rerun without editing them:

```sh
/usr/bin/godot --headless --path games/borrowed-turns --script "$evidence/borrowed-turns-r2-independent-content.gd"
/usr/bin/godot --headless --path games/borrowed-turns --script "$evidence/borrowed-turns-r2-independent-axis.gd"
```

## Retained independent observations

These commands/statuses were supplied by the independent tester. They were **not rerun during packaging**; copied logs and harnesses were byte-identical to the `/tmp/opencode` originals. The logs and screenshots, if retained, are under `.lore/local/experiments/001-hook-discovery/evidence/revision-02/`; the two harnesses remain tracked under `.lore/work/games/borrowed-turns/experiments/001-hook-discovery/evidence/revision-02/`. Commands were run from the original repository root.

| Stage | Exact command | Recorded result |
| --- | --- | --- |
| Behavior-specific RED before revision implementation | `/usr/bin/godot --headless --path games/borrowed-turns --script res://tests/run.gd -- --focus=budget` | Exit 1; 5 checks, 3 expected behavior failures. The archived source is post-implementation and is not expected to reproduce this RED. |
| Model | `/usr/bin/godot --headless --path games/borrowed-turns --script res://tests/run.gd` | Exit 0; 282 checks, 0 failures. |
| Headless UI | `/usr/bin/godot --headless --path games/borrowed-turns --script res://ui/smoke.gd` | Exit 0; 176 checks, 0 failures. |
| Rendered UI | `/usr/bin/godot --path games/borrowed-turns --script res://ui/smoke.gd -- --capture-dir=/tmp/opencode/borrowed-turns-r2-independent` | Exit 0; 204 checks, 0 failures. |
| Startup | `/usr/bin/godot --headless --path games/borrowed-turns --quit-after 3` | Exit 0. |
| Startup with Invert | `/usr/bin/godot --headless --path games/borrowed-turns --quit-after 3 -- --invert` | Exit 0. |
| Content diagnostic | `/usr/bin/godot --headless --path games/borrowed-turns --script /tmp/opencode/borrowed-turns-r2-independent-content.gd` | Exit 0; no-capture escape on turn 12 at 3 HP; burst C, replace with A, release A, then escape at 1 HP. |
| Displacement convention | `/usr/bin/godot --headless --path games/borrowed-turns --script /tmp/opencode/borrowed-turns-r2-independent-axis.gd` | Exit 0; dominant-axis and horizontal-tie cases matched preview and commit. |

The retained rendered images include area replacement, deadline state, deadline end-turn, and lethal preview. They are fixed-size Godot SubViewport captures using injected events, not proof of physical OS input, native window-manager resize, or HiDPI behavior. Diagnostics do not establish balance, enjoyment, voluntary replay, or progression payoff. Independent refactoring/engineering-quality assessment was pending at packaging time.
