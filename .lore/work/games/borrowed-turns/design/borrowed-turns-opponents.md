---
title: "Borrowed Turns: opponent shortlist"
date: 2026-11-17
status: draft
tags: [game-design, borrowed-turns, opponents]
related: [.lore/work/games/borrowed-turns/experiments/003-active-opponents/record.md]
---

# Opponent shortlist

Ronald accepts the expanded Stage at `8275a48` and asks for potential opponents. These are AI-proposed gameplay roles; his subsequent “Great. Lets see it” selects the recommended **Switcher first**, checked alone and then paired with an existing opponent. The other five remain proposals, not approved rules, art briefs or implementation tasks. Current narrow-shove chaser A and wide-shove ranged B remain the baseline.

Each opponent should create a distinct positioning problem and offer a worthwhile borrowed tool. Because the player has no independent attack and a held ability disappears when its source dies, a purely non-damaging last opponent could make defeat-all impossible. Every candidate below therefore has a damaging, capturable attack and a damaging Shine. This is a feasibility constraint of the present bargain, not a rule that every future ability must deal damage.

| Working role | Movement and announced attack | Borrowed Shine | Partner interaction |
| --- | --- | --- | --- |
| Switcher | Seeks a short clear line; announces a damaging position exchange | Damage and exchange positions with the target | Escape one locked region at the cost of occupying a different exposed position |
| Flanker | Uses the existing narrow damaging shove, but seeks a different approach side from its partner; alone it closes and attacks | Familiar damaging shove | Makes escape from A's direction expose the player's other side; tests behavioral identity without a new effect |
| Vault | Approaches and announces a damaging strike with a clearly marked empty landing cell beside its target | Damage and relocate beside the target | Mobility can be valuable, but can also move the player into B's threat |
| Anchor | Closes and announces a damaging adjacent strike with a temporary movement restriction | Damage and prevent the target's next movement | Hold A's approach without retroactively cancelling its locked attack |
| Rhythm | Alternates a damaging adjacent strike and short-line shove, always announcing the actual next shape | Repeat the specific attack acquired, not the opponent's whole sequence | Choose which hit to acquire while accounting for B's region |
| Puller | Maintains a short straight-line gap; announces damage and a pull toward itself | Damage and pull the target toward the player | Rearrange B's spacing while risking proximity to its next attack |

## Open definitions, not silent requirements

- Swap and strike/landing effects need explicit ordering, occupancy and death behavior before a build.
- Anchor introduces a new temporary status. Define when it expires, whether voluntary movement alone is prevented, and how push/pull interact with it.
- Rhythm changes which attack is announced, not a hidden reaction after the player commits. Capture still takes the first attack that actually hits; holding copies that one attack.
- Flank selection needs predictable ties and a useful solo fallback, not an unseen second attack planner.
- Range, damage, path blocking and exact footprint are not settled by these role descriptions.
- All candidates need a feasible solo acquisition/defeat path and readable interaction with an existing opponent. Do not add a last-enemy exception to hide an acquisition or damage deadlock.

## Recommended first exploration

Switcher offers the largest immediate change in the player's positioning tool. Flanker is the lower-complexity alternative: test whether movement relationships alone produce a different puzzle with an already understood attack.

Switcher is selected for the next bounded implementation, with B as the first paired comparison. First inspect acquisition, targeting and solo completion, then compare the pair. Judge clarity, consequential choices and desire for another encounter separately; six proposals are not six authorized builds or the six alternative versions required when formally exploring one new mechanic. This follow-up implements the selected opponent; it does not claim a six-version swap-mechanic comparison.
