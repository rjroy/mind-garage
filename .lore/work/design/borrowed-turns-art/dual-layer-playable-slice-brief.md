---
title: "Borrowed Turns: playable dual-layer slice"
date: 2026-07-02
status: draft
tags: [borrowed-turns, playable-slice, standees, shadow-puppets]
related: [.lore/work/design/borrowed-turns-art/visual-systems-direction.md, .lore/work/experiments/002-shadow-paper/record.md]
---

# Borrowed Turns: playable dual-layer slice

**Candidate standee originals approved; playable slice implemented and technically verified, awaiting human review.** After explicitly requesting the art, Ronald reviewed the three generated figures together and selected **Use this set**, then **Build the playable slice**. The originals are preserved unchanged under `games/borrowed-turns/assets/standees/two-pursuers/`, with source hashes and provenance. This is candidate artwork, not a final cast. Ronald identified the preceding map figures as imperceptible and the board as unplayable; that is the usability failure this slice investigates, not a request to refine the capture clip.

The parent owns the experiment record and Beads. The proposal and test-first contract below preserve the agreed scope; the final section records the implemented candidate. Technical checks do not establish that the usability failure is solved.

## Deliver the whole playable situation

Use the **normal game scene and Stage controls**, with a visible encounter choice named **Two pursuers** and a direct launch option:

```sh
godot --path games/borrowed-turns -- --presentation=stage --encounter=two-pursuers
```

This entry point is implemented and uses the temporary puppet pack documented below. It does not require a separate capture-tool script. Selecting a different encounter during play requires an explicit new-run confirmation; changing presentation alone never changes the fixture or resets progress. Plain/paper remain usable comparison views of the same state. Preserve the current default paper startup.

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

### Approved slice: test-first join contract

Ronald subsequently selected **Build the playable slice** after approving the standee set. Implementation of the defined encounter is authorized, beginning with controlled tests and neutral setup before independent behavioral RED. This section supersedes earlier discussion-only implementation status, not the limits on new artwork or source changes. Approved stage and standee PNGs remain immutable. The parent owns tracking and later implementation assignments.

**Small implementation boundary:** normal encounter UI plus a separate two-pursuer content fixture; one board standee-rendering/picking profile; and a bounded two-source puppet rig using the existing controller's progress. Preserve the original encounter, paper default and plain/paper fallback. Do not route this through the old standalone motion-study entry. Board-space allocation may change for readability, trading some backdrop area for larger actors without abandoning either layer. Actual minimum-size and normal-size renders, not unit constants, decide whether this succeeds.

**Canonical actor identities:** `player`, `A`, `B`. Use these everywhere, including standee texture keys, board descriptors, puppet source IDs and held ownership. `A` and `B` refer to stable identities, not board compass directions. The pure presentation lane owns `ui/two_pursuer_presentation.gd` and its focused test; it consumes model/controller facts only.

**Board seam, `ui/board.gd`:**

```gdscript
func configure_standees(textures: Dictionary, assembly: Dictionary) -> bool
func standee_layout() -> Array
func actor_at(local_pixel: Vector2) -> String
func pick_cell(local_pixel: Vector2) -> Array
func focus_actor(actor: String) -> void
```

- `textures` maps the three canonical IDs to `Texture2D`. `assembly` maps each ID to `{canvas: Vector2, foot: Vector2, height_fraction: float}`. Canvas and foot are **native source pixels**; `height_fraction` sets full-canvas rendered height relative to `_stage_rect().size.y`, not a minimum readable size. Aspect stays unchanged. This compact metadata suffices for three unmodified images; no rigging/import framework or derivative is needed. Production anchors are measured against the accepted source feet and checked in the actual consumer, not hardcoded into unit expectations.
- Reject missing textures, invalid anchors/scales and native-canvas mismatch. A failed reconfiguration clears stale standee art. Successful configuration retains injected textures; do not silently fall back to primitives in this selected encounter.
- `standee_layout()` returns detached rows for living actors **in actual back-to-front draw order**: `{actor: String, cell: Array, rect: Rect2, foot: Vector2, tab_rect: Rect2, opacity: float, texture: Texture2D}`. These are the drawing and picking inputs, not a parallel test fiction. `rect` covers the full original canvas; source `foot` maps exactly onto `cell_center(cell)`. `tab_rect` is the actual visible, separately drawn source marker, attached to that foot. Tabs must remain individually accessible in the same-column case.
- `actor_at` gives source tabs priority over bodies, then tests body pixels in reverse draw order with alpha at least `0.1`. Transparent padding/interior gaps click through. Accepted source bodies are near-opaque, not exactly alpha 1. `pick_cell` returns that actor's true cell, otherwise the existing floor inverse mapping. `_from_pixel` remains **floor-only**, so projection tests and empty-floor semantics do not change. Actual GUI motion/clicks consume the shared picker.
- `focus_actor` reaches the actor's true cursor cell and emits inspection only, never a command. Empty ID clears actor emphasis; stale IDs cannot resurrect pieces. Bracket keys cycle living identities; existing arrows and Enter remain available. Rear-source focus/hover exposes that actor by reducing front occluders' opacity without moving pieces or arbitrarily changing draw order. Clearing focus restores normal opacity. Non-Stage views have no standee draw/hit regions.

