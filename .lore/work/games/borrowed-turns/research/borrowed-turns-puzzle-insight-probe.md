---
title: Borrowed Turns puzzle insight probe
date: 2026-11-17
status: completed
tags: [borrowed-turns, puzzle, tactical-decisions, research]
related: [.lore/work/games/borrowed-turns/research/borrowed-turns-tactics-puzzles-and-time.md, .lore/work/games/borrowed-turns/experiments/004-switcher/record.md]
---

# Borrowed Turns puzzle insight probe

## Key findings

In a reachable turn of the authored Switcher + B encounter at `df36cd69b1a5230abb9a3053e26c91b4cf7227b4`, the player can exchange places with B, putting B in Switcher's locked cell. Switcher then swaps with and damages B, not the player. The same principle works in a counterfactual with B on the other side, but the original target input is illegal there. The probe checks a tactical inference, not whether it is necessary to win, actually discovered, or enjoyable.

There is a meaningful alternative: merely stepping out of the threatened cells also avoids damage, while ending immediately hurts the player but causes B to damage Switcher. These are different tactical plans, not a demonstration of a unique solution or dominance. A blind human attempt could distinguish prediction from trial-and-error; no human attempt was performed.

## Intended insight, stated before line testing

Before examining continuations, the hypothesis was: **Switcher locks a cell, not a person. If a different actor occupies that cell at resolution, the attack can hit that actor instead.** This was stated to the parent before replay and search. The start of Switcher + B is the authored encounter, not an invented rules fixture. A bounded model-state search following a reachable acquisition found the turn below. The choice of this particular reachable turn was therefore informed by search, not preselected or presented as naturally encountered.

## Spoiler-free human prompt

Show only this section and the position, not the setup trace or answer key. This is an optional facilitated thought experiment, not a recruitment request. Present the actual turn-8 board from the setup below, or a faithful diagram, including the game's normal ability descriptions and preview controls. Coordinates increase right and down.

> You have 3 AP and hold Switcher's Swap. Both enemies have announced attacks. What could you do this turn, and what do you predict will happen when you end it? Look for a way to avoid losing health while affecting an opponent. Explain your prediction before confirming or previewing the outcome.

This goal asks for a useful consequence, not a full victory. Let the player choose freely, including a different approach. For an optional subsequent transfer, reveal the counterfactual position only after their initial response; it is not a normal selectable encounter. Ask for a new prediction before revealing its result. Because Ronald may already know Switcher, record prior exposure and that the position was prepared for him. Ask separately about enjoyment and desire to continue; count voluntary replay only if it actually occurs.

## Answer key: spoilers

### Reproducible authored position

Launch `godot --path games/borrowed-turns -- --encounter=switcher-b`. Starting at turn 1, use these commands in order. `M` is one Move, `C` Capture, `E` End Turn; each row ends with E.

| Turn | Commands before E |
| --- | --- |
| 1 | M `[1,3]`, M `[2,3]`, C |
| 2 | M `[2,2]`, M `[2,1]`, M `[2,0]` |
| 3 | none |
| 4 | none |
| 5 | M `[3,1]` |
| 6 | M `[3,2]` |
| 7 | M `[3,3]`, M `[3,4]` |

At turn 8: player `[3,4]` HP6, 3 AP, holding A's Swap; A/Switcher `[3,2]` HP5, locked target `[3,4]`; B `[1,4]` HP5, facing right. B's width-three, range-two shove covers `[2,3]`, `[2,4]`, `[2,5]`, `[3,3]`, `[3,4]`, `[3,5]`. No walls. Both attacks do 1 damage. Swap Shine targets an occupied enemy on a clear cardinal line within two cells, exchanges positions first, then damages that target. End Turn resolves A then B, then movement and new intentions. Source displacement translates B's footprint; it does not keep a frozen world-space footprint.

### Compared continuations

- **Plausible naive line:** End Turn immediately. A exchanges with the player and damages them, HP6→5. B then hits A at `[3,4]`, HP5→4, and pushes A to `[4,4]`; movement follows, leaving player `[3,2]`, A `[3,4]`, B `[1,3]`. This is not simply a bad plan: it damages the ability source, whereas the next line preserves it.
- **Insight line:** Shine B at `[1,4]` (1 AP): player moves to `[1,4]`, B to `[3,4]` and B HP5→4. End Turn: A's locked `[3,4]` now contains B. A exchanges `[3,2]` with B, then damages B to HP3. B's shove resolves from its new `[3,2]` position, facing right, and hits nobody. After enemy movement: player `[1,4]` HP6, A `[2,4]` HP5, B `[2,2]` HP3; A's Swap remains held. The exchange and damage occur before B's attack, not after it.
- **Bypass:** Move to `[4,4]`, then End Turn. A's locked cell is empty and B's original footprint misses. After movement, player `[4,4]` HP6, A `[3,3]` HP5 and B `[1,3]` HP5. This avoids damage without the replacement-occupant inference but does not damage an opponent. No full-win continuation or optimality comparison was tested for any branch.

