#!/usr/bin/env python3
"""Convert UnitData .tres files from Array[Dictionary] inventory to Array[InventoryEntry]."""

import re
import ast
import sys
import os

INVENTORY_ENTRY_PATH = "res://scripts/resources/InventoryEntry.gd"
INVENTORY_ENTRY_EXT_ID = "2"  # ext_resource id for InventoryEntry.gd

def convert_file(path: str) -> None:
    with open(path, encoding="utf-8") as f:
        content = f.read()

    # Find the inventory line
    inv_match = re.search(r'^inventory = \[(.*)?\]$', content, re.MULTILINE)
    if not inv_match:
        print(f"  SKIP (no inventory line): {os.path.basename(path)}")
        return

    inv_raw = inv_match.group(1).strip()

    # Check if already migrated (would contain SubResource)
    if "SubResource" in content:
        print(f"  SKIP (already migrated): {os.path.basename(path)}")
        return

    if not inv_raw:
        # Empty inventory — just change the type annotation, no sub-resources needed
        entries = []
    else:
        # Parse the Python-compatible dict literal (Godot dict syntax is valid Python)
        entries = ast.literal_eval(f"[{inv_raw}]")

    # Build sub_resource blocks and reference list
    sub_resource_blocks = []
    references = []
    for i, entry in enumerate(entries, start=1):
        sid = f"IE_{i}"
        etype = entry.get("type", "weapon")
        lines = [
            f'[sub_resource type="Resource" id="{sid}"]',
            f'script = ExtResource("{INVENTORY_ENTRY_EXT_ID}")',
            f'entry_type = "{etype}"',
        ]
        if etype == "weapon":
            lines.append(f'weapon_id = "{entry.get("weapon_id", "")}"')
            lines.append(f'uses_remaining = {entry.get("uses_remaining", 0)}')
        elif etype == "item":
            lines.append(f'item_id = "{entry.get("item_id", "")}"')
            lines.append(f'uses_remaining = {entry.get("uses_remaining", 0)}')
        elif etype == "equip":
            lines.append(f'accuracy = {entry.get("accuracy", 0)}')
            lines.append(f'damage = {entry.get("damage", 0)}')
            lines.append(f'crit = {entry.get("crit", 0)}')
            lines.append(f'dodge = {entry.get("dodge", 0)}')
        sub_resource_blocks.append("\n".join(lines))
        references.append(f'SubResource("{sid}")')

    new_inventory_line = f'inventory = [{", ".join(references)}]'

    # Update load_steps: original = ext_resources_count + 1
    # new = ext_resources_count + 1 (InventoryEntry) + len(entries) + 1
    ls_match = re.search(r'load_steps=(\d+)', content)
    if ls_match:
        old_steps = int(ls_match.group(1))
        new_steps = old_steps + 1 + len(entries)  # +1 ext, +N sub_resources
        content = content.replace(f"load_steps={old_steps}", f"load_steps={new_steps}", 1)

    # Add InventoryEntry ext_resource after the UnitData ext_resource line
    ie_ext_line = f'[ext_resource type="Script" path="{INVENTORY_ENTRY_PATH}" id="{INVENTORY_ENTRY_EXT_ID}"]'
    content = re.sub(
        r'(\[ext_resource type="Script" path="res://scripts/resources/UnitData\.gd"[^\]]*\])',
        r'\1\n' + ie_ext_line,
        content, count=1
    )

    # Insert sub_resource blocks before the [resource] section
    if sub_resource_blocks:
        sub_block = "\n\n".join(sub_resource_blocks) + "\n\n"
        content = content.replace("\n[resource]\n", f"\n{sub_block}[resource]\n", 1)

    # Replace inventory line
    content = re.sub(r'^inventory = \[.*?\]$', new_inventory_line, content, flags=re.MULTILINE)

    with open(path, "w", encoding="utf-8") as f:
        f.write(content)

    print(f"  OK {os.path.basename(path)} ({len(entries)} entries)")


def main():
    files = []
    for root, _, fnames in os.walk("/workspace/data"):
        for fname in fnames:
            if fname.endswith(".tres"):
                files.append(os.path.join(root, fname))

    files.sort()
    print(f"Converting {len(files)} .tres files...")
    for path in files:
        convert_file(path)
    print("Done.")


if __name__ == "__main__":
    main()
