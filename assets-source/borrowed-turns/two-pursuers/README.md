# Two-pursuer puppet source

The five shipped textures in `games/borrowed-turns/assets/puppets/two-pursuers/` are unchanged extracts from `storyboard-candidate.png` (1024 × 1536 RGB). Ronald authorized promotion of these exact derivatives and their necessary source and recipes. They remain the provisional low-resolution concept cutouts, not newly approved finished artwork. The game reads only the shipped textures, not this source package.

Source SHA-256: `6d18ad9385747855507ad32234f14928ac113b4196260153e8bac80b3df7737c`.

The two scripts are portable adaptations of the original extraction recipes. The original `prepare-cutouts.sh` SHA-256 was `62c3b32a2b2198de2bfad408d961f32d12acde813a53270c97f1cb832d216a70`; the original `prepare-pack.sh` SHA-256 was `ffebf1cbe5c333cac9b25057a8d355eb157fe50a3dc351d7897d7bfce035b5cf`. Paths now resolve from the source package and a caller-provided output directory, intermediate files are temporary, and unused inspection/whole-image outputs are omitted. The extraction, masks, compositing and PNG timestamp exclusions for the five results are unchanged.

Reproduce with ImageMagick 7.1.2-34 Q16-HDRI, build `c5d4ca8a0:20261014`, and `sha256sum`:

```bash
bash assets-source/borrowed-turns/two-pursuers/prepare-pack.sh /path/to/empty/output
```

Compare the output hashes to:

```text
183a86540b7611c47b8a8de3ba6da791e3c78e6025a9b38109c474defa1c0e3e  a-body.png
3396932a1a8ae490b217100c79ce55a1490bde376c7896a62b6450f9f85b564f  a-hands.png
c9644ebc272d865f11c0ff2d9d7533e537766a9c2f0a3c188034a34779020c36  b-body.png
0559331e196e085b5bdc6f24d4a00629e5c47d589b4218c735ac347cc97aeca7  b-hands.png
0675257136cff1f7375b8b621dffb64f4296940e29fe3b9ddf9c4e6a4cf0f588  p-lantern.png
```

Rebuilding is not required to play. Source PNG import settings disable alpha-border RGB changes and use lossless texture compression.
