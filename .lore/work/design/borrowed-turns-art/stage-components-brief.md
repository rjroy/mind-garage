# Borrowed Turns: first stage component

## Scope and approval

First component: **one floor artwork candidate only**. Bead: `mind-garage-fy3`.

Ronald liked the stage candidate and approved starting the 2D projected-board approach. He subsequently explicitly selected **Generate the floor**, approving this description, raster mode and requested source dimensions and authorizing one generation. The single generation completed and decoded successfully. Actual output is an opaque 1254×1254 RGB PNG, below the requested 2048×2048; it has not been resized. Ronald then accepted this exact candidate (“I think its fine”), after disclosure of the rougher texture and resolution. This approves the source artwork, not a processed derivative or runtime implementation. Local provenance and the candidate are under `.lore/local/experiments/002-shadow-paper/components/`.

The earlier primitive pilot is not the visual target. The stage candidate establishes the intended material and palette, not a requirement to bake its perspective, grid or lighting into this source.

## Floor production description

- **Role and consumer:** An opaque paper ground texture for Borrowed Turns' Godot 2D stage. A later, separately authorized projective shader or mesh will map it into the theatre floor. Logical tile coordinates, drawn grid lines and tactical overlays remain separate.
- **View and framing:** Orthographic top-down, square, edge-to-edge material field. No perspective, horizon, surrounding stage, visible outer paper border or transparent padding. No seamless-tiling requirement; this is one continuous floor source, not a tile kit.
- **Material and palette:** Tactile cut-paper surface matching the approved stage floor: predominantly muted deep plum, with restrained amber and rust variation and fine fibrous grain. Broad, low-contrast variation should leave room for figures, grid lines and telegraphs; avoid bright focal patches or dense distracting marks.
- **Lighting:** Even, diffuse material presentation. No baked spotlight, directional illumination, cast shadows or glossy highlights. Retain paper texture, not the reference's scene lighting.
- **Exclusions:** No grid, tile seams, masonry, cracks outlining cells, borders, foliage, figures, puppets, lantern, artifact, footprints, telegraphs, text, controls or effects. This artwork establishes no gameplay, lighting or lantern mechanics.

## Proposed delivery and route

**Raster-only PNG**, requested source **2048 × 2048 pixels, 1:1**, fully opaque. SVG is not recommended for this tactile bitmap texture. The square is an authoring canvas, not a decision about board dimensions or camera.

Use the built-in `experimental_image_generate` tool once, after approval, with both authorized references:

- `.lore/work/design/borrowed-turns-art/lantern-hero-in-the-shadow-forest.webp`
- `.lore/local/experiments/002-shadow-paper/look-frame/stage-candidate.png`

The original supplies paper construction and palette; the liked stage candidate is the immediate floor-material reference. Neither authorizes copying unwanted grid, perspective or scene content.

Proposed candidate path: `.lore/local/experiments/002-shadow-paper/components/floor-candidate.png`. Preserve the actual original output and record its actual format and dimensions; a request for 2048 pixels is not a guarantee the tool will deliver that size. Do not silently resize a different result.

Projected display sizes, board footprint, runtime texture dimensions and file-size budget are **unknown**. They are not invented source-art requirements; resolve them for separately authorized derivative/integration work. No transparency or background removal is needed for this floor.

## Review boundary

After authorized creation, verify decode, dimensions, color mode and provenance; visually inspect the actual saved candidate against both references. Present the exact candidate for Ronald's artwork approval, noting any delivery mismatch. Source approval does not approve derivatives, runtime readability, camera mapping or integration. Backdrop, foreground and cast creation remain outside this first component's scope.

## Runtime grid intent, after source approval

Ronald wants grid dimensions to be a runtime decision rather than baked into the artwork, and would like individual squares to read as different pieces of paper. The original continuous-material description does not by itself deliver that appearance. The runtime treatment is being discussed separately; no new cell artwork, processing or integration has occurred. Slight downscaling may soften the rough grain, but its actual projected appearance remains untested.

