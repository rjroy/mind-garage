---
title: "Borrowed Turns: playable dual-layer slice"
date: 2026-07-02
status: draft
tags: [borrowed-turns, playable-slice, standees, shadow-puppets]
related: [.lore/work/design/borrowed-turns-art/visual-systems-direction.md, .lore/work/experiments/002-shadow-paper/record.md]
---

# Borrowed Turns: playable dual-layer slice

**Candidate standee originals approved; playable implementation remains a draft proposal.** After explicitly requesting the art, Ronald reviewed the three generated figures together and selected **Use this set**. They are preserved unchanged under `games/borrowed-turns/assets/standees/two-pursuers/`, with source hashes and provenance. This approves candidate artwork, not a final cast or automatic implementation. Ronald identifies current map figures as imperceptible and the board as unplayable; that is a usability failure, not a request to refine the capture clip.

The parent owns the experiment record and Beads. No code, tests or game-view changes have started. The broader implementation discussion is separate from the explicit standee-art request.

## Deliver the whole playable situation

Use the **normal game scene and Stage controls**, with a visible encounter choice named **Two pursuers** and a direct launch option:

```sh
godot --path games/borrowed-turns -- --presentation=stage --encounter=two-pursuers
```

This is an intended entry point, not an implemented command. It must not require a separate capture-tool script. Selecting a different encounter during play requires an explicit new-run confirmation; changing presentation alone never changes the fixture or resets progress. Plain/paper remain usable comparison views of the same state. Preserve the current default paper startup.

The Stage actor sizing, placement and picking improvements belong to the real board renderer, not special recording code. The new fixture supplies the stress case rather than hiding a separate demonstration behind it. This is a candidate playable slice, not a claim of finished coverage for the original bolt/burst cast.

### One controlled encounter

Start with a **5×5 board**, no walls: player `[2,2]`, A `[2,1]` facing `[0,1]`, B `[2,3]` facing `[0,-1]`. Both use the existing shove: range 2, damage 1, push enabled. Both announced footprints contain the player. Both are initially within capture reach. Keep the three actors in this adjacent, same-column arrangement; do not move them into convenient separate lanes to hide occlusion.

Proposed fixture values: player 8 HP, pursuers 5 HP each, 2 AP, 2 MP, capture reach 1, exit `[4,4]` opening on turn 3. These are controlled content values for this encounter, not changes to shared rules or permanent balance findings. The model supplies all actual targeting, friendly fire, blocked pushes, displacement and outcomes.

The player can choose either enemy on the board, capture its announcement, hold/release/replace it, move, End turn, escape or lose, and restart. Preserve action/movement budgets, capture costs, deadlines, backlash and exact command assessment. The slice must continue functioning beyond its first capture; do not turn it into a prerecorded input sequence.

## The two layers have different jobs

**Board:** where actors actually are, what each announcement threatens, which action is legal, and what the selected command predicts. **Backdrop:** which player-related exchange is being rehearsed or performed, and who owns its action. Neither is a second independent simulation.

- Reuse temporary A/P puppet cutouts and the liked uncanny capture treatment. Obtain B and its hand motif by bounded extraction from B's existing second storyboard panel, not a new puppet generation or a substitute for new standee art. Preserve both storyboard originals and existing cutouts; no substantial repainting.
- Keep fixed theatrical identity slots: A left, player central, B right. These are not compass bearings. Their identities remain stable if board positions change.
- Both initial sources rehearse conditional pushes. A and B can have offset rehearsal phases, but neither current threat vanishes merely because the other is emphasized.
- Confirmed capture removes only that source's current board announcement and performance. Its map standee remains alive. The same source-marked hands leave that performer and settle beside the player's lantern with the mint glow. The other source continues rehearsing throughout.
- A surviving source can announce again later; a fresh occurrence and the old held occurrence remain distinct. Shared source ID plus announcement/capture turn identifies the occurrence.
- During play, relevance follows actual current model footprints, not the initial script: if neither announcement threatens the player's current position, performers become quiet/watchful rather than pushing at an imaginary victim. Selection highlights the matching performer; previews do not fabricate capture transfers or committed hits.
- Confirmed enemy resolution, release and backlash use the same existing shove motif and actual ordered events. Controlled release and uncontrolled backlash must remain distinguishable. Do not add bolt/burst puppet behavior, inferred damage, or a generic director framework.
- Map movement/displacement presentation follows model-authored events, settling exactly onto their cells. Align its feedback with the performed action instead of moving pieces to final positions disconnected from the story. Animation never determines legality, damage or displacement.

## Make the board genuinely playable

