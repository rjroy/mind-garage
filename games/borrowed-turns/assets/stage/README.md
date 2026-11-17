# Stage artwork

## Approved floor source

`floor-paper.png` is approved source artwork, not regenerable game/test output. It belongs in source control. Screenshots, recordings, logs and processing previews remain local.

- Role: top-down ungridded paper material for the proposed 2D projected stage.
- Format: 1254×1254, opaque 8-bit RGB PNG. Requested 2048×2048; the smaller actual delivery was disclosed before approval.
- Creation: one `experimental_image_generate` call, reported model `openai/gpt-image-2`; job `image_1e190794d001MK88mPs9rLZ14W`.
- References: the supplied lantern/shadow-forest image and Ronald's liked empty-stage study.
- Source approval: Ronald accepted this exact image after reviewing its rougher texture and actual dimensions.
- SHA-256: `86f09de16558b344cbf451378a74e56b0e52a8a763fcdfd2b14c31ba39df329c`.
- Promotion: copied unchanged from the local generated candidate, byte-compared, checksum-verified and reopened successfully.
- Brief: [stage component description](../../../../.lore/work/design/borrowed-turns-art/stage-components-brief.md).

The original has not been resized, keyed or converted. Optional stage view now consumes it through Godot's texture importer and a projective floor shader. Its in-game filtering, cell variation, targeting and visual acceptance remain subject to independent and human review.

Ronald wants runtime-selectable grid dimensions and cells that read as separate paper pieces. Stage view follows the model's dimensions and uses stable per-cell crops, rotation and subtle variation, rather than baking a fixed grid into this source. It adds no player-facing grid-size setting. The exact rendering is not yet accepted.

## Approved backdrop source

`backdrop-paper.png` is approved source artwork, not runtime/test output.

- Role: opaque parchment performance screen and plum rear arch; no floor or grid.
- Format: 1672×941, opaque 8-bit RGB PNG, matching the requested canvas.
- Creation: one `experimental_image_generate` call, reported model `openai/gpt-image-2`; job `image_1e1b0ecb3001n12kBvW8ptwUFF`.
- SHA-256: `5a98667d52c44da7633b4442e733d15fa0f563872d24807fe3dc4875ee0b7ad9`.
- Ronald approved this exact candidate (“we can keep it”) after disclosure of the heavier arch, lower-corner foliage and warm gradient.
- Promotion: copied unchanged from the local candidate, byte-compared, checksum-verified and reopened successfully.

No source processing has occurred. Stage view now composes this backdrop with the approved foreground and projected floor; the floor overlaps the lower background. In-game composition awaits human review. The elaborate puppet layer is not implemented.

## Approved foreground source

`foreground-paper.png` is the approved unchanged RGBA original.

- Role: forest wings, leaf canopy, left banners and front paper curls.
- Format: 1672×941, 8-bit RGBA PNG, matching the requested canvas.
- Creation: one `experimental_image_generate` call, reported model `openai/gpt-image-2`; job `image_1e1bb1eca001RNOL7tXFNRnnwQ`.
- SHA-256: `e4c459a0f23318ae418d04632d01588ae908d8da7b3f9ca6c90368bc07d7685d`.
- Although green backing was requested, the tool delivered real alpha. No green removal or other cleanup was performed.
- Alpha inspection: 1,105,156 transparent, 1,017 opaque and 467,179 partially transparent pixels; 426,437 of the partial pixels have ≥90% opacity.
- Light/dark and registered-backdrop inspection composites revealed no obvious green contamination or broad matte halo. Fine gaps remain open.
- Ronald approved this exact source (“looks great”) after viewing it over the approved backdrop, without a floor.
- Promotion: byte-compared, checksum-verified and reopened after copying unchanged from local staging.

All three source components are approved; their in-game composition is not. The foreground is highly translucent in some artwork pixels: preserve its original alpha unless a separately authorized derivative is needed. Local composites remain discussion evidence, not source assets.

## Runtime use

Commit the `.png.import` texture settings alongside these originals; the generated `.godot/imported/` cache is not source artwork. After a fresh checkout, run `godot --headless --editor --path games/borrowed-turns --import` from the repository root, or open the editor, before launching the game. Normal texture import does not overwrite the PNG originals. No custom background removal, source resizing or art cleanup is part of this integration. See the [game instructions](../../README.md#theatre-stage).