## Source promotion

At Ronald's request to move the accepted artwork into a committable asset location, the unchanged original was copied to `games/borrowed-turns/assets/stage/floor-paper.png`. Both source and destination match SHA-256 `86f09de16558b344cbf451378a74e56b0e52a8a763fcdfd2b14c31ba39df329c`; the durable copy decoded and was visually reopened. Approved source artwork is distinct from regenerable game/test evidence. Local generation provenance remains optional. No runtime wiring, resizing or other derivative has occurred.

## Backdrop component: proposed production brief

### Scope and approval state

Ronald selected **Finish stage artwork first**, defining backdrop and foreground components before changing the game view. He subsequently explicitly selected **Generate the backdrop**, approving the description, raster mode and requested dimensions below and authorizing one generation. That single generation completed: the candidate decoded as an opaque 1672×941 RGB PNG, matching the requested canvas. Ronald approved the exact image (“we can keep it”) after disclosure of the heavier arch, lower-corner foliage and warm gradient. It was copied unchanged to `games/borrowed-turns/assets/stage/backdrop-paper.png`, byte/hash-verified and reopened. SHA-256: `5a98667d52c44da7633b4442e733d15fa0f563872d24807fe3dc4875ee0b7ad9`. No foreground creation, image processing or runtime integration is included.

### Visual description and layer ownership

Create the **warm parchment puppet screen plus its rear architectural arch**, preserving the liked stage study's composition, tactile paper construction and plum/amber/rust palette. The screen is the quiet performance surface; the arch supplies enough rear structure for it to belong to the theatre rather than read as a bare texture.

- **Screen:** Broad, uninterrupted amber-parchment field, gently varied with paper grain. Keep its central performance area free of motifs, strong bright patches, hard lighting gradients and distracting cracks. It must support dark, elaborate action-puppets added separately at runtime.
- **Rear structure:** Restrained layered deep-plum paper arch around the upper screen and its sides, following the study's existing arch shape and proportions. Paper-layer relief is appropriate; do not add ordinary figure shadows or a new scene-lighting scheme.
- **Shared layout:** Request the study's full 1672 × 941 canvas. Keep the arch/screen registration fixed to that composition, not a tighter crop. The screen's main visible performance area occupies the upper central stage. Continue the parchment behind the future floor through the lower canvas, with no painted floor, horizon line or hard lower border. The projected floor can overlap this continuation near the study's existing wall/floor junction, approximately 58% down the canvas, without exposing a gap.
- **Future foreground ownership:** The outer forest wings, leafy overhead canopy, banners, foreground curls and front edge belong to a later foreground component, not this backdrop. Do not duplicate them here. The rear arch and front foliage will overlap in the approved composition; this is a layer separation, not a redesign.
- **Exclusions:** No floor, grid, fixed cell count, standees, puppets, action marks, lantern, artifact, text, controls or visible transparency checkerboard. Do not infer camera controls, physical lighting rules or lantern mechanics.

### Delivery and creation route

Proposed **raster-only PNG, 1672 × 941 pixels**, approximately **16:9**, fully opaque and edge-to-edge. The dimensions match the approved stage study for composition registration, not a runtime resolution requirement. SVG is not the recommended medium for this tactile paper artwork. Projected display sizes, runtime texture dimensions and file-size budget remain **unknown**.

After approval, use **one built-in `experimental_image_generate` call** with the liked stage study as the primary composition reference and the original supplied image as the material/style reference:

- `.lore/local/experiments/002-shadow-paper/look-frame/stage-candidate.png`
- `.lore/work/design/borrowed-turns-art/lantern-hero-in-the-shadow-forest.webp`

Proposed candidate path: `.lore/local/experiments/002-shadow-paper/components/backdrop-candidate.png`. Preserve the actual original output, record its actual dimensions and disclose any mismatch; do not automatically crop, resize or promote it.

This backdrop needs no transparency or color removal. The later foreground will require its own approved description and transparency route; a uniform removable background does not itself authorize removal, and a pictured checkerboard is not alpha.

