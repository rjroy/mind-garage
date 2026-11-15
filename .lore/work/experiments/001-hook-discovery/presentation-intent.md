---
title: "Borrowed Turns: presentation musings and core-mechanic boundary"
date: 2026-11-15
status: draft
tags: [game-design, visual-experiment, intent, player-feedback]
related: [.lore/work/design/borrowed-turns-art/borrowed-turns-shadow-paper-brief.md, .lore/work/experiments/001-hook-discovery/design-revision-02.md]
---

# Borrowed Turns: presentation musings and core-mechanic boundary

## Context and authority

Ronald supplied the art exploration in `.lore/work/design/borrowed-turns-art/`, committed separately at `4727f30`. After review, he clarified that these notes should be read as **intent or musings to inform our own intent-building, not binding implementation requirements**. Preserve the supplied documents and their provenance rather than retroactively rewriting them into a technical specification.

Their statements about unseen or unsettled implementation are not evidence that the current R2 implementation does not exist. Conversely, current placeholder implementation should not dictate every future artistic or mechanical choice. Distinguish what has actually been built, what the player has decided, and what remains exploratory.

## Shadow ownership

Ronald confirmed that capture steals one announced action. The enemy gets its animated action-shadow back **if it can announce again**. Do not portray capture as permanently removing the enemy's ability or silhouette. This clarification concerns the communication of announcement ownership; it does not authorize additional art production by itself.

## Shadow placement and ability geometry

The review proposed preserving existing release geometry as a constraint. Ronald explicitly left this open to agent discretion, experiment, or both. Do not elevate the current origin/target geometry into an immutable art requirement. Equally, do not silently change gameplay while claiming to compare presentation alone: any geometry experiment should state which mechanics changed and what is being compared.

No question about shadow placement blocks removal of Invert. A future visual slice can choose a bounded interpretation and record its assumptions and evidence rather than requiring another exhaustive interview.

## Invert is not core

Ronald explicitly directed: **take Invert out**. It belongs, at most, to future unlock exploration, not the active baseline. The agent repeatedly carried the preview forward without sufficient reason; this is corrective human design input, not a feature independently rejected through automated tests.

Remove the live toggle, pull/inversion command support and startup option, active-state metadata, obsolete instructions, and superseded test expectations. Preserve ordinary shove/push behavior, ability-specific backlash, and meaningful preview synchronization coverage. Do not hide the feature behind a flag or retain it as a default-off bonus.

The original and revision-02 archived sources, concepts, logs and screenshots remain historical evidence. References to Invert in those immutable records do not authorize reintroducing it. Future exploration would need a new, explicit scope.

## Current execution boundary

Task `mind-garage-wdx` covers removing Invert and recording this clarification. No image generation, new finished assets, Blender work, shadow animation, runtime art integration, or final style selection is included. The other R2 capture/backlash rules remain unchanged by this focused removal.
