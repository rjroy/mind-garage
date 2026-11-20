---
title: Borrowed Turns tactics, puzzles and time
date: 2026-11-17
status: draft
tags: [borrowed-turns, tactical-decisions, puzzles, time-pressure]
related: [.lore/work/games/borrowed-turns/experiments/005-opponent-library/record.md, .lore/work/shared/research/what-makes-games-fun.md, .lore/work/shared/audience/player-brief.md]
---

# Borrowed Turns tactics, puzzles and time

## Key findings

The relevant question for Ronald is not whether a board has many legal moves. It is whether he can see an opportunity, choose a plan he cares about, and see a consequence that makes him reconsider his next move. One perfectly good puzzle can have a single solution. One perfectly good tactical position can have several plans and no trick. Neither guarantees that the player wants another fight.

At `df36cd6`, the [six winning traces](../../../../../games/borrowed-turns/tests/stocked_routes_run.gd) contain a useful warning. Four need no voluntary movement command. Anchor and Puller even lose to the identical sequence: Capture, End Turn, Shine at `[4,3]` twice. Deadeye can be beaten without ever borrowing Swap. That shows some authored differences need not change the winning *inputs*. It does not establish that the routes are optimal, readily discovered by a new player, or representative of Ronald's play. In contrast, the recorded Circler and Lantern Guard routes use different movement and targeting. Switcher + B can test a question no solo encounter can: is the other enemy worth keeping alive because of what it lets you do?

## Three different diagnoses

- **Core bargain:** A hit can be a price worth choosing or just the admission fee for attacking at all. Compare a position where delaying or replacing a capture changes a later opportunity with one where delay merely costs HP. A counterexample to “the core is broken” would be an existing position where the same rules sustain an engaging choice. A counterexample to “we only need better boards” would be varied boards that still reward the same routine.
- **Puzzle:** Name the inference *before* showing a solution. For example, “the locked attack belongs to a cell, not to the actor who first stood there.” Can the player predict the outcome of moving a different actor there? Does that prediction help on a changed board where copying the old inputs fails? Verify the example against actual reach, AP and attack order before using it. A win alone is not evidence of an insight; multiple valid solutions are not evidence against one.
- **Time:** If the player knows what to do but dislikes confirming it repeatedly, removing downtime is a different intervention from making enemies act while the player thinks. Compare the same threat and goal under turns, continuous resolution with pausing, and continuous resolution without pausing. Ask what the player *gains* from timing a capture. Do not call faster losses, elevated stress, or shorter fights improved tactics.

## Decision and human evidence

### What the online evidence supports

- [Ryan, Rigby & Przybylski (2006), four studies](https://doi.org/10.1007/s11031-006-9051-8): perceived autonomy and competence were associated with enjoyment. Look for a plan the player feels they chose and pulled off; this is not evidence that adding more legal moves causes enjoyment.
- [Matthew Davis, *Into the Breach* design postmortem (GDC)](https://www.gdcvault.com/play/1026333/-Into-the-Breach-Design): a developer account of iterating on legible threats and manipulating enemies. The useful comparison is not “both games telegraph attacks”; it is what the player can do *because* they know the attack is coming. This is precedent from one game, not a controlled experiment.
- [Visani Scozzi, Iacovides & Linehan (2017), puzzle learning in *Portal*](https://doi.org/10.1145/3116595.3116628): comparing solution analysis with actual play and player experience exposed learning breakdowns in a 14-person case study. Borrow the method, not a claim about tactical enjoyment: document the inference a designer expects, then see what the player actually infers.
- [Mäkelä & Schmidt (2020), combat pacing in RPGs](https://doi.org/10.1145/3410404.3414248): an analysis of 546 forum posts found conflicting values in turn-based, real-time and pausable combat. Immediacy and precise control can both matter; repeated pausing can interrupt flow. Self-selected posts reveal plausible experiences, not which format most players prefer.
- [Anwar (2016), exploratory pace study, University of Waterloo](https://uwspace.uwaterloo.ca/items/d588c640-a68b-4b0c-8e04-30be326df033): real-time play produced more reported pressure and tension in a 36-participant study. Results differed by game type; distinct games confound timing with other design differences. Keep the information, encounter and input burden comparable before interpreting a clock effect.

### What to do with a result

Start with the existing decision states before making any build. If genuine competing plans exist and Ronald enjoys choosing between them, investigate encounter composition. If finding a rule interaction feels good but executing the rest is routine, investigate shorter authored puzzles. If choosing under pressure or intercepting an attack is the attractive part, try a matched timing probe. If none of those experiences appeals, shelving Capture/Shine is a legitimate outcome.

For an optional human comparison, use an unfamiliar position and avoid showing the answer key. Ask afterward what Ronald was trying to make happen, whether the choice was enjoyable, and whether he wants a different position. Record a voluntary return only if it actually occurs. Use a different but comparable position for a second condition and note order and prior exposure. One player's repeated play informs this game; it is not independent evidence about players generally. No additional telemetry, recruitment or implementation is assumed.
