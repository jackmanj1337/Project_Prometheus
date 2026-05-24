# Project_Prometheus
A repo to track a small side project game I am making to test some tools.

## Running tests

`bash run_tests.sh` runs the 35 headless GDScript test suites in the current
checkout.

For a fresh-clone, CI-style run that bootstraps Godot's import/class cache first,
use `bash scripts/ci/run_headless_tests.sh`.

`run_headless_tests.sh` is the portable option for clean environments because it
forces Godot's import/class-cache bootstrap before the suite. In an existing
working checkout, `bash run_tests.sh` is the normal fast path.

## GitHub Actions

This repo includes two GitHub Actions workflows:
- `.github/workflows/tests-pr.yml`
- `.github/workflows/tests-push.yml`

They:
- installs Godot `4.6`
- runs separate workflows for `push` and `pull_request`
- runs `bash scripts/ci/run_headless_tests.sh`
  which performs the import scan and then runs `bash run_tests.sh`

For branch protection, require the `godot-tests-pr` check on `main`.

After you push the workflow to GitHub, verify that **Actions** are enabled for
the repo and confirm the first run passes.
