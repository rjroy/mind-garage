---
title: "Borrowed Turns: shadow-director visual exploration"
date: 2026-07-02
status: completed
tags: [borrowed-turns, concept-art, shadow-puppets, visual-exploration]
related: [.lore/work/design/borrowed-turns-art/visual-systems-direction.md, .lore/work/experiments/002-shadow-paper/record.md]
---

# Borrowed Turns: shadow-director visual exploration

## Status and purpose

**Description approved; the one authorized image has completed, concept approval pending.** Ronald explicitly selected **Generate the storyboard** after presentation of the three-frame description. This approves the brief and one exploratory call, not the resulting concept, puppet production or runtime implementation. Actual output is a decoded 1024×1536 RGB PNG, below the requested approximately 1536×2592. It remains unchanged in the local candidate path below; inspection must disclose its tactical/ownership mistakes rather than count the image as algorithm evidence. The parent owns the wider systems note; this brief defines only the first visual checkpoint.

The accepted stage/floor runtime at `dcbd13e` is the visual anchor, not a redesign target. Prior stage and source-art approval does not approve puppet designs or this image. The separate authorization above covers one generation only; no runtime changes, source processing, dependencies or asset batch is included.

**Question:** Can a selective, left-to-right puppet performance remain clearly connected to an exact front-to-back board situation, without reading as a second tactical map or an attack already happening?

## Smallest meaningful deliverable

**One concept storyboard sheet with three vertically stacked, wide stage frames**, using one unchanged encounter and provisional cast throughout. Request a portrait PNG around **1536 × 2592**, with each frame approximately 16:9. These are requested concept dimensions, not a runtime budget or guaranteed tool output. Review individual frames at readable size, not just the whole reduced sheet.

This is one authored example of proposed directorial choices, not a working algorithm. It deliberately tests depth compression, selective casting, stable screen positions and stolen-action ownership together. An isolated puppet portrait would not test their relationship.

### Controlled illustrative encounter

Use a seven-column, seven-row board, with coordinates `[x,z]`: x increases rightward; z increases toward the front. This is illustrative existing-rule material, not a change to production content or a new movement/attack rule.

| Figure | Board position | Current announcement |
| --- | --- | --- |
| P, ordinary protagonist | `[3,3]` | Initially holds no action. Carries a lantern visually; its artifact/mechanical role remains undecided. |
| A, pursuer behind P | `[3,2]` | Existing shove, forward along +z, range 3: threatened cells `[3,3]`, `[3,4]`, `[3,5]`. |
| B, pursuer in front of P | `[3,5]` | Existing shove, backward along -z, range 3: threatened cells `[3,4]`, `[3,3]`, `[3,2]`. |
| C, unrelated pursuer | `[5,1]` | Existing shove rightward, range 1: threatened cell `[6,1]`; no current player interaction. |

No walls, damage numbers, turn-budget values or invented outcomes are needed. A and B's announcements both threaten P's current cell. Their rehearsals are separate conditional warnings, **not a claim that both attacks will hit in a complete turn**. Ordered resolution, displacement and collateral interactions are outside this sheet.

### Three frames

1. **A rehearses.** The board shows all four standees and all three announced footprints. On the backdrop, P is central, A is on stage-left performing a richly articulated pushing gesture, and B remains poised on stage-right. C has no puppet. A's gesture stops short of contact; P is not hurt, moved or knocked over.
2. **B rehearses.** Repeat the board, standee positions, all footprints and puppet stage positions exactly. B now performs the pushing gesture inward from stage-right; A is poised. This is another instant of the same rehearsal cycle, not a turn advance. The board's behind/in-front relation has deliberately become left/right theatre staging.
3. **A's announcement captured.** No standee moves. Remove only A's board announcement, leaving B and C's footprints. A's performing puppet is absent, its left slot left vacant rather than moving B across the screen. The same distinctive A forearms/open hands appear gathered beside P's lantern, visibly marked A and now under P's ownership. B continues its conditional rehearsal. A remains on the board: it is not dead or permanently disabled, and may announce again later.

## Construction and readability

