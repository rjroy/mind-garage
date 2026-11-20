---
title: "Borrowed Turns revision 02: backlash as the capture bargain"
date: 2026-11-15
status: draft
tags: [game-design, experiment, player-feedback, design-revision]
related: [.lore/work/games/borrowed-turns/experiments/001-hook-discovery/record.md, .lore/work/games/borrowed-turns/experiments/001-hook-discovery/capture-bargains.md]
---

# Borrowed Turns revision 02: backlash as the capture bargain

## Position in the experiment

The first playable comparison is preserved at commit `fd8e91d` on `experiment/borrowed-turns-prototype`, with the original source archive and evidence unchanged. This document records the subsequent conversation and agreed design direction. **These revised rules are not implemented in that prototype.** No new playtest scores, enjoyment result, or simulation result is asserted here.

Ronald requested visible commits because these design decisions are themselves part of the experiment. Preserve the initial proposals, criticism, alternatives considered, human decisions, and remaining uncertainty instead of rewriting the first design as if we had always intended this one.

## Observation: insufficient variant diversity

Ronald did not say the original alternatives were explicitly wrong, but challenged whether they represented sufficiently different mechanics. Action cost and range often belong to the common rules or tuning. V6's target commitment imposed a constraint without making its compensating player benefit clear.

The AI accepted that it had explored capture restrictions more than distinct uses or possibilities. This is human-supplied design diagnosis, not an autonomous AI discovery. It is qualitative feedback and conceptual critique, not proof that every original constraint is unfun. Ronald also left room for combining individually useful constraints into a coherent whole.

Separate future work into:

- **Shared rules:** the common action economy, movement, capture reach, and deadlines.
- **Mechanic alternatives:** meaningfully different capabilities, interactions, or coherent tradeoffs in how the player uses the mechanic.
- **Tuning/constraint comparisons:** deliberate tests of costs, ranges, caps, and timing. These are legitimate experiments but must be labeled honestly rather than counted as six fundamentally different mechanics.

A restriction can create an interesting bargain, but the proposed player benefit must be explicit. Merely making the same action harder is not sufficient diversity by itself.

## Human-selected direction

| Element | Direction agreed in conversation |
| --- | --- |
| Capture cost | Free: no action or movement-point expenditure |
| Capture frequency | Unlimited per turn; no arbitrary N-capture cap |
| Capture range | Initially 1; useful range upgrades can follow |
| Movement | Its own movement-point budget, interleavable with actions and free capture; initial 1 point was suggested |
| Release cost | One action |
| Release range | Inherited from the captured ability, not a universal player release range; later unlocks may augment it |
| Holding | Capture demands release; start by investigating a two-turn deadline |
| Replacement | Capturing a new ability while holding one immediately triggers the old ability's backlash |
| Expiry | Failing to release by the deadline triggers the held ability's backlash |
| Backlash | Based on the actual captured ability, ideally that ability discharging where the player stands; bigger abilities should carry correspondingly consequential backlash |
| Discard | No discard command or harmless disposal route; release it or accept its backlash |

Movement and actions are independent pools. Ronald illustrated this with **two actions and four movement points**: move two cells, capture for free, move one cell, release, then move one cell. That sequence uses four movement points and one action, leaving one action. The numbers illustrate interleaving; they do not establish the final starting budgets or override every earlier tuning suggestion.

Utility upgrades such as movement or capture range can be useful without being individually transformative. They can coexist with the earlier requirement for genuinely enticing new possibilities; the progression system need not make every incremental improvement a major new mechanic.

## Decision sequence and attribution

1. **Ronald:** Proposed the shared rules above, including free capture, separate movement points, ability-derived range, forced release, ability-specific replacement/expiry backlash, and no discard.
2. **AI:** Asked whether movement is separate from release, and whether replacement discharges the held ability before acquiring the new one if the player survives.
3. **Ronald:** Clarified interleaving with the two-action/four-movement example and confirmed replacement triggers backlash. He considered whether a per-turn capture limit might be needed, without selecting one.
4. **AI:** Suggested two captures per turn provisionally, with one/unrestricted comparisons, to preserve a capture/replacement sequence while bounding cancellation chains. This was a proposal, not tested evidence.
5. **Ronald:** Rejected a cap for the starting design: “Let's start with capture as much as you want, because the backlash is the restricting mechanic .. you cannot capture again if you are out of HP”.
6. **AI:** Accepted unlimited free capture. Proposed resolution order: discharge the held ability, resolve its effects, acquire the new ability only if the player survives; death ends the run. Detailed edge cases remain to be specified before implementation.

The two-capture proposal is therefore **not** the current design. The first prototype's once-per-turn capture flag and discard are likewise not requirements for the revision. No existing rule survives merely because it is already coded.

## Why this might be interesting

The proposed bargain is no longer just prevention plus a storage restriction. Positioning can make backlash useful: an area discharge centered on the player could hurt nearby pursuers while also risking the player's life. Deliberately allowing expiry, or replacing an ability to trigger it, may be a tactic.

Working experience hypothesis: **redirect a stolen ability, or deliberately endure its discharge where you stand.** Unlimited capture lets that possibility be investigated instead of preemptively removed by a cap.

This is a hypothesis, not a demonstrated improvement. A sufficiently beneficial backlash could permit repeated captures to cancel too many threats. Conversely, unavoidable self-damage could make replacement feel like a trap. The first tests should investigate those possibilities without automatically reinstating an arbitrary cap.

## Open executable details, not silently settled

- Exact initial action/movement budgets and their refresh point. The two-action/four-point example is not a finalized starting configuration.
- Meaning of the two-turn deadline under the new interleaved economy: when counting starts, when it ends, and whether the final action/turn still permits release. Do not carry over the old two-ordinary-action clock accidentally.
- What advances enemy resolution when multiple actions and movement steps are available: the turn end, individual actions, or another explicit boundary. Real-world waiting at the keyboard must not advance a turn-based simulation.
- Ability-specific backlash footprints and directional behavior. An area attack centered on the player is understandable; a ray, charge, push, or pull needs an explicit equivalent. Preserve meaningful properties rather than silently replace every backlash with generic damage.
- Replacement atomicity when the old discharge kills or moves the intended new source, or invalidates capture reach. Define and preview the result instead of inventing a mid-resolution exception.
- Whether capturing an already canceled announcement is possible. The AI suggested each announced occurrence can be taken once, but Ronald has not separately settled every announcement/refresh rule for this revision.

The user prefers agents to make bounded provisional choices rather than ask about every number. These open items identify implementation decisions that need an explicit record and tests, not a mandatory new interview or permission to build in this documentation-only step.

## Next evidence

For an authorized implementation revision, retain the first prototype and compare recorded builds rather than overwrite its evidence. Use controlled scenarios for interleaved budgets, range inherited from different abilities, deadline boundaries, replacement survival/death, beneficial area backlash, no-discard behavior, and repeated capture chains. Preview and confirmed resolution must agree, including whether a replacement succeeds after backlash.

Ask about enjoyment and consequential choices separately from winning. Record whether intentional backlash is understandable and satisfying, not merely effective. Preserve contrary results and human interventions. These checks are proposed; none has run for revision 02.

Related Beads: `mind-garage-6yt` records this documentation/checkpoint step. `mind-garage-vu4` remains the human-feedback discussion; the first capture-rule feedback is now recorded here.