**UI seam, `ui/encounter_ui.gd`:**

- `encounter_id: String` defaults to `"escape"`. `encounter_picker: OptionButton` is a real visible control in all views, item metadata `"escape"` / `"two-pursuers"` with grounded labels. `encounter_dialog: ConfirmationDialog` protects selecting a different encounter. `request_encounter(id: String)` asks for confirmation without changing state; cancel preserves state and restores the selection; confirm configures the chosen content, clears the old run and updates identity. Restart uses the currently selected fixture. Presentation changes do not change fixture identity or progress.
- Parse `--encounter=escape|two-pursuers` in normal startup; invalid values fail clearly. The selected encounter and view are reflected in controls. A new fixture does not replace or modify `content/escape.gd`.
- Selection does not auto-open the opaque stage sheet. `_stage_plans` remains the explicit Details toggle and opens Preview when a prediction exists, otherwise Plans. Costs, consequences, held deadline, confirmation/cancel remain visible. Exact ordered preview text is still accessible before committing; Details stays above the floor. Existing stage smoke is adjusted only to open this explicit preview before its existing visibility assertions.
- Neutral setup before RED needs only loadable methods, `encounter_id="escape"`, an attached selector with these metadata choices and a dialog. Their callbacks may be inert; no fixture switching, startup selection, art loading or layout changes belong in setup. Neutral board configuration returns `false`, layout `[]`, actor hit `""`, floor picker delegates to `_from_pixel`, and focus is inert. Existing behavior remains unchanged. Missing APIs exit 2 rather than being misreported as behavioral failures.

**Temporary puppet route:** reuse the verified native A/P cutouts, and later extract B body/hands from the original storyboard's second panel within the already authorized bounded preparation. Keep all derivatives local. A pack contains `a-body.png`, `a-hands.png`, `b-body.png`, `b-hands.png`, `p-lantern.png`; native source-pixel hinges, canvases and player/held anchors live in the compact rig assembly, following the existing one-source study convention. Explicit `--puppet-pack=<absolute-directory>` overrides the default repository-local `.lore/local/experiments/002-shadow-paper/dual-layer/puppets`. Do not require a new tool script. Validate files, decode/alpha and assembly dimensions on load and log attempt/outcome. No silently committed temporary derivatives, tiny-shape fallback or generated manifest framework. Missing local pack is a setup error: command-line selection exits clearly; chooser selection reports the problem and preserves the current run. Fresh checkout alone cannot provide the temporary puppets; document the required pack and actual launch arguments.

**Both capture choices are visual acceptance cases:** stage-right B's inward-facing hands must visibly stop attacking, travel to player ownership and settle facing outward beside the lantern, rather than continue pointing at the player. Preserve recognizable B identity and uncanny glow without treating the lantern as a new mechanic. The rig may orient/position the temporary motif appropriately in this nonliteral theatre. Verify A and B capture in actual motion; do not freeze hand angle, travel duration or endpoint pixels as model rules.

**Neutral setup and temporary pack prepared:** board seams are inert (`false`, `[]`, `""`, floor-only picker, no-op focus); the real encounter selector/dialog exist with the agreed metadata, but the selector is hidden and request is inert to preserve existing layout/behavior before independent RED. No fixture, parser, standee rendering or puppet performance has been implemented in this setup.

