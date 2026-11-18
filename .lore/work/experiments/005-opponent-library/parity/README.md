# Historical mechanical parity

From the repository root, run:

```sh
sh .lore/work/experiments/005-opponent-library/parity/run.sh
```

Requires Git with baseline commit `6def00f9027cfc481ac2840abc376fbb07dea146`
available locally, Godot 4.7.2 (`godot`), Python 3, tar, and sha256sum.
The command archives the baseline, copies the current candidate game working
tree (including untracked source, excluding `.godot`), and works entirely in a
new temporary directory. It prints that directory, which retains outputs, logs,
and a candidate source manifest. `TMPDIR` can select its parent. It does not
modify the checkout.

The frozen baseline alone deterministically generates the action corpus for the
three surviving controls. The candidate registry adapter supplies the real
registered fixtures, without reconstructing them. The comparator checks every
projected row. Corpus and frozen replay fingerprints verify the exact shared
historical actions and projections, respectively. These canonical JSON hashes were
derived by removing escape from the original corpus and replay after verifying
their original SHA256 fingerprints (`384d5ea698955064041239152094012ac39dc2b30780784bcbf9df296b85aa47`
for the corpus file and `d0e6143fa193cb8eb92eae3d2839afc1014fe72e02f40ab6c4dfbb7bfc65fd88`
for the replay). No escape episode is generated or replayed by this recipe.
Any failed check, Godot error, or comparison difference returns nonzero.

The original four-control measurement was 511 generation checks, 13 episodes,
476 rows and 1,562 replay checks per side, including five escape episodes and
155 escape rows. It remains historical evidence, not a requirement for the
current candidate. The current recipe runs 380 generation checks and compares
eight episodes and 321 rows with 1,058 replay checks per side: two-pursuers has
3 episodes and 140 rows, switcher 2 and 48, switcher-b 3 and 133. Each includes
wins and losses, captures and Shine; switcher-b includes both capture orders.
Replay checks assess
purity, assess/act agreement, exact preview, rejection atomicity and explanation,
and exact reset.

The projection includes board, rules, state, enemy mechanics, intentions and
historical semantic events, but excludes new metadata, presentation-only kind,
movement representation, and exact rejection wording. Omitted ability width and
width 1 are equivalent. Unknown new events remain visible. This finite replay
does not test all states, new opponents or metadata contracts, presentation, input,
or enjoyment. Its historical fingerprint is an evidence check, not a permanent
unit-test expectation for future tuning.
