#!/usr/bin/env python3
"""Assert run_tests.sh stops when the schema-trial validator fails or is missing.

run_tests.sh called test_fixtures/schema_trial/check_trial_fixtures.py and ignored
its exit status, and the runner does not use `set -e`. FULL-AUDIT-2026-09-14
proved it by fault injection: a validator exiting 1 plus passing Godot suites
printed "PASS: all suites green" and exited 0. The real fixtures pass, so a real
run can only produce the passing shape; this drives a copy of the actual runner
with a stub validator and a stub `godot` instead.

The passing case is load-bearing. Without it the failing cases could go green
because the harness itself is broken, which is the exact failure being tested.
"""

import os
import shutil
import stat
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
VALIDATOR = Path("test_fixtures/schema_trial/check_trial_fixtures.py")

# Stands in for Godot: the import pass writes the class cache run_tests.sh checks
# for, and a suite run prints a Results line the classifier accepts. Every call is
# logged so a test can tell whether the runner got past the validator.
GODOT_STUB = """#!/usr/bin/env bash
echo "$*" >> "$GODOT_CALL_LOG"
case " $* " in
  *" --import "*) mkdir -p .godot && touch .godot/global_script_class_cache.cfg ;;
  *) echo "Results: 1 passed, 0 failed" ;;
esac
exit 0
"""


def write_executable(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text)
    path.chmod(path.stat().st_mode | stat.S_IXUSR)


class RunTestsSchemaGateTests(unittest.TestCase):
    def setUp(self):
        self._tmp = tempfile.TemporaryDirectory()
        self.root = Path(self._tmp.name)
        self.project = self.root / "project"
        # The real runner and classifier; everything they call out to is stubbed.
        (self.project / "scripts" / "ci").mkdir(parents=True)
        shutil.copy2(REPO_ROOT / "run_tests.sh", self.project / "run_tests.sh")
        shutil.copy2(
            REPO_ROOT / "scripts" / "ci" / "suite_classification.sh",
            self.project / "scripts" / "ci" / "suite_classification.sh",
        )
        # The required non-Godot runner is stubbed green: it is what runs this file,
        # so calling the real one from here would recurse.
        write_executable(
            self.project / "scripts" / "ci" / "run_required_non_godot_tests.sh",
            "#!/usr/bin/env bash\nexit 0\n",
        )
        (self.project / "scripts" / "tests").mkdir(parents=True)
        (self.project / "scripts" / "tests" / "test_stub.gd").write_text("")
        self.bin = self.root / "bin"
        write_executable(self.bin / "godot", GODOT_STUB)
        self.godot_log = self.root / "godot-calls.log"

    def tearDown(self):
        self._tmp.cleanup()

    def write_validator(self, exit_code: int) -> None:
        write_executable(
            self.project / VALIDATOR,
            f"import sys\nprint('validator stub exiting {exit_code}')\nsys.exit({exit_code})\n",
        )

    def run_runner(self) -> subprocess.CompletedProcess:
        env = {
            key: value
            for key, value in os.environ.items()
            if key not in {"GIT_DIR", "GIT_WORK_TREE", "GIT_INDEX_FILE", "GIT_PREFIX", "TEST_JOBS"}
        }
        env["PATH"] = f"{self.bin}{os.pathsep}{env.get('PATH', '')}"
        env["GODOT_CALL_LOG"] = str(self.godot_log)
        return subprocess.run(
            ["bash", str(self.project / "run_tests.sh"), "--serial"],
            cwd=self.project,
            env=env,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            timeout=120,
        )

    def godot_was_called(self) -> bool:
        return self.godot_log.exists() and self.godot_log.read_text().strip() != ""

    def test_passing_validator_reaches_the_godot_suites(self):
        """Control: the harness can produce a pass, so the red cases mean something."""
        self.write_validator(0)
        result = self.run_runner()
        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertIn("PASS: all suites green", result.stdout)
        self.assertTrue(self.godot_was_called(), result.stdout)

    def test_failing_validator_fails_the_run(self):
        """The audited hole: validator exit 1 used to end in PASS and exit 0."""
        self.write_validator(1)
        result = self.run_runner()
        self.assertEqual(result.returncode, 1, result.stdout)
        self.assertIn("FAIL: schema-trial fixture validation failed", result.stdout)
        self.assertNotIn("PASS", result.stdout)
        self.assertFalse(self.godot_was_called(), result.stdout)

    def test_missing_validator_fails_the_run(self):
        result = self.run_runner()
        self.assertEqual(result.returncode, 1, result.stdout)
        self.assertIn("schema-trial validator", result.stdout)
        self.assertIn("is missing", result.stdout)
        self.assertNotIn("PASS", result.stdout)
        self.assertFalse(self.godot_was_called(), result.stdout)


if __name__ == "__main__":
    sys.exit(0 if unittest.main(exit=False).result.wasSuccessful() else 1)