The five-file pack is now at the default local directory above. A/P were copied byte-for-byte from the verified study. B body/hands use the original storyboard's panel-2 crop `290x145+580+580`, region masking and the established 37% dark-silhouette alpha extraction; no RGB recoloring, generated repair or source changes. Native B body+hands reassemble with **AE=0** and RGB comparisons against the source crop are **AE=0**. Two final recipe runs matched every pack hash. ImageMagick **7.1.2-34 Q16-HDRI**, build `c5d4ca8a0:20261014`.

| Local pack file | Native canvas | SHA-256 |
| --- | --- | --- |
| `a-body.png` | 290×145 | `183a86540b7611c47b8a8de3ba6da791e3c78e6025a9b38109c474defa1c0e3e` |
| `a-hands.png` | 290×145 | `3396932a1a8ae490b217100c79ce55a1490bde376c7896a62b6450f9f85b564f` |
| `b-body.png` | 290×145 | `c9644ebc272d865f11c0ff2d9d7533e537766a9c2f0a3c188034a34779020c36` |
| `b-hands.png` | 290×145 | `0559331e196e085b5bdc6f24d4a00629e5c47d589b4218c735ac347cc97aeca7` |
| `p-lantern.png` | 145×145 | `0675257136cff1f7375b8b621dffb64f4296940e29fe3b9ddf9c4e6a4cf0f588` |

Compact source-pixel assembly: A baseline `(105,145)`, hand hinge `(171,96)`; B baseline `(180,145)`, hinge `(119,87)`; player baseline `(56,145)`, lantern handle `(105,60)`. Each body/hand pair shares its full native canvas. The player-relative held hinge starts at `(143,74)`, outside the lantern; B's held instance can mirror about its hinge at runtime to face outward, preserving the source file. These are visual assembly inputs, not gameplay facts or frozen animation angles.

Exact local recipe `prepare-pack.sh`, SHA `ffebf1cbe5c333cac9b25057a8d355eb157fe50a3dc351d7897d7bfce035b5cf`; inspection recipe `inspect-pack.sh`, SHA `b0e83dacbaf8d22a2be7fe60dbd3a96079b958e368a3f9ef0e8c222714d2bdc9`. Both live beside the local pack. Native/light/dark and `inspection/stage-static-composite.png` were inspected. The latter is an explicitly labeled static overlay on an old runtime capture, not the new encounter or motion proof. Hood, hands and joint details survive the intended parchment presentation; dark-background contrast and clipped lower edges remain known temporary-material limits. No further art processing is required for focused UI preflight.

**Focused test ownership and commands:**

- Designer: `tests/standee_board_run.gd`, controlled synthetic RGBA textures and source-pixel anchors, no live art/content. Verify real descriptor geometry, native registration/aspect, depth, alpha/gap picking, tab access, focus, resize/dimensions and stale actor removal.
- Designer: `ui/smoke.gd --focus=two-pursuers`, actual chooser/normal scene, approved-art loading and injected viewport body clicks for either capture, exact assessment/commit, explicit Details, continued End turn/release, view parity, selected-fixture restart and terminal replay. `--focus=two-pursuers-cli --presentation=stage --encounter=two-pursuers` separately checks actual startup selection.
- Independent pure lane: `tests/two_pursuer_presentation_run.gd` and the detached `compose(snapshot, frame, generation, source_ids, inspected_source)` contract. No duplicate event-algorithm matrix in the board runner.
- Author runs syntax only. Independent tester runs behavioral RED after neutral setup, freezes hashes, then GREEN/regression and rendered viewport evidence after implementation. Optional smoke `--capture-dir=<fresh-local-directory>` produces labeled evidence for actual human review, not approval by screenshot assertion.

Focused tests precede behavior implementation: controlled source-owned footprints; capture either source without canceling the other; fresh announcement plus old held occurrence; failed/lethal acquisition and generation reset guards; actual actor/tile hit geometry and overlap access; unchanged state/prediction/history across view changes; and exact snapshot settlement after motion. Use test-owned alpha textures for unit picking/layout tests, not mutable art/tuning. Extend meaningful existing coverage rather than duplicating the full C01–C03 matrix.

