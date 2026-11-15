---
title: "Borrowed Turns: encounter baseline and capture bargains"
date: 2026-11-15
status: draft
tags: [game-design, experiment, capture-mechanic]
related: [.lore/work/experiments/001-hook-discovery/record.md, .lore/work/intents/player-brief.md]
---

# Borrowed Turns: encounter baseline and capture bargains

## Agreed direction

Mind Garage names the experimental effort, not the game. **Borrowed Turns** is this prototype's working title and can change independently of the experiment's identity.

**Hook: Steal the enemy's plan, then make it do something they never intended.**

Ronald selected this hook. He supplied the story seed: an otherwise ordinary person acquires an artifact that enables capture, and is hunted because of it. This is an opening premise, not a settled plot or a claim that the character has no other abilities.

The AI proposed an escape-oriented interpretation: survive through improvisation rather than overpowering the pursuers. Ronald agreed to use that as the encounter baseline below.

## Agreed prototype encounter baseline

- Turn-based, with visible enemy intentions and time to inspect them.
- Top-down 2D on a grid, with clear positions, paths, ranges, and affected cells.
- One screen-sized, constrained encounter with all relevant threats visible.
- A small number of enemies whose simultaneous threats make canceling one a choice, not a complete solution.
- A concrete escape objective, such as reaching an exit or surviving until it opens, rather than mandatory extermination.
- No card-game structure: captured actions belong to enemies and the physical encounter, not a draw deck.

These are provisional prototype commitments, not permanent decisions for a finished game. Real-time or a different perspective could be revisited, but would require retesting capture costs rather than assuming equivalent results. Board dimensions, exact escape condition, turn ordering, controls, movement, damage, enemy action rules, and run length are still open.

This document records design discussion only. No board, interface, assets, simulation, or playable variant has been built. Visual/interface execution belongs with the UI/design specialist when implementation is authorized.

## Framing the mechanic

The player selects a visible announced enemy action, prevents that occurrence from resolving, and holds a version they can release later from a new position or toward a new target. Other threats remain. The potential enjoyment is choosing which danger to remove and turning the stolen action into a useful future opportunity.

Ronald raised two key uncertainties: capture needs meaningful limits, and unlocks need to change the possibilities rather than merely increase slots or range. The AI's earlier one-slot, turn-cost, expiry, and preserved-geometry suggestions remain candidate rules, not separately approved requirements.

## Shared comparison proposal, not yet approved executable rules

Keep the board, enemies, announced action definitions, escape objective, starting state, and feedback consistent across variants. Use one stored action and let releasing it consume the player's action. Preserve the source action's recognizable geometry; do not silently turn a line attack into a freely targeted explosion.

Use V1 as a reference, not a presumed winner. State any coupled changes explicitly. The alternatives below compare coherent bargains, not a controlled test of one numerical parameter; differences cannot automatically be attributed to a single cause.

Initial screening should cover a threatened player choosing between two capturable actions, holding versus releasing an action, attempting an illegal capture, and completing or failing an encounter. Add variant-specific controlled cases below. Preserve exact starting states once defined rather than pretending these verbal scenarios are executable fixtures.

## Six alternative capture bargains

All six have disposition **proposed, unbuilt, untested**. No alternative has been ruled out.

### V1. Spend a Turn

- **Rule difference/reference:** Capture consumes the player's action. One slot; a stored action does not expire. To capture again, first release or explicitly discard the stored action; discarding also consumes an action.
- **Enjoyment hypothesis:** Preventing one attack while foregoing movement, plus the occupied slot, creates enough tension without additional resource management.
- **Prediction:** Ronald sometimes declines a legal capture, and sometimes releases a useful action partly to reopen the slot.
- **Counterevidence:** Capturing is an automatic safe default, or holding the best action removes most interesting capture decisions.
- **Risk:** Waiting and indefinite storage may enable repetitive suppression or hoarding.
- **Diagnostic:** Trace capture/hold/discard loops under multiple simultaneous threats; check that exactly one announced occurrence is canceled and other enemies still resolve.

### V2. Close Approach

- **Rule difference:** Capture requires adjacency to the source enemy. The capture action may include a one-cell approach step immediately before capture, if that legal step ends adjacent. Other storage/release rules match V1.
- **Enjoyment hypothesis:** Reaching a dangerous enemy to steal its action creates a satisfying positional commitment; the approach step prevents a pure movement tax.
- **Prediction:** Ronald changes routes to obtain a particular action and can identify when the approach was worth the exposure.
- **Counterevidence:** Useful captures rarely become reachable, or the approach step is simply a universally preferable way to move.
- **Risk:** This bundle changes capture reach and action economy; it may reward kiting more than capture choice.
- **Diagnostic:** Test blocked approach paths, adjacency boundaries, capture from current adjacency, and whether the source's other neighbors still threaten the resulting position.