### Review boundary

Inspect the actual saved image for material consistency, uninterrupted puppet space, reference alignment and absence of duplicated foreground or floor. Present that exact version for Ronald's artwork approval. Approval of this description or source does not approve the foreground, derivatives, runtime mapping, puppet readability or integration.

## Foreground component: proposed production brief

### Scope and approval state

Foreground: **one approved frame source**. Ronald explicitly selected **Generate, then review**, approving its description, raster mode, requested canvas and one generation. The single generation completed at 1672×941. Despite the request for removable green, it delivered an RGBA PNG with real transparency. Alpha and light/dark edge inspection passed for human review. Ronald then approved the exact foreground (“looks great”) after viewing it over the approved backdrop, without a floor. No removal was necessary or performed. The unchanged source was copied to `games/borrowed-turns/assets/stage/foreground-paper.png`, byte/hash-verified and reopened; SHA-256 `e4c459a0f23318ae418d04632d01588ae908d8da7b3f9ca6c90368bc07d7685d`. No asset splitting or game-view changes are included.

### Visual description and registration

Create the liked stage study's **outer forest wings, leafy canopy, hanging banners and front paper curls** as one registered foreground frame. Match its rich, layered cut-paper construction: deep plum trunks and branches, amber and rust-red leaves, warm cut edges and visible paper grain. Preserve the study's asymmetry, including banners on the left and the larger curled paper flourish at lower right. This is not a new stage design.

- **Shared canvas:** Requested 1672 × 941, approximately 16:9, matching the approved backdrop. Do not crop the frame to its visible artwork or change its registration.
- **Open play and performance space:** Confine trunks mainly to the outer 15% on either side and canopy mainly to the upper 15%. Banners may hang lower within the left wing. Keep the central area, approximately 22–78% across and 15–87% down, empty. Keep front curls shallow through the lower middle, with taller flourishes restricted to the outer corners. These are frame guides, not fixed board dimensions; no tile count is implied.
- **Layer ownership:** No rear architectural arch, parchment screen, floor or grid. The approved backdrop already contains lower-corner foliage: do not generate another bank of bushes there. Front-edge curls and perimeter leaves may overlap that existing scenery without repeating it. No standees, puppets, lantern, artifact, telegraphs, text or controls.
- **Paper depth:** Internal overlaps may have restrained paper-layer shading. Do not paint shadows or reflected color onto the removable background. No fog, glow, translucent wisps or blurred peripheral edges.

### Raster original and proposed transparency route

Recommend **raster-only PNG, requested 1672 × 941**, generated once with the built-in `experimental_image_generate` tool. SVG would not preserve the intended tactile raster material.

Generate foreground artwork against a **flat, uniform vivid green background, #00FF00**, absent from the plum/amber/rust artwork. Use that same color in every empty gap, including gaps between leaves. No green paint spill, gradient, background texture, scenic fill or pictured checkerboard. Paper silhouettes should have crisp edges suitable for later removal; do not promise that generated pixels will satisfy these constraints before inspection.

Authorized reference inputs for the proposed call:

- `.lore/local/experiments/002-shadow-paper/look-frame/stage-candidate.png`: foreground composition and silhouette.
- `games/borrowed-turns/assets/stage/backdrop-paper.png`: actual approved registration, palette and rear-layer ownership.
- `.lore/work/design/borrowed-turns-art/lantern-hero-in-the-shadow-forest.webp`: original construction/style anchor.

Proposed original path: `.lore/local/experiments/002-shadow-paper/components/foreground-keyed-candidate.png`. Preserve the generated original unchanged, record actual dimensions and disclose any mismatch. Runtime display size and file-size budget remain unknown.

### Approval and removal boundary

First inspect and present the actual generated original for exact-version artwork approval. Request separate permission now, effective only after that approval, to remove the green from a **separate RGBA candidate**, without resizing, redrawing or changing registration. Proposed path: `.lore/local/experiments/002-shadow-paper/components/foreground-alpha-candidate.png`. This permission would cover only background removal and local inspection composites, not other derivatives or integration.

