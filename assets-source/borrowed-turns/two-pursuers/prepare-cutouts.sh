#!/usr/bin/env bash
# Extract the A and player cutouts into the supplied work directory.
set -euo pipefail
if [[ $# -ne 1 ]]; then echo "Usage: $0 <work-directory>" >&2; exit 2; fi
root="$1"
source="$(cd -- "$(dirname -- "$0")" && pwd)/storyboard-candidate.png"
printf '%s\n' "6d18ad9385747855507ad32234f14928ac113b4196260153e8bac80b3df7737c  $source" | sha256sum -c -
mkdir -p "$root"
magick "$source" -crop 290x145+165+100 +repage "$root/a-crop.png"
magick "$source" -crop 145x145+445+100 +repage "$root/p-crop.png"
# Exclude labels and architecture. These polygons define mask regions, not new art.
magick -size 290x145 xc:white -fill black \
  -draw 'rectangle 0,0 13,144 rectangle 0,0 85,43 rectangle 0,0 43,79 rectangle 86,0 121,32 rectangle 183,0 289,33 rectangle 180,0 225,42 rectangle 0,143 289,144' \
  "$root/a-region.png"
magick -size 145x145 xc:white -fill black -draw 'rectangle 73,0 119,24 rectangle 0,143 144,144' "$root/p-region.png"
for name in a p; do
  magick "$root/$name-crop.png" -colorspace Gray -threshold 37% -negate \
    "$root/$name-region.png" -compose Multiply -composite \
    -morphology Close Diamond:1 \
    \( +clone -fill white -draw 'color 0,0 floodfill' -negate \) -compose Lighten -composite \
    -blur 0x0.35 -level 5%,95% "$root/$name-alpha.png"
done
# Both forearms/hands come from the same A pose; the rest stays a separate body.
# A binary ownership partition preserves the original assembly without double alpha.
magick -size 290x145 xc:black +antialias -fill white \
  -draw 'polygon 166,63 181,60 215,49 233,30 251,29 257,49 250,69 224,86 185,98 165,95' \
  -draw 'polygon 155,101 171,97 205,100 231,83 250,63 277,60 284,88 263,112 231,127 175,130 153,121' \
  -draw 'rectangle 180,87 289,144' \
  "$root/hands-region.png"
magick "$root/a-alpha.png" "$root/hands-region.png" -compose Multiply -composite "$root/hands-alpha.png"
magick "$root/a-alpha.png" \( "$root/hands-region.png" -negate \) -compose Multiply -composite "$root/body-alpha.png"
magick "$root/a-crop.png" "$root/body-alpha.png" -alpha off -compose CopyOpacity -composite \
  +set date:create +set date:modify +set date:timestamp -define png:exclude-chunk=date,time -define png:color-type=6 "$root/a-body.png"
magick "$root/a-crop.png" "$root/hands-alpha.png" -alpha off -compose CopyOpacity -composite \
  +set date:create +set date:modify +set date:timestamp -define png:exclude-chunk=date,time -define png:color-type=6 "$root/a-hands.png"
magick "$root/p-crop.png" "$root/p-alpha.png" -alpha off -compose CopyOpacity -composite \
  +set date:create +set date:modify +set date:timestamp -define png:exclude-chunk=date,time -define png:color-type=6 "$root/p-lantern.png"
sha256sum "$source" "$root/a-body.png" "$root/a-hands.png" "$root/p-lantern.png"