The independent tester owns behavioral RED/GREEN and actual viewport interaction/render evidence at 1024×720 and a normal-size view. Verify same-column depth overlap, selection through visible artwork/tabs, warning ownership, source-to-held continuity, either capture choice and continuing play through release/End turn/restart. Test source loading explicitly: no candidate pack means a clear setup error, not another primitive-art fallback. Fresh correctness and engineering review follow; preserve plain/paper and existing rules.

**One combined human checkpoint:** Ronald plays the encounter, identifies himself and both pursuers, reads both threats, chooses either standee to capture, and explains what stopped, what continues and what he now holds. Then he continues the run and can replay the other choice. Record confusion and ease of acting separately from whether he likes the art. Stop for that actual playable review, not another isolated clip or an assertion that technical passes establish playability.

### Implemented candidate and author inspection

The normal game now supports `--encounter=two-pursuers` and a visible confirmed-new-run chooser. Its wall-free content is separate from the protected original escape fixture; the same model/controller owns every command, prediction and outcome. Plain/paper remain available and paper/escape remain startup defaults. Missing temporary pack material is a clear setup error rather than a primitive fallback. See the game README for the exact launch command, local prerequisite and controls.

The board consumes native standee textures and anchors through its actual draw/pick descriptors. Source images are unchanged. The candidate uses full-canvas height `.28` of fitted stage height, a shallower five-row board quadrilateral (`.23,.54 / .77,.54 / .79,.90 / .20,.90`) and an extended ungridded apron. This retains the visual floor seam while giving faces room below the performance. It trades depth-row separation for much larger actors; same-column torsos intentionally overlap, with distinct heads, visible source/HP foot tabs, alpha picking, rear-source emphasis, bracket-key access and explicit Alt-floor targeting. Contextual GUI input also permits a legal floor target behind an otherwise-illegal actor target; the pure actor-first picker and floor inverse remain separate and unchanged in meaning.

Temporary puppets use one player and two stable source slots. The shared pure descriptor supplies current relevance, captured/held occurrence identity and ordered actual cue events. Idle loops do not own a second clock or hold gameplay busy. Non-player-only resolutions keep the player unreached/unreacting; actual damage/displacement facts, not an enemy simply taking a turn, justify player reaction.

Final held placement is player-native `(151,25)`, above/beside the lantern handle, at `.45` source scale. B's same cutout turns continuously through a half-turn and remains outward-facing while held; no source mirroring/repainting or new pose asset was needed. A single placement correction after actual inspection separated held hands from B's continuing inward rehearsal and moved the conditional floor caption left of the stacked figures. These are candidate presentation choices, not model rules or frozen timings.

Author checks: focused board **171/0**, real-scene UI **202/0**, startup CLI **7/0**. The independent tester corrected only the board unit's claimed empty-floor sample from an actually covered cell to `[1,0]`; production picking/size was not tuned to appease it. Frozen test bytes are preserved after that independently authorized correction. Full independent regression, rendered gate and fresh correctness/engineering review follow the source freeze.

One fixed-30-fps graphical author inspection produced 13 actual frames at 1024×720 and 1600×900, **60 checks/0 failures**: both initial captures, the other continuing rehearsal, outward B-held orientation, exact Alt-floor movement, watchful sources after stepping out of both threats, a real A→B damage/displacement cue with no player-hit reaction, and model-correct replacement failure. A focused four-frame held-placement recheck inspected the single collision correction. Evidence remains under `/tmp/opencode/borrowed-turns-dual-layer-author-render/` and `...-author-held-placement/`; it can be regenerated through the real game controls described above. These are author diagnostics and injected input, not physical-input evidence or human playability/style acceptance.

**Current status:** independent checks and technical review passed; one combined human play review remains. The full rendered gate passed 648/0 after a test-only normal-layout wait; focused slice UI passed 202/0 and missing-pack chooser preservation passed 8/0. Fresh correctness review found no material defect; separate refactor and engineering-quality assessments required no further changes. The attempted comparison recording failed startup-delta validation and is not valid motion evidence. See the experiment record for failure history and reproducible commands.

Large figures still occlude one another's torsos in the intentional same-column case; temporary puppet costumes/resolution do not match the approved standee cast fully. No additional asset generation, source promotion or visual-polish loop is implied. Ronald's combined clarity/taste judgment and separate runtime acceptance remain outstanding.