Large figures alone are insufficient. Start with substantially larger authored standees and a shallower depth-size gradient; do not shrink distant actors back into icons just to fit. Judge actual body, face/role silhouette and lantern readability at normal size and 1024×720 before claiming success. No unverified pixel minimum is prescribed.

Retain the approved stage construction, palette and floor material. Reallocate stage space toward the board and reduce unused floor margins; five rows provide more useful depth than seven. If additional depth is needed, move the floor/backdrop division moderately upward. **Declared tradeoff:** less puppet-screen space for larger playable pieces. Keep both performers and board readable together; do not merely repeat the small board under a large decorative theatre.

Keep feet anchored to the true projected cell centers, with depth-sorted upright sprites. Do not change logical positions or silently offset standees into other cells. Address the intentional overlap:

- A clear, source-marked paper foot tab remains visible and clickable for every actor, drawn above overlapping artwork. Its attachment to the actor's actual cell is explicit. No ordinary grounding shadows.
- Opaque sprite pixels select that actor's true cell; transparent padding does not steal neighboring floor clicks. Foot tabs and keyboard source selection provide direct access to partly hidden actors.
- Use a restrained contour for occluded rear pieces and temporarily reduce the occluding front piece's opacity when the player hovers/focuses the rear actor or its tab. No arbitrary swapping of draw order or moving actors apart.
- Keep P/A/B identifiers and HP separate from the raster art, with readable, nonoverlapping placement. Match A/B identifiers and badge shapes on board, puppet and held action; color is supplementary.
- Test actual body clicks, foot-tab clicks, keyboard focus and empty-cell targeting through the viewport. Input follows the shared projection and explicit actor hit geometry, not decorative bounding boxes. Finite resolution prevents duplicate commands and ends on the exact model state.

Use one restrained, source-marked board-warning language rather than accumulating hatches, arrows and decorative boxes. Preserve exact threatened cells, direction, overlapping-source identity, held backlash and preview outcomes. This is an integrated readability pass, not a separate telegraph asset batch.

Do not automatically cover the performers with the opaque preview sheet on every selection. Keep costs, important consequence warnings, held deadline and Confirm/Cancel visible. Complete ordered effects and plans remain explicitly accessible through Details; opening it may temporarily cover part of the performance screen, never the playable floor. Closing it preserves selection. This deliberately revises the former auto-open sheet behavior, not the obligation to expose exact outcomes.

## One consolidated candidate-art set

**Request three isolated raster standee images**, one each for player, A and B. Two distinct enemy silhouettes are worth the extra image: source letters alone would make the very confusion under investigation harder to diagnose. Reusing one enemy image twice is not the chosen starting point.

The images are **temporary candidate art for this playable slice**, not an approved production cast. Recommend **PNG**, not SVG: tactile paper material and cut-edge treatment are important here. SVG would be suitable for runtime badges, not the primary character artwork.

### Shared production description

- **Consumer/view:** full-body, upright paper standees on the actual perspective board. Nearly frontal three-quarter figure view, the same modest viewing angle for all three; not overhead characters, cinematic portraits or 3D figurines. Neutral alert standing poses, not attack poses. The expressive actions belong to the puppets.
- **Construction:** mature theatrical cut-paper figures, clear outer silhouettes, a few purposeful overlapping paper layers, restrained grain and warm cut edges. Playful craft without bobble heads, toy-store papercraft or tiny ornamental detail. Face, coat shape, hands and separate feet must survive reduction.
- **Palette:** plum, warm ivory, amber and rust, coordinated with the accepted stage. Use sufficiently light face/garment panels and edges to separate figures from its dark floor. No black-on-plum silhouettes requiring selection glow to become visible.
- **Framing:** request **1024×1536, 2:3 PNG** for each image. One figure only, centered; about 12% empty space at the sides, 8% above the head, and feet on a shared baseline about 86% down the canvas. Include the complete lantern, hands, coat and feet without clipping. Match adult proportions and approximate human height across the set; A's breadth and B's hood differentiate them, not arbitrary scale.
- **Background:** request uniform vivid green **#00FF00**, absent from the art, in every empty gap. No checkerboard, horizon, scenery, ground plane, cast shadow, pedestal, reflected green or translucent smoke. If genuine alpha arrives instead, verify it and skip removal.
- **Reusable source exclusions:** no lettering, A/B labels, health bars, telegraphs, grid, runtime glow or movement frames. No weapons, armor, fantasy emblems, invented artifact lore or lantern light-radius effect.
- **Unknowns:** final projected sizes, runtime texture budget and file-size budget remain unsettled until actual consumer inspection. Requested dimensions are not guaranteed tool output; record and disclose actual delivery.

