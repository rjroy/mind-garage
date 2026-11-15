"""Run and verify the full rendered Borrowed Turns smoke harness."""

import argparse
import math
import os
from pathlib import Path
import re
import subprocess
import sys


PROJECT = Path(__file__).resolve().parents[1]
SUMMARY = re.compile(
    r"R2 UI smoke: [1-9][0-9]* checks, 0 failures\. "
    r"Injected GUI events, not physical OS input\."
)
PNG_SIGNATURE = b"\x89PNG\r\n\x1a\n"


def positive_timeout(value: str) -> float:
    try:
        seconds = float(value)
    except ValueError as exc:
        raise argparse.ArgumentTypeError("timeout must be a positive number") from exc
    if not math.isfinite(seconds) or seconds <= 0:
        raise argparse.ArgumentTypeError("timeout must be a positive finite number")
    return seconds


def reject(reason: str, code: int = 1) -> int:
    print(f"Rendered smoke: rejected: {reason}", file=sys.stderr, flush=True)
    return code


def forward_output(output: bytes | None) -> None:
    if output:
        sys.stdout.buffer.write(output)
        sys.stdout.buffer.flush()


def verify_output(output: bytes, capture_dir: Path) -> str:
    lines = output.decode("utf-8", errors="replace").splitlines()
    if any(line.lstrip().startswith(("ERROR:", "SCRIPT ERROR:")) for line in lines):
        return "child output contains an engine or script error"
    summaries = [line for line in lines if "R2 UI smoke:" in line]
    if len(summaries) != 1 or SUMMARY.fullmatch(summaries[0]) is None:
        return "missing, invalid, or duplicate full-run success summary"
    try:
        with (capture_dir / "r2-escaped.png").open("rb") as image:
            if image.read(len(PNG_SIGNATURE)) != PNG_SIGNATURE:
                return "terminal capture is not a PNG"
    except OSError as exc:
        return f"terminal capture unavailable: {exc}"
    return ""


def main() -> int:
    parser = argparse.ArgumentParser(description="Run the rendered Borrowed Turns smoke harness.")
    parser.add_argument("--godot", default="/usr/bin/godot")
    parser.add_argument("--capture-dir", required=True, type=Path)
    parser.add_argument("--timeout", type=positive_timeout, default=120.0)
    args = parser.parse_args()

    # Keep the final path component intact so an existing symlink is refused too.
    capture_dir = Path(os.path.abspath(args.capture_dir))
    print(f"Rendered smoke: preparing fresh capture directory {capture_dir}", flush=True)
    try:
        capture_dir.mkdir(parents=True, exist_ok=False)
    except FileExistsError:
        return reject(f"capture path already exists: {capture_dir}")
    except OSError as exc:
        return reject(f"could not create capture directory: {exc}")

    print(f"Rendered smoke: launching {args.godot}; timeout {args.timeout:g}s", flush=True)
    try:
        result = subprocess.run(
            [args.godot, "--path", str(PROJECT), "--script", "res://ui/smoke.gd", "--", f"--capture-dir={capture_dir}"],
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            timeout=args.timeout,
            check=False,
        )
    except subprocess.TimeoutExpired as exc:
        forward_output(exc.stdout)
        return reject(f"child timed out after {args.timeout:g} seconds", 124)
    except OSError as exc:
        return reject(f"child could not start: {exc}")

    forward_output(result.stdout)
    if result.returncode != 0:
        if result.returncode < 0:
            return reject(f"child terminated by signal {-result.returncode}", 128 - result.returncode)
        return reject(f"child exited with status {result.returncode}", result.returncode)

    print("Rendered smoke: child exited 0; checking completion and terminal capture", flush=True)
    reason = verify_output(result.stdout, capture_dir)
    if reason:
        return reject(reason)
    print(f"Rendered smoke: accepted; terminal capture {capture_dir / 'r2-escaped.png'}", flush=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())
