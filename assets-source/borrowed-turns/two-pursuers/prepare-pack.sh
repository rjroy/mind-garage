#!/usr/bin/env bash
# Rebuild the five puppet textures in a caller-provided output directory.
set -euo pipefail
if [[ $# -ne 1 ]]; then echo "Usage: $0 <output-directory>" >&2; exit 2; fi
root="$1"
script_dir="$(cd -- "$(dirname -- "$0")" && pwd)"
source="$script_dir/storyboard-candidate.png"
mkdir -p "$root"
prior="$(mktemp -d "${TMPDIR:-/tmp}/puppet-cutouts.XXXXXXXX")"
trap 'rm -rf -- "$prior"' EXIT
bash "$script_dir/prepare-cutouts.sh" "$prior"
printf '%s\n' \
  "6d18ad9385747855507ad32234f14928ac113b4196260153e8bac80b3df7737c  $source" \
  "183a86540b7611c47b8a8de3ba6da791e3c78e6025a9b38109c474defa1c0e3e  $prior/a-body.png" \
  "3396932a1a8ae490b217100c79ce55a1490bde376c7896a62b6450f9f85b564f  $prior/a-hands.png" \
  "0675257136cff1f7375b8b621dffb64f4296940e29fe3b9ddf9c4e6a4cf0f588  $prior/p-lantern.png" | sha256sum -c -
mkdir -p "$prior/inspection"
for name in a-body a-hands p-lantern; do cp -f "$prior/$name.png" "$root/$name.png"; done
magick "$source" -crop 290x145+580+580 +repage "$prior/inspection/b-source-native.png"
# Remove caption, rear architecture and floor from the extraction region only.
# These masks change alpha, not source RGB; no anatomy or silhouette is drawn.
magick -size 290x145 xc:white -fill black \
  -draw 'rectangle 0,0 37,144 rectangle 0,0 112,44 rectangle 0,0 68,62 rectangle 175,0 289,48 rectangle 215,0 289,80 rectangle 240,0 289,110 rectangle 254,0 289,144 rectangle 0,143 289,144' \
  "$prior/inspection/b-region.png"
magick "$prior/inspection/b-source-native.png" -colorspace Gray -threshold 37% -negate \
  "$prior/inspection/b-region.png" -compose Multiply -composite \
  -morphology Close Diamond:1 \
  \( +clone -fill white -draw 'color 0,0 floodfill' -negate \) -compose Lighten -composite \
  -blur 0x0.35 -level 5%,95% "$prior/inspection/b-alpha.png"
# Forearm pair, including both elbow rings; the source points inward from right.
magick -size 290x145 xc:black +antialias -fill white \
  -draw 'polygon 35,42 94,42 98,67 128,65 132,83 128,113 35,113' \
  "$prior/inspection/b-hands-region.png"
magick "$prior/inspection/b-alpha.png" "$prior/inspection/b-hands-region.png" \
  -compose Multiply -composite "$prior/inspection/b-hands-alpha.png"
magick "$prior/inspection/b-alpha.png" \( "$prior/inspection/b-hands-region.png" -negate \) \
  -compose Multiply -composite "$prior/inspection/b-body-alpha.png"
for role in body hands; do
  magick "$prior/inspection/b-source-native.png" "$prior/inspection/b-$role-alpha.png" \
    -alpha off -compose CopyOpacity -composite \
    +set date:create +set date:modify +set date:timestamp -define png:exclude-chunk=date,time \
    -define png:color-type=6 "$root/b-$role.png"
done
sha256sum "$root/a-body.png" "$root/a-hands.png" "$root/b-body.png" "$root/b-hands.png" "$root/p-lantern.png"