- Preserve the approved theatre's arches, leafy frame, plum/amber/rust paper and registered floor/backdrop arrangement across frames. No new setting, camera treatment or stage layout.
- Standees are quiet, comparatively simple, flat paper pieces. Puppets are elaborate, articulated silhouette constructions inspired by Japanese shadow puppetry, unmistakably different from enlarged standees. No weapons, heroic armor, spiky-haired hero treatment or new costume lore.
- Use temporary, repeatable identity cues: P's plain coat and lantern; A's broad shoulders and notched collar; B's rounded hood and split hem; C's narrow silhouette. Put P/A/B/C beside the standees and the corresponding performing puppets; retain A beside the captured hand motif. These are provisional concept cues, not accepted character designs. Color is supplementary, not the only ownership link.
- Keep both board depth separation and stage left/right separation legible. No connecting rays that imply physically cast shadows or a literal projection from standees.
- Board marks are factual comparison guides, not a new telegraph-art proposal. Preserve every announcement, including C's, until its specifically described removal. The puppets may be selective; the board must not hide tactical facts.
- No ordinary figure shadows, completed hit poses, damage flashes, spell projectiles, lantern light-radius boundary, interface-heavy screenshot or elaborate explanatory lettering. Restrict in-image text to frame numbers, the brief captions below and actor identifiers.

Suggested captions: **“1 · A rehearses”**, **“2 · B rehearses”**, **“3 · A captured; B still threatens.”** Explain outside the image that all rehearsals are conditional and stage positions are theatrical, not map bearings.

## Creation route and authorized reference strategy

After description approval and explicit one-image authorization, use the built-in `experimental_image_generate` tool once. Omit a model override. Suggested reference order:

1. `/tmp/opencode/borrowed-turns-stage-independent-rendered/stage-1600-encounter.png`: inspected current-session runtime reference for the accepted stage/floor composition and perspective. Ignore its HUD, primitive figure treatment and production actor positions; preserve its theatre arrangement.
2. `games/borrowed-turns/assets/stage/backdrop-paper.png`: approved rear architecture and puppet-screen material.
3. `games/borrowed-turns/assets/stage/foreground-paper.png`: approved frame silhouette and open area.
4. `games/borrowed-turns/assets/stage/floor-paper.png`: approved floor material, not a painted grid.
5. `.lore/work/design/borrowed-turns-art/lantern-hero-in-the-shadow-forest.webp`: original elaborate puppet/standee contrast and lantern taste anchor, not authority for heroic costume, ordinary shadows, attacks or stage geometry.

The temporary runtime capture is discussion evidence, not a required checkout asset. It can be regenerated with the existing `ui/smoke.gd -- --focus=stage --capture-dir=<fresh-local-directory>` graphical capture command when authorized; use the resulting `stage-1600-encounter.png`. Do not silently replace the runtime composition reference with the earlier, different concept-stage layout if the temporary capture is unavailable.

These guide one composite exploratory sheet; do not extract, modify or overwrite the approved sources. Use `.lore/local/experiments/002-shadow-paper/director-exploration/storyboard-candidate.png` as the proposed separate candidate path. No transparency or runtime derivative is needed.

### Generation prompt

> Create ONE exploratory concept storyboard sheet for Borrowed Turns, not production assets or a game screenshot. A tall portrait sheet, requested 1536 × 2592, contains THREE equal wide 16:9 theatre frames stacked vertically with narrow caption gutters. Each frame repeats the same fixed stage architecture, floor perspective and cast design. The first reference fixes the accepted runtime theatre/floor composition, not its HUD, primitive figures or actor positions. Match the supplied approved backdrop, foreground and plum paper floor; do not redesign their composition. Use the last reference only for elaborate shadow-puppet construction, simple standees and lantern appeal. No normal cast shadows.
>
> In every board, seven columns and seven rows. View the floor in the fixed theatre perspective, with the back at the top. Place ordinary protagonist P at [3,3], pursuer A behind P at [3,2], pursuer B farther toward the front at [3,5], unrelated pursuer C at [5,1]. Coordinates start at zero. A announces a forward shove through [3,3],[3,4],[3,5]. B announces a backward shove through [3,4],[3,3],[3,2]. C announces a rightward shove at [6,1]. Quiet standees never move between panels. Show precise restrained board warnings with dashed direction arrows and P/A/B/C identifiers. No invented attacks, weapons or damage.
>
> ABOVE the board, on the warm parchment backdrop, stage elaborate flat articulated dark shadow puppets. P stays central with a lantern; A stays stage-left; B stays stage-right, although their standees are behind/in front of P on the board. C remains on the board but is not cast on the backdrop. These are theatrical positions, not compass directions. Repeat the same provisional identities: P plain unarmored coat, A broad shoulders/notched collar, B rounded hood/split hem, C narrow. Label performing puppets with their corresponding identifiers. Their ornate silhouette language differs from the simple standees. Avoid the fantasy-hero costume of the reference.
>
> FRAME 1, caption “1 · A rehearses”: A extends expressive oversized articulated forearms and open pushing hands toward P, stopping short of contact. B is poised at right. P remains watchful, unharmed and stationary. All three board announcements remain.
>
> FRAME 2, caption “2 · B rehearses”: same board, same warnings, same cast positions; B now rehearses an inward push from stage-right while A is poised at left. This is not an actual hit or completed turn. No board movement.
>
> FRAME 3, caption “3 · A captured; B still threatens”: all four standees remain in their exact places. Remove A's board warning ONLY; keep B and C warnings. A's backdrop puppet is absent and its stage-left place remains vacant. The exact recognizable A forearms/open-hand silhouette, still identified A, is gathered beside P's lantern with a restrained pale-mint ownership accent. This is a proposed visual handoff, not a magic projectile or lantern rule. B stays at right rehearsing its warning toward P. No release, backlash, death or completed shove is shown.
>
> Make the board-to-puppet identities and the depth-to-left/right translation readable at a glance. Use sophisticated textured paper, rich plum/amber/rust stage framing and crisp intricate dark silhouettes. No decorative substitute for factual board marks, no interface panels, no extra puppet C, no duplicated figures, no changing set between frames. Do not imply literal lighting projection, permanent enemy disarmament, lantern radius or completed damage. Keep lettering minimal.