Use only available tools; do not assume a particular removal tool is installed or install dependencies. If green is uneven, contaminates paper edges, or cannot be removed cleanly without altering artwork, report the blocker rather than silently repainting or regenerating.

Verify decoded transparent and opaque pixels, inspect fine gaps and edge halos over both light and dark backgrounds, and inspect a local registration composite against the approved backdrop. Record the method, settings, tool/version and source/output hashes. A green original or pictured checkerboard is not a transparent asset. Present the resulting exact alpha candidate for separate derivative approval; do not promote or integrate it automatically.

## Stage integration outline and test contract

### Authorization and bounded result

Ronald explicitly selected **Integrate the stage**: build and test the layered stage/runtime grid with the existing encounter, then pause for his visual review. All three unchanged originals under `games/borrowed-turns/assets/stage/` are protected. This outline first supplied tests, followed by separate neutral setup, independent behavioral RED and production implementation. The implemented candidate has now passed independent execution and technical review, including the STAGE-C01 view-return correction; runtime visual acceptance remains pending.

Add an explicit optional **`stage`** presentation alongside `plain` and `paper`; retain `paper` as the current default. Preserve an in-game route between the views and add `--presentation=stage`. Plain/paper keep their existing layout and behavior. Presentation changes must not change model rules, content, command legality, predictions, history, budgets or encounter progress. No Invert, new mechanics, new artwork, art cleanup, resized source assets or dependencies.

The first integrated stage uses the existing limited figures and shove feedback. It does not fulfill or validate the eventual elaborate backdrop-puppet treatment, lantern handoff or finished character direction. Do not replace that missing art with another speculative primitive-polish project.

### Stage-specific layout

The stage must not be squeezed into the legacy board column. **Existing encounter means unchanged gameplay, not unchanged panel organization.**

- Give the theatre the full-width main region, with backdrop and foreground uniformly aspect-fitted and registered together. Do not stretch them independently.
- At the supported minimum 1024 × 720, use a compact two-line status header, the largest fitted stage that remains, and a compact bottom action/consequence strip. Rough allocation: about 56 px header, 84–88 px footer, restrained margins/gaps, leaving roughly 540 px stage height. These are starting composition guides, not fixed correctness constants.
- Keep health/exit objective, turn/phase, AP/MP, held action and its deadline outside scrolling details. Keep inspection/instruction, consequence summary, operation buttons and confirmation/cancellation visible and keyboard accessible.
- Reorganize the existing intentions, detailed ordered preview and event history into an explicit details sheet over the **upper backdrop area**, not a permanent right rail. Open the ordered preview when a command is selected and assessed; retain scrolling for its complete ordered effects. Confirm/Cancel remain visible in the action strip. Inspection details, enemy plans and recent events remain accessible through a labeled control, not removed.
- The details sheet must not cover the playable floor or steal board input when closed. Its deliberate tradeoff is covering part of the performance screen while reading exact outcomes. That is preferable to permanently shrinking the theatre or hiding tactical facts.
- The floor may begin moderately higher than the concept study, toward about 50% rather than 58% of stage height, to give rows usable targeting depth. This is an explicit composition adjustment: less puppet-screen area in exchange for a more usable board, without editing artwork. Keep the playable quadrilateral within the foreground's clear opening, including its corner curls. Final placement requires actual render inspection.

Runtime row/column counts and visual seed are independent of the artwork. They do not guarantee that arbitrarily large boards will be comfortably playable in a fixed viewport. Review the current encounter at minimum and larger sizes; report any consequential remaining layout limitation rather than obscuring information or claiming tests establish readability.

### Shared drawing and input path

Use one projective map between continuous logical board coordinates and a convex screen quadrilateral. Map cell polygons, cell centers/actor feet, grid/seams, walls, exit, intentions, candidates, selection/focus, previews, confirmed effects and mouse targeting through it. Outside the quadrilateral is not a cell. Logical ownership is half-open: left/top included; right/bottom excluded; exact internal seams belong to the next column/row.

