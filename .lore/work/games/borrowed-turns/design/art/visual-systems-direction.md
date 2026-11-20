---
title: "Borrowed Turns: three visual systems"
date: 2026-07-02
status: draft
tags: [borrowed-turns, art-direction, visual-exploration, shadow-puppets]
related: [.lore/work/games/borrowed-turns/design/art/stage-components-brief.md, .lore/work/games/borrowed-turns/experiments/002-shadow-paper/record.md]
---

# Borrowed Turns: three visual systems

## Context and authority

Ronald accepted the integrated stage and floor at `dcbd13e`: “The floor, and stage are perfect.” Preserve those accepted areas. His subsequent discussion identifies three remaining systems: standees, board telegraphs and shadow-puppet performance.

This document captures that discussion and the agent's working hypotheses. It is not approval of final character designs, animation, a casting algorithm or additional mechanics. Ronald requested documentation and work toward visual exploration of the most speculative system. The agent selects the shadow-puppet director because it must translate board relationships into a readable theatrical performance, not simply produce attractive artwork.

## Division of responsibility

**The board presents complete tactical facts. The backdrop dramatizes selected interactions.**

The board has left/right and front/back space; the puppet screen offers much less spatial separation. Literal projection of all board actors onto that screen risks overlap and confusion. The proposed solution is theatrical staging, including time and sequencing, rather than pretending screen coordinates reproduce the map.

The original supplied forest/lantern image remains the style anchor: framed theatre, standee-like figures, elaborate puppets visually distinct from those figures, and a lantern. Liking the lantern establishes visual interest, not its gameplay function.

## 1. Standees

**Ronald's open question:** should figures use a little object movement, a few drawn animation frames or both?

**Starting hypothesis:** treat the figure as a paper object. Slide between cells, briefly lean or pivot when acting, then settle. Avoid continual bobbing that demands attention from every piece. Add alternate drawn poses only where object movement cannot communicate the action convincingly.

The distinction between quiet figures and expressive puppets may give both layers a purpose. Stiffness remains a real risk. Judge one representative short motion study before authorizing a whole animated cast; no standee motion treatment is approved yet.

## 2. Telegraph display

**Ronald's observation:** current telegraphs are functional but not visually appealing. Their appearance needs exploration rather than assuming the current graphics are the answer.

**Starting hypothesis:** investigate a small set of paper-native constructions, such as contrasting paper edges or printed action marks. These are possible directions, not approved artwork.

Compare treatments on the same occupied board with overlapping threats. Distinguish:

- Threatened cells and their announcing source.
- The player's selected command and predicted effects.
- Held-action backlash and its risk to the player.

Do not depend on color alone. Preserve exact affected spaces, legal choices and source identification. Cosmetic comparisons are not six alternative mechanic versions and do not require a gameplay-rule change.

## 3. Shadow-puppet performance

### Human proposal

Ronald proposed choosing actors whose actions interact with the player, then composing those interactions on the backdrop. One enemy attacking the player should produce that exchange; multiple actors may be staged from different directions even when those directions differ from their board positions. With no interaction, he raised the possibility of the protagonist sneaking through shadows.

Rehearsal is already the agreed starting direction: **“If you do nothing this is what will happen to you.”** It is a conditional announced danger, not damage occurring while the player thinks.

### Working director hypothesis

The director consumes known announcements, the selected command's model prediction and confirmed ordered events. It must not become another combat simulator or invent later-turn knowledge.

1. **Select relevant interactions.** Prioritize the inspected action, announced threats affecting the player, and player-caused interactions with enemies. Previewed consequences may change relevance.
2. **Include non-damage consequences.** Displacement, replacement/expiry backlash and resulting chains can matter as much as a direct hit.
3. **Cast recognizable participants.** Preserve source identity and a recognizable action motif across board, rehearsal, capture and release. A repeated visual connection is a hypothesis to test, not permission to add misleading gameplay marks.
4. **Compose for theatrical clarity.** Left/right placement tells the exchange; the board remains authoritative about direction, range and distance. Screen position must not silently imply a different tactical outcome.
5. **Sequence when crowded.** Use readable exchanges over time rather than packing every actor into one horizontal tableau. A fixed simultaneous-cast limit has not been agreed.
6. **Keep unchanged situations stable.** Casting and placement should not continually reshuffle while the player considers the same situation.

