---
title: Borrowed Turns tactical choice audit
date: 2026-11-17
status: draft
tags: [borrowed-turns, tactical-decisions, capture-shine, encounter-design]
related: [.lore/work/research/borrowed-turns-tactics-puzzles-and-time.md, .lore/work/experiments/005-opponent-library/record.md, .lore/work/experiments/004-switcher/record.md]
---

# Borrowed Turns tactical choice audit

## Key findings

- **The first hit is an entry fee for a win in these encounters, but which hits to take need not be routine.** With no held ability, the player has no attack. Enemies can hurt each other, but none can hurt itself and the last living enemy cannot be killed that way. A capture therefore requires surviving at least one damaging hit. Anchor makes the mandatory hit almost the entire opening. Circler makes *where* to take it consequential. Switcher + B makes a **second** hit optional and shows what you can get for either paying it or declining it.
- **The strongest counterexample is Switcher + B.** From the same mid-fight board, keeping Swap turns both enemies’ warnings against each other and wins on turn 8 at 7 HP without another hit or capture. Killing the Swap source to acquire Wide Shove, or choosing to replace Swap while its source lives, also wins on turn 8 in the verified routes, but at 6 HP. Replacement buys a real two-target cast, not a better measured finish here.
- **Recommendation: test encounter composition first, not a Capture/Shine rewrite.** Keep Anchor as the low-choice control. Use a short, unfamiliar paired position where the player can see the source-preservation versus replacement opportunity within one enemy phase. The mechanical opportunity exists; whether Ronald finds it worth choosing or wants more is unknown.

## Scope and notation

`mind-garage-u1z`, committed `df36cd69b1a5230abb9a3053e26c91b4cf7227b4`, Godot `4.7.2.stable.arch_linux.ed1daf0bf`. These are three reachable positions in unmodified shipped encounters, not hand-edited fixtures. Each is a wall-free 7×7 **defeat-all** board, with no RNG or seed input. Each branch starts from a fresh reset and replays the same prefix. `[x,y]` is zero-based, right/down. `M2,3` means Move to `[2,3]`, `S2,3` means Shine targeting `[2,3]`, `C` is Capture, and `E` is End Turn. Each non-`E` command spends one AP; `E` is free and surviving active turns refresh to 3 AP. State notation `T2/3` means turn 2 with 3 AP; `[x,y]:HP` gives cell and health. `—` means no enemy or no held ability, as appropriate. Capture is unarmed at the listed snapshots unless stated otherwise.

Relevant implementation: the [catalog](../../../games/borrowed-turns/content/encounters.gd), [solo definitions](../../../games/borrowed-turns/content/opponents.gd), [paired fixture](../../../games/borrowed-turns/content/switcher_b.gd), and [model](../../../games/borrowed-turns/model/encounter.gd) (`_shine`, `_end_turn`, `_resolve_swap`, `_resolve_ability`, `_finish_ability`). `E` resolves A before B, then moves and re-aims the survivors. Swap locks a **cell**, not its original occupant; a shove keeps its direction until the enemy re-aims, but its footprint moves with its source. Arming does not discard the previous ability; the next surviving hit replaces it. Killing the source clears it, after the killing effect finishes.

## 1. Anchor: pay now, dodge, or waste the hit

**Snapshot:** Select `anchor`; no setup commands. `T1/3`, P `[2,3]:10`, A `[5,3]:4`, held `—`. A is stationary. The announced 2-damage Burst covers `[2,2]`, `[1,3]`, `[2,3]`, `[3,3]`, `[2,4]`.

| Plan | Continuation from snapshot | Turning point | Finish |
| --- | --- | --- | --- |
| Arm for the first hit | `C E S4,3 S4,3` | First `E`: `T2/3`, P `[2,3]:8`, A `[5,3]:4`, A/Burst held. First Shine leaves A at 2 HP (2 AP). | `T2/1`, P `[2,3]:8`, A `—`, held `—`, won. |
| Delay in safety | `M1,3 M1,2 E M2,2 M2,3 C E S4,3 S4,3` | First `E`: `T2/3`, P `[1,2]:10`, A `[5,3]:4`, held `—`. Second `E`: `T3/3`, same playable position/HP/ability as immediate capture after its first `E`. | `T3/1`, P `[2,3]:8`, A `—`, held `—`, won. |
| Delay in the blast | `E C E S4,3 S4,3` | First `E`: `T2/3`, P `[2,3]:8`, A `[5,3]:4`, held `—`. Second `E`: `T3/3`, same board and ability as immediate capture, but P has 6 HP. | `T3/1`, P `[2,3]:6`, A `—`, held `—`, won. |

