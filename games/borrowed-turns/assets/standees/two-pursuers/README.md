# Two-pursuer candidate standees

Ronald explicitly selected **Use this set** after viewing the combined player/A/B gallery. These exact originals are approved candidate artwork for the proposed playable experiment, not a final production cast. They are source artwork and belong in source control.

| Source | Role | SHA-256 |
| --- | --- | --- |
| `player.png` | Plain-coated lantern carrier | `6e0d1e7b1133b9a8b61278a6f3970c2dc3170265c177b888e3467901f6a49908` |
| `enemy-a.png` | Broad-shouldered, angular ochre collar | `b6cf578a491e9f47dbf569b1b06509f8fa652ebac6c8c4301fb38fa1f4dc2aff` |
| `enemy-b.png` | Narrower pursuer with rounded hood | `e8666070f3099bb5cfc59e386f19fdd9244776e5e3b20f81a7777d1880935f14` |

All are **1024×1536, 8-bit RGBA PNG**, matching the requested canvas. Actual alpha peaks at 254/255, with body samples at 253/255. No alpha normalization, resizing, crop or background removal was applied. Apparent broad halos in the raw viewer disappear under correct alpha compositing; inspection did not warrant cleanup.

Creation used one `experimental_image_generate` call per figure, reported model `openai/gpt-image-2`. Jobs: player `image_1e2b52d66001vbC3vyVPAGmAlv`; A `image_1e2b56d9e001HsVTlcu7QkxRda`; B `image_1e2b5ac3d001tCXb8ih6yhDzgY`. References were the original supplied forest/lantern image for paper construction and accepted stage backdrop/floor for palette and contrast.

Original local candidates remain preserved. These copies match their source bytes and hashes and decode correctly. Inspection galleries and other generated evidence stay under gitignored `.lore/local/`, not alongside these source assets.

The [draft slice brief](../../../../../.lore/work/design/borrowed-turns-art/dual-layer-playable-slice-brief.md) defines the intended use. B is more side-facing; A is more flamboyant than utilitarian. Actual projected size, overlap, selection, filtering and runtime readability have not been tested. Color-profile/runtime sRGB import handling remains unverified. No game integration or final character approval is implied by source-art acceptance.