### Transfer: counterfactual, not authored or verified reachable

Change only B's position in the turn-8 model state from `[1,4]` to `[5,4]`. All other state stays fixed, including B's facing right; recompute the published footprint, which is clipped to `[6,3]`, `[6,4]`, `[6,5]`. This alters a board fact, not an authored scenario, and its reachability with those announcements and history is unknown.

Copying Shine `[1,4]` is illegal because there is no enemy there. Instead Shine `[5,4]`: B arrives on A's locked `[3,4]` and is damaged to HP4; player arrives `[5,4]`. End Turn: A exchanges with B and damages it to HP3; B's translated shove hits nobody. After movement: player `[5,4]` HP6, A `[4,4]` HP5, B `[3,3]` HP3. This demonstrates mechanical transfer of the rule, not transfer of human understanding. A player might also recognize the target has moved without understanding why A will hit it.

### Interpretations and rejection criteria

The successful line is a fair inference only if the player can see the locked cell, the two enemy intentions, target legality and resolution order, and understands or can inspect the cell-target rule. If these are not legible in the real presentation, a wrong prediction need not indicate faulty reasoning. Preview exposes outcomes, so record whether the prediction preceded preview.

Reject the strong claim that this authored decision **requires** the insight to avoid damage: the dodge branch already disproves it. Reject the weaker claim that it is a *discoverable puzzle insight for Ronald* for this probe if, without prior coaching, he cannot explain or predict which occupant is hit on the initial position and adapt that prediction to the changed one, or reports that the information needed was not visible. A correct answer produced only by preview or copying is ambiguous rather than confirmation. Even a correct explanation and transfer establish neither enjoyment nor replay. Another viable tactical line does not by itself refute the weaker claim.

## Headless reproduction and limits

Godot `4.7.2.stable.arch_linux.ed1daf0bf`, Linux, source commit above. The following scratch driver uses the actual `Encounter` and authored `switcher_b` fixture, not a reimplementation. It checks every submitted action is legal, every committed state matches its preview, and the old transfer target is rejected. It prints complete ordered events and states for manual comparison with the answer key. The counterfactual deliberately edits the private model state only in scratch, then refreshes intentions; it is not reachable proof. No seed is involved.

Save this as `/tmp/opencode/probe/replay.gd` and run `godot --headless --path games/borrowed-turns --script /tmp/opencode/probe/replay.gd`. Create the parent directory first if necessary.

```gdscript
extends SceneTree
const E=preload("res://model/encounter.gd")
const F=preload("res://content/switcher_b.gd")
var fails=0
func step(g, cmd):
 var before=g.snapshot(); var v=g.assess(cmd)
 print("ACTION ",JSON.stringify(cmd)," legal=",v.legal," reason=",v.reason)
 if not v.legal: fails+=1; return
 if not g.act(cmd) or g.snapshot()!=v.preview: fails+=1
 print("STATE ",JSON.stringify(g.snapshot()))
func _initialize():
 var g=E.new(); g.configure(F.DATA,"R2")
 var init=[{"type":"move","to":[1,3]},{"type":"move","to":[2,3]},{"type":"capture"},{"type":"end_turn"},{"type":"move","to":[2,2]},{"type":"move","to":[2,1]},{"type":"move","to":[2,0]},{"type":"end_turn"},{"type":"end_turn"},{"type":"end_turn"},{"type":"move","to":[3,1]},{"type":"end_turn"},{"type":"move","to":[3,2]},{"type":"end_turn"},{"type":"move","to":[3,3]},{"type":"move","to":[3,4]},{"type":"end_turn"}]
 for cmd in init: step(g,cmd)
 var base=g.snapshot(); print("BASE ",JSON.stringify(base))
 for mode in ["naive","insight","transfer","dodge"]:
  g._state=base.duplicate(true)
  if mode=="transfer":
   g._state.enemies[1].pos=[5,4]; g._refresh_footprints()
   var old=g.assess({"type":"shine","target":[1,4]}); print("OLD INPUT legal=",old.legal," reason=",old.reason); if old.legal: fails+=1
  print("BRANCH ",mode," START ",JSON.stringify(g.snapshot()))
  if mode in ["insight","transfer"]: step(g,{"type":"shine","target":[5,4] if mode=="transfer" else [1,4]})
  if mode=="dodge": step(g,{"type":"move","to":[4,4]})
  step(g,{"type":"end_turn"})
 print("FAILURES ",fails); quit(0 if fails==0 else 1)
```

Execution exited **0**, printed `FAILURES 0`, and rejected the copied transfer input with `Swap requires an enemy target.` The recorded outcomes above were read from the ordered state/event output; the driver's exit status alone does not assert those specific HP or position values. The search was bounded to 100,000 explored states and turn 8, not an exhaustive proof of all routes. This model-only check does not establish real UI legibility, human understanding or fun.