One step from the starting tile does **not** escape the Burst; two do. Dodging is real defense for that phase, but it buys no progress in the tested detour. `S4,3` is a legal centre two cells away; its splash reaches A at `[5,3]`. The immediate route attains both bounds from this start: it cannot win before the first `E`, and every victory must lose at least 2 HP to acquire this sole attack. This does not make it the unique optimal input sequence. Here timing the initial injury is not a trade-off under a finish-sooner/keep-HP goal.

## 2. Circler: one step before the same hit changes the next turn

**Snapshot:** Select `circler`; no setup commands. `T1/3`, P `[2,3]:10`, A `[4,3]:4`, held `—`. Announced 1-damage Wide Shove covers columns 2–3, rows 2–4. All three branches acquire the **same** ability for **1 HP**; compare their first usable boards.

| Plan | Continuation from snapshot | Turning point | Finish |
| --- | --- | --- | --- |
| Take the hit off-axis | `C M2,2 E M2,2 S2,3 S4,2 E M3,2 S3,3 S5,2` | First `E`: `T2/3`, P `[1,2]:9`, A `[3,3]:4`, A/Wide Shove held. | `T3/0`, P `[3,2]:9`, A `—`, held `—`, won. |
| Take the hit in place | `C E M1,2 E M2,2 S2,3 S4,2 E M3,2 S3,3 S5,2` | First `E`: `T2/3`, P `[1,3]:9`, A `[4,3]:4`, A/Wide Shove held. `M1,2 E` reaches the off-axis board one turn later without another hit. | `T4/0`, P `[3,2]:9`, A `—`, held `—`, won. |
| Dodge first, then acquire | `M1,3 E M2,3 C M2,2 E M2,2 S2,3 S4,2 E M3,2 S3,3 S5,2` | First `E`: `T2/3`, P `[1,3]:10`, A `[4,3]:4`, held `—`. Second `E` reaches the off-axis acquisition board one turn late. | `T4/0`, P `[3,2]:9`, A `—`, held `—`, won. |

The off-axis hit leads to a different Circler movement after the shove, leaving A one cell closer. The first two Shines hit through the side lane, pushing A to `[5,3]:2`; this shifts its west-facing threat off P `[2,2]:9` before `E`. After that `E` A is at `[4,3]:2` again, `T3/3`. The direct and delayed routes eventually use the same two-turn finish: their first-phase decisions change **when** it becomes available, not the finishing tactic. The off-axis route reaches the earliest possible turn and highest possible HP: getting the weapon costs at least 1 HP, and four 1-damage hits cannot fit in its first 3-AP turn. The no-movement opening cannot match that pace (no turn-3 win after `C E` in the bounded scan below). This is positioning layered on top of a mandatory fee, not evidence of two equally good plans or a way to win without capturing.

## 3. Switcher + B: preserve Swap, kill its source, or buy a replacement

**Setup** for `switcher-b`, from P `[0,3]:8`, A `[6,0]:5`, B `[6,6]:5`, held `—`:

```text
M1,3 M2,3 M3,3 E M4,3 M5,3 M5,2 E C E S5,2 S5,1 S5,2 E
```

On turn 3 the first capture takes 1 HP and obtains Swap. On turn 4 the three Shines bring A to 2 HP; the last exchange leaves the old lock on A’s own cell, so its attack cannot hit itself.

**Common snapshot:** `T5/3`, P `[5,2]:7`, A `[5,1]:2`, B `[4,4]:5`, A/Swap held (captured on turn 3). A locks `[5,2]`. B’s north-facing Wide Shove covers columns 3–5, rows 2–3. Both warnings cover P now, but the player’s final cell **and** the order of the attacks decide who is hit.

| Plan | Continuation from snapshot | After first `E` | Finish |
| --- | --- | --- | --- |
| **Keep Swap; defeat B first** | `M4,2 S4,4 E M4,3 M4,2 E S2,2 S4,2 S2,2 E S3,2` | `T6/3`, P `[4,4]:7`, A `[5,1]:1`, B `[3,2]:4`, A/Swap held. | `T8/2`, P `[3,2]:7`, A/B `—`, held `—`, won. |
| **Kill A immediately; acquire B** | `S5,1 S5,2 C E M5,2 S4,2 S3,2 E M4,2 S3,2 S2,2 E S2,2` | `T6/3`, P `[5,1]:6`, A `—`, B `[4,3]:5`, B/Wide Shove held. | `T8/2`, P `[4,2]:6`, A/B `—`, held `—`, won. |
| **Replace Swap while A lives** | `C M5,3 E S4,3 E M5,3 S4,3 S3,3 E M4,3 S3,3 S2,3` | `T6/3`, P `[6,3]:6`, A `[5,2]:2`, B `[4,4]:5`, B/Wide Shove held. | `T8/0`, P `[4,3]:6`, A/B `—`, held `—`, won. |

