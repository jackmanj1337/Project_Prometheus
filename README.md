# Project_Prometheus
A repo to track a small side project game I am making to test some tools.

## Running tests

`bash run_tests.sh` runs the GDScript test suites headlessly.

For a fresh-clone, CI-style run that bootstraps Godot's import/class cache first,
use `bash scripts/ci/run_headless_tests.sh`.

**On a fresh clone, open the project in the Godot editor once before running tests.**
The headless test runner resolves `class_name` types through Godot's global class
cache (`.godot/global_script_class_cache.cfg`), which is gitignored and only generated
by an editor project scan. Without that scan, tests fail with errors like
`Could not find type "X" in the current scope`.

When a new `class_name` script is added outside the editor, either re-open the editor
to regenerate the cache or add the entry to `.godot/global_script_class_cache.cfg` by
hand (copy an existing block; set `base`, `class`, `path`).

## GitHub Actions

This repo includes a first-pass GitHub Actions workflow at
`.github/workflows/tests.yml`.

It:
- installs Godot `4.6`
- runs `bash scripts/ci/run_headless_tests.sh`
  which performs the import scan and then runs `bash run_tests.sh`

After you push the workflow to GitHub, verify that **Actions** are enabled for
the repo and confirm the first run passes.