Create a pure `ui/stage_projection.gd` (`RefCounted`) with:

| Method | Contract |
| --- | --- |
| `configure(columns: int, rows: int, quad: PackedVector2Array) -> bool` | Quad corners TL, TR, BR, BL; reject nonpositive dimensions and degenerate/nonconvex geometry; failure clears any previously valid mapping. |
| `project(grid: Vector2) -> Vector2` | Project continuous logical coordinates, including board-edge corners. True projective mapping, not bilinear interpolation. |
| `unproject(pixel: Vector2) -> Vector2` | Inverse logical coordinates; outside points may remain outside. |
| `cell_at(pixel: Vector2) -> Array` | Valid `[column, row]`, or `[]` outside/unconfigured. |
| `cell_polygon(cell: Array) -> PackedVector2Array` | Detached TL/TR/BR/BL corners; empty for invalid/unconfigured cells. |

For paper cells, use a separate pure `ui/paper_cells.gd` (`RefCounted`):

`sample(cell: Array, visual_seed: int) -> Dictionary`

Return detached `{uv_rect: Rect2, quarter_turn: int, tint: Color}`. UV crop stays inside the source; rotation is 0–3 quarter turns; tint is finite and opaque. Cell coordinates and saved visual seed alone determine appearance: no global RNG, frame time, command outcomes, traversal order or gameplay state. Keep palette variation subtle and nonsemantic. Shared source texture, stable per-cell crops/rotation/tint, narrow seams and restrained irregular paper edges provide separate-piece character without another asset batch.

The floor material must use the same logical map as the geometry, for example via inverse-projective shader coordinates. A two-triangle quad with plain affine UV interpolation is not a claim of correct perspective mapping. Do not bake a grid or lighting into source art.

Extend/extract these actual `board.gd` drawing seams:

- `set_stage_mode(enabled: bool) -> void`, separate from the existing paper-feedback flag.
- `cell_polygon(cell: Array) -> PackedVector2Array`, consumed by the real tile/telegraph/selection drawing paths; the baseline polygon is the existing `_cell_rect` corners.
- `piece_appearance(cell: Array) -> Dictionary`, consumed by the stage floor material using the stable visual seed.
- `figure_layout(cell: Array) -> Dictionary`: `{origin: Vector2, foot: Vector2, size: float}`, consumed by actual figure drawing. Initially extract the existing origin and size unchanged; its existing drawn foot is `origin + Vector2(0, 0.40 * size)`. Stage figures stay upright, with that foot anchored to the projected tile center, scale following depth, and drawing order following feet. Preserve readable labels and input footprints.

Keep `cell_center`, `_from_pixel` and the existing model-authored `effect_footprints` as shared consumers, not duplicate simulations. Preserve ordered C01–C03 cue behavior. Decor layers ignore mouse input. Draw backdrop, floor/cells, tactical marks and existing figures/feedback, then foreground; floor placement and playable-cell placement are distinct so framing cannot silently conceal actionable cells.

### Loadable setup before behavioral RED

The independent tester must not count absent scripts or methods as RED. A separately authorized setup may create the two loadable helper interfaces with safe neutral results (`configure` false, vectors zero, cell arrays/polygons empty, material dictionary neutral), add an inert stage flag, and extract the board's existing rectangular polygons and figure placement without changing behavior. Empty/unconfigured calls must not error. New rendering paths must later consume those seams, not leave test-only alternatives beside old draw loops.

No projective math, stage rendering or UI reorganization belongs in that neutral setup. The new runner reports exit 2 for missing interfaces; assertion failure after clean setup is exit 1. Syntax checks do not establish behavioral RED.

### Focused verification and ownership