### The three figures

1. **Player:** an ordinary adult in practical clothes, a narrow plain coat, short natural hair and a restrained rust scarf. Carry a recognizable warm lantern close to the viewer-right side of the body at waist height, not at the end of a wide outstretched arm. Warm ivory face/hands and a clear lantern opening. No spiky-haired fantasy hero, heroic cape or elaborate adventurer equipment.
2. **A:** a broad-shouldered pursuer in a structured plum coat with a distinct angular/notched ochre collar and warm ivory inner panel. A compact, uncovered head; hands relaxed and visible. Strong rectangular upper-body silhouette, clear feet, no enormous cape or weapon.
3. **B:** a narrower pursuer with a rounded deep-aubergine hood, a visibly split coat hem, restrained rust trim and a light inner panel/face opening. Distinct from A even when only the upper half is visible. Hands relaxed, feet clear; no glowing eyes, weapon or added supernatural anatomy.

These are bounded pilot hypotheses about readable identities, not claims that existing temporary puppets already match final costumes exactly. Runtime badges and lantern continuity bridge the provisional media.

### Route, references and approval

After approval, use **three built-in `experimental_image_generate` calls**, one per figure, applying the shared description and corresponding role paragraph. No automatic variants, rerolls or new poses. Use the supplied forest/lantern reference for construction and standee quality; the approved stage/floor images for palette/contrast; and the existing director storyboard for A/B/P associations, not heroic clothing, ordinary shadows or exact character approval. Compare the three actual outputs for scale, view, construction and silhouette before candidate use.

Proposed originals:

```text
.lore/local/experiments/002-shadow-paper/dual-layer/standees/player-candidate.png
.lore/local/experiments/002-shadow-paper/dual-layer/standees/enemy-a-candidate.png
.lore/local/experiments/002-shadow-paper/dual-layer/standees/enemy-b-candidate.png
```

The requested approval includes necessary, separately preserved green removal/crop-padding derivatives for **this candidate pilot only**, plus bounded extraction of existing B puppet material. Preserve originals; verify actual alpha, fine gaps and halos over light/dark/real floor backgrounds. No substantial repainting or redesign to rescue unusable outputs; report material blockers instead.

Inspect and record each actual candidate, but **do not stop for three separate taste approvals**. With explicit authorization for the defined set and its use in this isolated visual pilot, proceed to the combined playable review. Exact-version source approval and promotion into the game's approved asset directory remain separate gates afterward. No silent promotion or inference that the cast is final.

## Practical implementation and verification boundaries

Use the existing encounter UI/model/shared presentation controller. Add a real two-pursuer fixture/entry and a Stage standee-rendering/picking profile; keep those responsibilities out of the one-source recording tool. Reuse temporary puppet material and occurrence logic in a bounded two-source presenter, rather than stacking two complete scenes or inventing a new rules/timing controller. Source/current announcement, transfer, held, release, backlash and committed resolution remain separate model-authored states.

Focused tests precede behavior implementation: controlled source-owned footprints; capture either source without canceling the other; fresh announcement plus old held occurrence; failed/lethal acquisition and generation reset guards; actual actor/tile hit geometry and overlap access; unchanged state/prediction/history across view changes; and exact snapshot settlement after motion. Use test-owned alpha textures for unit picking/layout tests, not mutable art/tuning. Extend meaningful existing coverage rather than duplicating the full C01–C03 matrix.

The independent tester owns behavioral RED/GREEN and actual viewport interaction/render evidence at 1024×720 and a normal-size view. Verify same-column depth overlap, selection through visible artwork/tabs, warning ownership, source-to-held continuity, either capture choice and continuing play through release/End turn/restart. Test source loading explicitly: no candidate pack means a clear setup error, not another primitive-art fallback. Fresh correctness and engineering review follow; preserve plain/paper and existing rules.

**One combined human checkpoint:** Ronald plays the encounter, identifies himself and both pursuers, reads both threats, chooses either standee to capture, and explains what stopped, what continues and what he now holds. Then he continues the run and can replay the other choice. Record confusion and ease of acting separately from whether he likes the art. Stop for that actual playable review, not another isolated clip or an assertion that technical passes establish playability.

**Discussion status:** the playable slice remains the recommended next direction, not an implementation request. Its purpose is to test whether readable board actors and selective theatrical rehearsal explain the same exchange without competing or confusing ownership. The three standee candidate generations were explicitly requested and are underway; exact artwork approval, processing/promotion and playable implementation remain separate decisions. No runtime work is being started from the wider discussion alone.