- **Keep:** `M4,2 S4,4` spends 2 AP, vacates A’s lock and places B at `[4,2]` facing north while P occupies `[4,4]`. The translated shove hits A at `[5,1]`, not P; A is pushed to `[6,1]` and chases back. On turn 7 the third Shine puts B at `[4,2]:1` on A’s fresh lock with P at `[2,2]:7`, 0 AP. On `E` A swaps **with B**, killing it before it can shove. `S3,2` then kills A and clears Swap. No further hit or capture. Leaving A alive is useful both as a source and as an attacker.
- **Kill:** Two Shines kill A and clear Swap with 1 AP remaining. That last AP arms Capture on B’s known hit; it pushes P north. This removes one threat immediately, but trades a hit for a fresh weapon and leaves all 5 of B’s HP to clear. It is a feasible fallback, not necessary.
- **Replace:** `C M5,3` leaves `[5,2]` empty and enters B’s announced shove. Its hit pushes P east (horizontal on the displacement tie) and replaces the still-held Swap. `S4,3` then hits **both** A and B from `[6,3]`, reducing them to 1 and 4 HP respectively with 2 AP left. A dies on turn 7 without losing the new held ability. The later hit buys wider damage and a distinct route, but no terminal advantage over preserving Swap in these replays.

The paired example disproves “once you have Swap, you must kill its source and pay for a new ability.” It does not disprove that the **first** hit is mandatory, and it shows an optional purchase with tactical effects, not a profitable one at this snapshot. For these traces, preservation has the same finish turn, one more HP and fewer commands (11 versus 13 and 12). That is evidence of a usable puzzle-like inference and also a warning: three feasible continuations are not three comparably attractive strategies once the outcome is known.

## Search boundaries and decision

Alongside the direct replays, a scratch scan used the real model's `assess()` to branch on End Turn, Capture, the four cardinal moves and every cardinal Shine target within held range, discarding rejected actions and losses. It counted a horizon in **additional `E` commands**, still permitting all legal actions in the last player turn. It reused the earliest occurrence of the same mechanical state (P cell/HP, AP, armed flag, held source/ability, ordered enemies’ cells/HP/aim/ability/locks and patrol index); it did not conflate different active warnings or count events and acquisition timestamps as tactical differences. These are finite-horizon comparisons, not play frequencies or a model of discovery.

| Search start and filter | Horizon | Result |
| --- | ---: | --- |
| Anchor start, require unchanged P HP | 5 `E` | 625 states expanded; no win. |
| Circler start, require unchanged P HP | 5 `E` | 17,522 expansions; no win. |
| Circler after `C E`, allow all legal actions | 3 `E` | 72,600 expansions; wins on T4/T5, not T3. |
| Pair common T5 snapshot, allow all legal actions | 2 `E` | 61,916 expansions; no win by T7. The T8/7 HP replay therefore attains both the earliest finish and the HP ceiling from this snapshot. |
| Same pair snapshot, extended by one enemy phase | 3 `E` | Four winning turn/HP outcomes: T8 at 4, 5, 6 or 7 HP. These are outcome classes, not a count of distinct solutions. |
| Pair **keep** after its first `E`, require P HP ≥ 7 | 2 `E` | 16,547 expansions; T8/7 HP win, not T6/T7. |
| Pair **kill** after its first `E`, require P HP ≥ 6 | 2 `E` | 10,456 expansions; T8/6 HP win, not T6/T7. |
| Pair **replace** after its first `E`, allow all legal actions | 2 `E` | 74,476 expansions; T8 wins at 5 or 6 HP, not T6/T7. |

No result implies whole-catalog dominance. The earliest finish and HP bounds apply to the exact positions, not arbitrary setups. The scan does not establish a unique fastest/highest-HP route or minimize total commands; it does not rank unrelated openings from spawn. Final AP/HP have no carryover in these trials. Turn and command counts are mechanical measurements, not measured wall time, player preference, or enjoyment. The [prior brief](borrowed-turns-tactics-puzzles-and-time.md) supplies questions about choice, puzzles and time; this audit provides no evidence for a real-time conversion.

**Next probe, if separately authorized:** Compare one short paired arrangement under the unchanged rules with a short single-source control. Put the fork early, with a legible fixed-cell lock and a second threat that can be translated onto an opponent. Before inspecting candidate routes, require two legal, same-snapshot lines with different immediate payoffs (e.g. preserve HP and the held tool versus take a hit to unlock a quicker clear or a valuable multi-target effect). Screen out a faster, safer repeat-Shine route that bypasses the interaction. For Ronald, keep the solution hidden and distinguish whether he notices and chooses between plans, whether the choice is enjoyable, whether he wants another, and whether he actually returns without prompting.

