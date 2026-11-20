#!/bin/sh
set -eu

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
ROOT=$(git -C "$HERE" rev-parse --show-toplevel)
BASE=6def00f9027cfc481ac2840abc376fbb07dea146
EXPECTED_CORPUS=e21d75082e6cd32af80cb53d8826d6ea0c20f3a4b7a10422a408eb6b2998bd29
EXPECTED_REPLAY=dd10dea5283007a0589d8b4c9f4cc773d74a4bef33e7e232c70f83a3fa89b21e
WORK=$(mktemp -d "${TMPDIR:-/tmp}/borrowed-turns-parity.XXXXXXXX")
printf 'Evidence directory: %s\n' "$WORK"

mkdir -p "$WORK/baseline" "$WORK/candidate/games/borrowed-turns"
git -C "$ROOT" archive "$BASE" games/borrowed-turns | tar -xf - -C "$WORK/baseline"
# Snapshot working tree content, including untracked candidate source, without
# allowing Godot to create an import cache in the checkout.
tar --exclude='./.godot' -cf - -C "$ROOT/games/borrowed-turns" . |
	tar -xf - -C "$WORK/candidate/games/borrowed-turns"
B="$WORK/baseline/games/borrowed-turns"
C="$WORK/candidate/games/borrowed-turns"
find "$C" -type f -exec sha256sum {} + | sort > "$WORK/candidate-manifest.sha256"

run_godot() {
	name=$1
	shift
	if godot --headless "$@" > "$WORK/$name.log" 2>&1; then
		cat "$WORK/$name.log"
	else
		status=$?
		cat "$WORK/$name.log" >&2
		return "$status"
	fi
	# Godot can report a script error while still exiting successfully.
	if grep -Eq 'SCRIPT ERROR|^ERROR:' "$WORK/$name.log"; then
		echo "Godot reported an error in $name" >&2
		return 1
	fi
}

run_godot generate --path "$B" --script "$HERE/generate.gd" -- --out="$WORK/corpus.json"
python3 - "$WORK/corpus.json" "$EXPECTED_CORPUS" <<'PY'
import hashlib
import json
import sys

with open(sys.argv[1], encoding="utf-8") as f:
    corpus = json.load(f)
actual = hashlib.sha256(json.dumps(corpus, sort_keys=True, separators=(",", ":")).encode()).hexdigest()
if actual != sys.argv[2]:
    raise SystemExit(f"Shared historical corpus fingerprint changed: {actual}")
print("Verified shared historical corpus fingerprint:", actual)
PY
run_godot frozen --path "$B" --script "$HERE/replay.gd" -- \
	--corpus="$WORK/corpus.json" --out="$WORK/frozen.json"
run_godot candidate --path "$C" --script "$HERE/replay.gd" -- \
	--corpus="$WORK/corpus.json" --out="$WORK/candidate.json" --adapter="$HERE/registry_adapter.gd"
python3 "$HERE/compare.py" "$WORK/frozen.json" "$WORK/candidate.json" --summary="$WORK/summary.json"
python3 - "$WORK/summary.json" "$EXPECTED_REPLAY" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as f:
    actual = json.load(f)["sha256"]
if actual != sys.argv[2]:
    raise SystemExit(f"Shared historical replay fingerprint changed: {actual}")
print("Verified exact shared historical replay fingerprint:", actual)
PY
sha256sum -c "$WORK/candidate-manifest.sha256" > "$WORK/manifest-check.log"
