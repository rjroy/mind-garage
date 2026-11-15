"""Black-box acceptance checks for the real rendered-smoke gate CLI."""

import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest


PROJECT = Path(__file__).resolve().parents[1]
GATE = PROJECT / "tools" / "rendered_smoke_gate.py"
FAKE = Path(__file__).with_name("fake_smoke_process.py")


class RenderedSmokeGateTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory(prefix="borrowed-turns-gate-", dir="/tmp/opencode")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.child = self.root / "fake-godot"
        shutil.copyfile(FAKE, self.child)
        self.child.chmod(0o755)
        self.capture = self.root / "captures"
        self.started = self.root / "started"

    def invoke(self, scenario: str, timeout: float = 2.0) -> subprocess.CompletedProcess[str]:
        self.started = self.root / ("started-" + scenario)
        env = os.environ.copy()
        env["FAKE_SMOKE_SCENARIO"] = scenario
        env["FAKE_SMOKE_STARTED"] = str(self.started)
        env["FAKE_PROJECT_ROOT"] = str(PROJECT)
        return subprocess.run(
            [sys.executable, str(GATE), "--godot", str(self.child), "--capture-dir", str(self.capture), "--timeout", str(timeout)],
            cwd=PROJECT,
            env=env,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            timeout=8,
            check=False,
        )

    def test_completed_run_is_accepted(self) -> None:
        result = self.invoke("completed")
        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertTrue(self.started.is_file(), result.stdout)
        self.assertTrue((self.capture / "r2-escaped.png").is_file(), result.stdout)
        self.assertIn("179 checks, 0 failures", result.stdout)

    def test_clean_exit_without_completion_is_rejected(self) -> None:
        result = self.invoke("early")
        self.assertTrue(self.started.is_file(), result.stdout)
        self.assertNotEqual(result.returncode, 0, result.stdout)

    def test_marker_without_fresh_terminal_capture_is_rejected(self) -> None:
        for scenario in ("missing_image", "bad_image"):
            with self.subTest(scenario=scenario):
                # Each run must get a fresh output directory.
                self.capture = self.root / scenario
                result = self.invoke(scenario)
                self.assertTrue(self.started.is_file(), result.stdout)
                self.assertNotEqual(result.returncode, 0, result.stdout)

    def test_stale_capture_directory_is_rejected_without_launch(self) -> None:
        self.capture.mkdir()
        (self.capture / "r2-escaped.png").write_bytes(b"stale artifact")
        result = self.invoke("early")
        self.assertNotEqual(result.returncode, 0, result.stdout)
        self.assertFalse(self.started.exists(), result.stdout)

    def test_failure_or_forged_completion_is_rejected(self) -> None:
        for scenario in ("failed", "bad_summary", "zero_checks", "embedded_summary", "script_error", "error"):
            with self.subTest(scenario=scenario):
                self.capture = self.root / scenario
                result = self.invoke(scenario)
                self.assertTrue(self.started.is_file(), result.stdout)
                self.assertNotEqual(result.returncode, 0, result.stdout)

    def test_signal_or_timeout_is_rejected(self) -> None:
        for scenario in ("signal", "timeout"):
            with self.subTest(scenario=scenario):
                self.capture = self.root / scenario
                result = self.invoke(scenario, timeout=1.0)
                self.assertTrue(self.started.is_file(), result.stdout)
                self.assertNotEqual(result.returncode, 0, result.stdout)


if __name__ == "__main__":
    unittest.main()
