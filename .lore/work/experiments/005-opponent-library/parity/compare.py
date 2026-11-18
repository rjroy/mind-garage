#!/usr/bin/env python3
"""Disposable fingerprint + first-difference comparator for projected replays."""
from __future__ import annotations

import argparse
from collections import Counter, defaultdict
import hashlib
import json
from pathlib import Path
import sys


def digest(value: object) -> str:
    payload = json.dumps(value, sort_keys=True, separators=(",", ":")).encode()
    return hashlib.sha256(payload).hexdigest()


def summary(document: dict) -> dict:
    by_fixture = defaultdict(list)
    by_episode = defaultdict(list)
    for row in document["rows"]:
        fixture = row.get("fixture", row["episode"].split("/")[0])
        by_fixture[fixture].append(row)
        by_episode[row["episode"]].append(row)
    result = {}
    for fixture, rows in sorted(by_fixture.items()):
        events = [
            event
            for row in rows
            if row.get("committed")
            for event in row["state"]["events"]
        ]
        episodes = {
            name: episode_rows
            for name, episode_rows in by_episode.items()
            if episode_rows[0]["fixture"] == fixture
        }
        result[fixture] = {
            "sha256": digest(rows),
            "episodes": len(episodes),
            "rows": len(rows),
            "committed": sum(row.get("committed", False) for row in rows),
            "rejected": sum(row.get("committed") is False for row in rows),
            "event_counts": dict(sorted(Counter(e["type"] for e in events).items())),
            "captures": sorted({(e["source"], e["kind"]) for e in events if e["type"] == "capture"}),
            "shine_counts": dict(sorted(Counter(e["kind"] for e in events if e["type"] == "shine").items())),
            "episodes_detail": {
                name: {
                    "sha256": digest(episode_rows),
                    "actions": len(episode_rows) - 1,
                    "status_before_reset": episode_rows[-2]["state"]["status"],
                    "player_hp_before_reset": episode_rows[-2]["state"]["player"]["hp"],
                }
                for name, episode_rows in episodes.items()
            },
        }
    return {"sha256": digest(document), "fixtures": result}


def differences(left: object, right: object, path: str = "$"):
    if type(left) is not type(right):
        yield f"{path}: type {type(left).__name__} != {type(right).__name__}"
    elif isinstance(left, dict):
        for key in sorted(left.keys() | right.keys()):
            if key not in left or key not in right:
                yield f"{path}.{key}: missing on {'baseline' if key not in left else 'candidate'}"
            else:
                yield from differences(left[key], right[key], f"{path}.{key}")
    elif isinstance(left, list):
        if len(left) != len(right):
            yield f"{path}: length {len(left)} != {len(right)}"
        for index, (a, b) in enumerate(zip(left, right)):
            yield from differences(a, b, f"{path}[{index}]")
    elif left != right:
        yield f"{path}: {left!r} != {right!r}"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("baseline", type=Path)
    parser.add_argument("candidate", type=Path, nargs="?")
    parser.add_argument("--summary", type=Path)
    args = parser.parse_args()
    baseline = json.loads(args.baseline.read_text())
    report = summary(baseline)
    if args.summary:
        args.summary.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n")
    print("Baseline SHA256:", report["sha256"])
    for fixture, values in report["fixtures"].items():
        print(
            fixture, values["sha256"], f"{values['episodes']} episodes",
            f"{values['rows']} rows", f"Shine={values['shine_counts']}",
        )
    if args.candidate is None:
        return 0
    candidate = json.loads(args.candidate.read_text())
    if baseline == candidate:
        print("MATCH: all projected rows, legality, events and intentions")
        return 0
    print("MISMATCH: candidate SHA256:", digest(candidate))
    for index, value in enumerate(differences(baseline, candidate)):
        print(value)
        if index == 19:
            print("Stopping after first 20 differences.")
            break
    return 1


if __name__ == "__main__":
    sys.exit(main())