## Review and limits

Parent reviews this description before asking for approval and one generation. After generation, verify decode/dimensions, inspect the actual image and report any mistaken cells, cast, ownership or stage drift before presenting the exact candidate. If the image misses a requirement, disclose it; do not silently regenerate or treat it as evidence that the director algorithm works.

The human checkpoint asks whether the relationship feels coherent: can Ronald identify the active actor, understand the theatrical spatial translation, recognize a warning rather than an outcome, and follow the stolen action without interpreting A as permanently disabled?

A still sheet cannot establish motion/rehearsal rhythm, fair automatic relevance selection, stable casting during arbitrary play, reaction to selected command previews, ordered multi-actor resolution, no-interaction idle, deadlines/backlash, or production feasibility. Those remain later bounded questions. Liking this concept approves neither a puppet asset library nor runtime implementation; exact-version concept approval and any next creation/integration authorization remain separate.

## Human reaction to the first sheet

Ronald called it **“at least a great starting point”** and specifically liked **“the unwordly effect that glows out of the shadow puppet when captured.”** Preserve that supernatural glow direction rather than treating every deviation as something to remove. The current sheet remains a partial staging study: the feedback does not establish that captured ownership/destination or board threat changes are sufficiently clear. No further image generation, production or runtime integration was authorized by this reaction.

## Targeted ownership edit

Ronald subsequently said **“continue”** in response to refining the capture handoff while preserving the liked glow. This authorizes one narrow edit of the existing storyboard, not a new asset batch or runtime work.

The designer's edit changes only panel 3's captured motif: remove its floating stage-left hands and place one compact folded version around the upper frame of P's lantern, with the A identifier and mint tendrils binding around the handle. Keep the lantern and flame recognizable. This depicts a settled held action, not a projectile or travelling duplicate. A remains alive on the board; B's rehearsal continues; the former A performance slot is vacant. Panels 1/2, the stage/floor, captions, figures, board marks and lantern position are to remain unchanged.

The original stays intact. The one experimental image edit completed with the existing sheet as its only input and a separate local `storyboard-ownership-candidate.png` output: 1024×1536 RGB PNG, SHA-256 `0e9c129f1f208153d862905e26eff6e2bb7fd9f6a1227459c92a2f9ee6803912`. It decoded successfully. Upper panels are not pixel-identical, so actual visual preservation and ownership clarity require inspection before presentation. Existing board-footprint and character-design limitations are deliberately not being repaired in this pass.

## Stop condition reached: direction communicated

Ronald judged the revised hands more like lantern decoration, but explicitly said generated concepts need not be perfect: **“90% is close enough for us to communicate the direction ... ai image gen is not yet perfect.”**

The sheets are sufficient to communicate the exploration's direction. Stop further static-image refinement. Preserve the liked uncanny capture glow and nonliteral selective staging as references; carry the unresolved ownership question into a separately scoped motion/runtime test rather than seeking a perfect generated still. This is acceptance for direction communication, not a claim that the depicted handoff works or authorization for production assets, animation or integration.
