#!/usr/bin/env python3
"""Controlled subprocess for the rendered-smoke acceptance gate tests."""

import base64
import os
from pathlib import Path
import signal
import sys
import time


PNG = base64.b64decode(
    "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+X2ioAAAAASUVORK5CYII="
)
SUMMARY = "R2 UI smoke: 179 checks, 0 failures. Injected GUI events, not physical OS input."


def main() -> None:
    Path(os.environ["FAKE_SMOKE_STARTED"]).write_text("started\n", encoding="utf-8")
    args = sys.argv[1:]
    captures = [arg.removeprefix("--capture-dir=") for arg in args if arg.startswith("--capture-dir=")]
    try:
        valid_runner = (
            args[args.index("--path") + 1] == os.environ["FAKE_PROJECT_ROOT"]
            and args[args.index("--script") + 1] == "res://ui/smoke.gd"
            and "--" in args
        )
    except (ValueError, IndexError):
        valid_runner = False
    if len(captures) != 1 or not valid_runner:
        print("fake child received incorrect runner arguments", file=sys.stderr)
        sys.exit(65)
    out = Path(captures[0])
    scenario = os.environ["FAKE_SMOKE_SCENARIO"]
    if scenario == "timeout":
        time.sleep(5)
        return
    if scenario == "signal":
        os.kill(os.getpid(), signal.SIGTERM)
        return
    if scenario == "early":
        print("Borrowed Turns UI: start baseline=R2", flush=True)
        return
    if scenario != "missing_image":
        (out / "r2-escaped.png").write_bytes(b"not a png" if scenario == "bad_image" else PNG)
    if scenario == "bad_summary":
        print("R2 UI smoke: 179 checks, 1 failures. Injected GUI events, not physical OS input.")
    elif scenario == "zero_checks":
        print("R2 UI smoke: 0 checks, 0 failures. Injected GUI events, not physical OS input.")
    elif scenario == "embedded_summary":
        print("not a completion line: " + SUMMARY)
    else:
        print(SUMMARY)
    if scenario == "script_error":
        print("SCRIPT ERROR: controlled runtime failure", file=sys.stderr)
    if scenario == "error":
        print("ERROR: controlled engine failure", file=sys.stderr)
    if scenario == "failed":
        print("ERROR: R2 UI smoke: controlled failed assertion", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