### V3. Brief Possession

- **Rule difference:** Use V1's capture cost, but the stored action expires after two subsequent player actions if not released. The capture action itself does not consume this lifetime; a release on the second subsequent action is allowed.
- **Enjoyment hypothesis:** A limited opportunity creates improvisation rather than indefinite collection of the best answer.
- **Prediction:** Ronald weighs a usable action now against a stronger action that would take too long to position.
- **Counterevidence:** Expiry mostly causes wasted effort or forces immediate release every time.
- **Risk:** A turn-based game could still feel like an unpleasant countdown puzzle despite having no real-time pressure.
- **Diagnostic:** Test lifetime boundaries, capture versus release timing, and whether representative attacks can reach useful targets before expiry.

### V4. Keep the Source Alive

- **Rule difference:** Use V1, but the stored action depends on its source remaining alive. Defeating the source destroys its unreleased action. The source can make new announced actions on later turns; capture is not permanent disabling.
- **Enjoyment hypothesis:** A pursuer can become an asset to preserve temporarily, changing how the player evaluates a threat.
- **Prediction:** Ronald sometimes avoids an otherwise useful elimination to preserve a stolen opportunity.
- **Counterevidence:** Source survival never matters, or it mostly causes losses the player perceives as arbitrary.
- **Risk:** Interaction with simultaneous damage and release could be confusing; resolution order must be explicit before implementation.
- **Diagnostic:** Test source death before release, release that kills its own source, and unrelated enemy deaths. Confirm cancellation applies only to the captured occurrence.

### V5. Store the Consequence

- **Rule difference:** Capture is a free once-per-turn operation while the slot is empty, followed by an ordinary player action. If the stored action is discarded or still unreleased at the end of the second subsequent player action, it discharges against the player using an explicit action-specific backlash rule. Releasing it on that final action avoids backlash.
- **Enjoyment hypothesis:** Immediate freedom is purchased with a future obligation: the player can rescue the present while creating a problem to solve.
- **Prediction:** Ronald occasionally refuses a free capture because the stolen action would be difficult or dangerous to use in time.
- **Counterevidence:** Free prevention dominates regardless of backlash, or the future penalty feels like a gotcha rather than an informed bargain.
- **Risk:** This is the most rule-heavy candidate and could make defense needlessly punitive. Do not invent unspecified backlash behavior at runtime.
- **Diagnostic:** Define backlash for each capturable action; test the final release boundary, forbidden replacement, once-per-turn enforcement, and whether capture/backlash loops bypass the intended cost.

### V6. Show Your Hand

- **Rule difference:** Use V1, but immediately upon capture the player commits a legal future release target. The release originates at the player's later position, subject to the original action's geometry; the target stays fixed. If release becomes invalid, reposition or discard under V1's rules rather than silently retargeting.
- **Enjoyment hypothesis:** Choosing an action also becomes a spatial promise; maneuvering to make that promise work creates anticipation.
- **Prediction:** Ronald uses movement to realize a planned release and sometimes chooses a less powerful action with a more achievable target.
- **Counterevidence:** Targets become invalid too often, or commitment only adds clicks without changing decisions.
- **Risk:** Moving enemies may make targeting feel unfair. Targeted cell versus tracked actor must be fixed consistently before testing; do not mix the two without a separate comparison.
- **Diagnostic:** Test target commitment, later line-of-sight changes, invalid releases, and discard recovery. Confirm previews distinguish present legality from future uncertainty.

## Shared unlock preview, not a progression tree

The earlier suggestion was to give every variant the same small advanced-ability sample. A bounded candidate is **Invert**: reverse a captured push into a pull or a pull into a push before release. Restrict it to explicitly reversible actions; no assumed “opposite” for damage or explosions. Include the same compatible enemy action in every variant if this preview is used.

This is an AI proposal, not Ronald's selected unlock. First test base capture/release; then offer the same directly accessible preview in each variant, without grinding. Compare anticipation and actual payoff separately. Naturally earned progression can be tested later; preview enthusiasm does not establish that an unlock path is satisfying.

Combining actions, echoes, and traps remain possible later directions, not promised features or part of this first comparison. Do not build a progression tree to compensate for an unsatisfying core decision.

## Next planning boundary

Before building, settle the exact shared turn sequence, minimal board/enemy set, target selection semantics, capture reach for variants other than V2, escape condition, and proposed unlock preview. Specify executable correctness tests and practical decision/stopping criteria. Prefer a small manual fixture set over procedural generation initially.

Human play should investigate whether each bargain is understandable and produces worthwhile choices, while keeping enjoyment, desire for another run, and voluntary replay separate. Do not exclude variants for being predicted less fun by AI. No test, exclusion, ranking, or enjoyment conclusion is recorded here.

Related Beads: `mind-garage-xgy` covers this design-record step. Future implementation needs its own bounded scope and verification path.
