#!/usr/bin/env bash
# Run all GDScript tests; exit 1 if any fail
cd "$(dirname "$0")"
TESTS=(
  test_data_layer
  test_grid_manager
  test_map_grid
  test_game_map_scene
  test_unit_stats
  test_unit_selection
  test_targeting
  test_combat
  test_enemy_ai
  test_skill_item_handler
  test_snapshot_coverage
  test_map_cursor
  test_map_cursor_selection
  test_map_cursor_input
  test_turn_manager
  test_game_state
  test_data_manager
  test_action_menu
  test_settings_manager
  test_settings_screen
  test_new_game_screen
  test_unit_details_screen
  test_hud
  test_level_up_screen
  test_promotion_screen
  test_reclass_screen
  test_pair_up_registry
  test_pair_up_combat_context
)
fail_count=0
for t in "${TESTS[@]}"; do
  out=$(godot --headless --path . --script "res://scripts/tests/$t.gd" 2>&1)
  exit_code=$?
  summary=$(echo "$out" | grep "Results")
  echo "$t: ${summary:-'(no summary)'}"
  if [[ $exit_code -ne 0 ]]; then
    fail_count=$((fail_count + 1))
  fi
done
echo ""
if [[ $fail_count -gt 0 ]]; then
  echo "FAIL: $fail_count suite(s) failed"
  exit 1
fi
echo "PASS: all suites green"