`tests/stage_projection_run.gd` owns controlled rectangle/trapezoid inputs and independent analytic coordinates, including a midpoint that distinguishes homography from bilinear mapping. It covers half-open boundaries, sloped-edge outside rejection, shared cell corners, nonsquare runtime dimensions, viewport aspects, invalid/replaced configuration, stable detached paper descriptors and global-RNG isolation. Controlled model fixtures exercise real board mapping, upright foot/scale placement, resize and view-return behavior without importing production art or encounter tuning.

Extend the existing `ui/smoke.gd`, not a duplicate UI harness. Its existing lifecycle comparison now includes `stage` and preview footprint rows. Focused stage checks exercise actual viewport GUI targeting, runtime board dimensions, full-width layout and visible tactical controls at 1024 × 720 and 1600 × 900, ordered-preview visibility, resize preservation, feedback cancellation on view change and restart isolation. The full run retains the existing replacement/deadline/mixed-feedback/model coverage; do not clone that matrix into stage tests.

Author validation is **syntax only**. After the neutral setup, the independent tester owns behavioral RED and later GREEN:

Both authored files passed `godot --headless --path games/borrowed-turns --check-only --script <script>` with exit 0 using Godot `4.7.2.stable.arch_linux.ed1daf0bf`. Behavioral execution was deliberately not run by the author. No production helper or board/UI behavior has been implemented in this step.

```sh
godot --headless --path games/borrowed-turns --script res://tests/stage_projection_run.gd
godot --headless --path games/borrowed-turns --script res://ui/smoke.gd -- --focus=stage
```

After implementation, the same tester runs the unchanged model/controller/rendering suites and full UI smoke, then the existing completion gate:

```sh
godot --headless --path games/borrowed-turns --script res://tests/run.gd
godot --headless --path games/borrowed-turns --script res://tests/shadow_presentation_run.gd
godot --headless --path games/borrowed-turns --script res://tests/shadow_rendering_run.gd
godot --headless --path games/borrowed-turns --script res://ui/smoke.gd
python3 games/borrowed-turns/tools/rendered_smoke_gate.py \
  --capture-dir /tmp/opencode/borrowed-turns-stage-fresh-smoke --timeout 120
```

Use a fresh nonexistent capture directory. The full capture includes `stage-1024-encounter.png` and `stage-1600-encounter.png` from actual production content without tuning assertions; separately named `stage-*-shove-preview.png` and `stage-*-shove-held.png` use controlled fixtures. Verify optional stage/plain/paper startup and continued rejection of Invert independently. Fresh correctness review must inspect actual draw-path use of the shared map, source-art protection and state/effect parity; math tests alone cannot prove a renderer uses the map.

Finally inspect the actual in-game stage, not an offline art composite: registration, far-row targeting, individual paper pieces, texture filtering, labels/standee footprints, foreground occlusion, threat/preview contrast, minimum-size controls and finite motion. Screenshots plus a short interaction recording support that review, not acceptance of physical mouse/HiDPI behavior or the unbuilt puppet layer. Present the existing encounter and material caveats to Ronald and pause for explicit visual/runtime acceptance. Logs, captures and recordings stay local; the parent owns Beads and experiment-result updates.

### Current acceptance boundary

The implemented optional stage retains the paper default and plain/paper views. Independent projection/model/controller/rendering suites passed; after STAGE-C01, focused UI passed 304/0, full headless UI 599/0 and gated rendered UI 640/0. Correctness, refactoring assessment and separate engineering-quality review accepted the bounded implementation. No source PNG was changed.

The actual-stage visual critique found the integrated scene suitable for Ronald's review, while disclosing weak contrast for dark provisional gestures, some held-graphic/actor-label crowding and subtle separate-paper-piece character at minimum size. No new artwork or broad polish cycle is authorized by those observations. Actual runtime visual acceptance, eventual elaborate puppets and finished standees remain separate.

Ronald subsequently tried checkpoint `dcbd13e` and accepted the stage and floor: **“The floor, and stage are perfect.”** Preserve their current composition/material treatment unless he asks to change them. This does not approve provisional figures, remaining feedback, finished standees or elaborate puppets, and does not authorize further production or integration.