**Disconfirmation:** If the unchanged rules repeatedly make one route both safer and faster across the paired probes, or Ronald reads the consequences but finds that only the first inference matters and the rest feels compulsory, do not prescribe more opponents. Shorten the puzzle if he values the inference; otherwise compare a bounded **core-bargain** alternative on matched boards (for example, spending AP to intercept a warning without requiring the first injury, versus the existing damage-for-power route). If he doesn't see the fork, distinguish a readability problem from indifference before attributing the result to the core. No such change or human result is part of this audit.

## Headless reproduction and validation

From the repository root, below creates only a scratch archive of the committed game. No import or rendering is needed for these model commands.

```sh
scratch=$(mktemp -d /tmp/opencode/borrowed-turns-audit.XXXXXX)
git archive df36cd6 games/borrowed-turns | tar -x -C "$scratch"
project="$scratch/games/borrowed-turns"
godot --headless --path "$project" --script res://tests/run.gd
godot --headless --path "$project" --script res://tests/stocked_routes_run.gd
```

The model suite reported **572 checks, 0 failures**, and the six shipped route checks reported **0 failures**; both exited **0**. The scratch scan commands behind the table also exited **0**. The replay below uses `assess` to check legality and nonmutation, then `act` and exact preview/commit equality, and prints each turn/AP, board, HP, held/armed state, intentions and events. Save this fenced block as `$scratch/replay.gd`:

```gdscript
extends SceneTree

const Model = preload("res://model/encounter.gd")
const Catalog = preload("res://content/encounters.gd")

func command(token: String) -> Dictionary:
	if token == "C":
		return {"type": "capture"}
	if token == "E":
		return {"type": "end_turn"}
	var parts := token.substr(1).split(",")
	var cell := [int(parts[0]), int(parts[1])]
	return {"type": "move", "to": cell} if token[0] == "M" else {"type": "shine", "target": cell}

func show_state(label: String, s: Dictionary) -> void:
	var enemies := {}
	for enemy in s.enemies:
		enemies[enemy.id] = [enemy.pos, enemy.hp]
	print(label, " ", JSON.stringify({
		"turn": s.turn, "AP": s.action_points, "P": s.player, "enemies": enemies,
		"held": s.stored, "armed": s.capture_armed, "status": s.status,
		"intentions": s.intentions, "events": s.events,
	}))

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var game = Model.new()
	game.configure(Catalog.registry()[args[0]].data, "R2")
	show_state("start", game.snapshot())
	for token in args[1].split(" ", false):
		var action := command(token)
		var before: Dictionary = game.snapshot()
		var result: Dictionary = game.assess(action)
		if not result.legal or game.snapshot() != before or not game.act(action) or game.snapshot() != result.preview:
			printerr("Replay failed at ", token, ": ", result.reason)
			quit(1)
			return
		show_state(token, game.snapshot())
	var final: Dictionary = game.snapshot()
	var actual := [final.turn, final.player.hp, final.action_points, final.player.pos[0], final.player.pos[1]]
	var expected: Array = Array(args[2].split(",")).map(func(value): return int(value))
	if final.status != "won" or not final.enemies.is_empty() or not final.stored.is_empty() or actual != expected:
		printerr("Unexpected finish: ", actual, " expected ", expected)
		quit(1)
		return
	quit(0)
```

Run each replay independently; the final argument is `turn,HP,AP,x,y`. All nine exited **0** with the asserted winning states.

```sh
replay() {
    godot --headless --path "$project" --script "$scratch/replay.gd" -- "$@"
}
replay anchor 'C E S4,3 S4,3' 2,8,1,2,3
replay anchor 'M1,3 M1,2 E M2,2 M2,3 C E S4,3 S4,3' 3,8,1,2,3
replay anchor 'E C E S4,3 S4,3' 3,6,1,2,3
replay circler 'C M2,2 E M2,2 S2,3 S4,2 E M3,2 S3,3 S5,2' 3,9,0,3,2
replay circler 'C E M1,2 E M2,2 S2,3 S4,2 E M3,2 S3,3 S5,2' 4,9,0,3,2
replay circler 'M1,3 E M2,3 C M2,2 E M2,2 S2,3 S4,2 E M3,2 S3,3 S5,2' 4,9,0,3,2
pair='M1,3 M2,3 M3,3 E M4,3 M5,3 M5,2 E C E S5,2 S5,1 S5,2 E'
replay switcher-b "$pair M4,2 S4,4 E M4,3 M4,2 E S2,2 S4,2 S2,2 E S3,2" 8,7,2,3,2
replay switcher-b "$pair S5,1 S5,2 C E M5,2 S4,2 S3,2 E M4,2 S3,2 S2,2 E S2,2" 8,6,2,4,2
replay switcher-b "$pair C M5,3 E S4,3 E M5,3 S4,3 S3,3 E M4,3 S3,3 S2,3" 8,6,0,4,3
```
