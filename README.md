# Project_Prometheus
A repo to track a small side project game I am making to test some tools.

## Running tests

`bash run_tests.sh` runs the GDScript test suites headlessly.

**On a fresh clone, open the project in the Godot editor once before running tests.**
The headless test runner resolves `class_name` types through Godot's global class
cache (`.godot/global_script_class_cache.cfg`), which is gitignored and only generated
by an editor project scan. Without that scan, tests fail with errors like
`Could not find type "X" in the current scope`.

When a new `class_name` script is added outside the editor, either re-open the editor
to regenerate the cache or add the entry to `.godot/global_script_class_cache.cfg` by
hand (copy an existing block; set `base`, `class`, `path`).