The backdrop can be selective only because the board retains complete tactical information. An uncast threat must not disappear from the board or be implied harmless.

### Rehearsal, capture and commitment

- **Announced:** the source's puppet rehearses its conditional danger without moving standees or depicting a completed outcome.
- **Captured:** remove that announced occurrence's rehearsal and transfer its recognizable action motif to player ownership. A surviving eligible enemy may announce again; its fresh rehearsal must remain distinct from the held action.
- **Released or otherwise resolved:** perform the actual ordered outcome, including failed acquisition or lethal backlash when those occur. Do not invent a successful attack, extra victim or displacement.

With no relevant interaction, the agent proposes a watchful protagonist and restrained lantern attention. Sneaking should accompany actual movement, not falsely imply movement during a decision. This idle-performance choice remains a hypothesis.

## First exploration and what it can establish

Start with the director's visual grammar before commissioning a puppet cast or runtime algorithm. The discussed scenario set is:

1. One direct announced threat.
2. Multiple threats with a player-caused capture/backlash or chain.
3. No immediate interaction.

The designer will define the smallest coherent visual presentation for human review. A static storyboard can test identity, relationships, staging and the difference between warning and outcome. It cannot establish motion quality, timing, stable automatic casting or runtime correctness.

The [first exploration brief](shadow-director-exploration-brief.md) proposes a single three-frame sheet: A rehearses from the left, B rehearses from the right, then A's announcement is captured while B continues. Board positions stay fixed; an unrelated actor remains visible on the board without a puppet. This first sheet deliberately does not cover the whole scenario set above, especially backlash chains and idle behavior.

Ronald reviewed the resulting sheet as **“at least a great starting point”** and specifically liked the unworldly glow emerging from the puppet when captured. Retain that supernatural capture-effect direction in subsequent exploration. This is positive direction-level feedback, not approval of complete tactical markings, final figures, automatic casting or runtime implementation. The captured action's destination and player ownership still need a clearer visual account.

After one handoff edit, Ronald said it still reads more like lantern decoration, but clarified that image generation need not reach perfection: **“90% is close enough for us to communicate the direction.”** Treat the current sheets as sufficient direction references and stop refining them. The quoted percentage expresses tolerance for illustrative misses, not a measured quality score or a formal acceptance threshold. The ownership effect remains an unresolved runtime/motion question; it is not a blocker to understanding the intended visual direction.

Keep concept candidates and inspection evidence under gitignored `.lore/local/`. Preserve approved source artwork and the accepted stage/floor. Description approval, image creation, exact-image approval and runtime integration remain separate decisions. No production batch or game implementation is authorized by this document.

Actionable work and blockers remain in Beads (`mind-garage-fy3`); the next mechanics item `mind-garage-7am` remains blocked. This note records intent and hypotheses, not a second task tracker.

## Proposed next checkpoint: play both layers together

After the one-source motion checkpoint communicated ownership clearly enough, Ronald asked to consider the complete playable relationship. He said the current map figures are imperceptible and need larger standee artwork. The next proposal therefore combines standee readability, source-marked board warnings and two simultaneous rehearsals with either capture choice—not another isolated effect clip.

The [draft playable-slice proposal](dual-layer-playable-slice-brief.md) uses an adjacent, same-column player/A/B encounter to expose overlap instead of arranging it away. Three distinct candidate standee silhouettes, true-cell foot anchors and accessible selection would make the actual board the place of play. Temporary puppet art would remain, with stable A-left/P-center/B-right theatrical identities.

This remains creative discussion. Ronald clarified that the agent should recommend a useful next step without interpreting broader scope discussion as permission to execute it. Candidate generation, processing and implementation are not yet authorized.
