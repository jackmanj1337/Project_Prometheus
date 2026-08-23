---
Role: topic
---

# FE-Style Map Sprite Importer for Godot
## Initial Automated Version

This guide walks through building the **first usable version** of a sprite importer for a Fire Emblem-style tactics game in Godot.

The goal of this version is:

```text
Drop in:
- walk.png
- stand.png

Automatically generate:
- SpriteFrames resource
- AnimatedSprite2D scene
- usable map animations
```

This version intentionally keeps things simple:
- fixed sprite sheet layouts
- fixed frame sizes
- no combat animations
- no palette swapping
- no advanced metadata

Once this works, it becomes the foundation for a much larger automated asset pipeline.

---

# Final Result

After following this guide, you should be able to:

1. Put sprite sheets into:
   ```text
   res://assets/raw/
   ```

2. Run an importer button in the editor

3. Automatically generate:
   ```text
   res://assets/generated/mage/
       mage_frames.tres
       mage_unit.tscn
   ```

4. Open the generated scene and immediately play animations

---

# Requirements

## Software

Install:

- Godot 4.x
- Git (optional)
- A code editor

Recommended:
- VSCode
- Godot built-in script editor

---

# Recommended Project Structure

Create this folder structure:

```text
res://
├── addons/
│   └── fe_importer/
│       ├── plugin.cfg
│       ├── plugin.gd
│       └── importer.gd
│
├── assets/
│   ├── raw/
│   └── generated/
│
├── scenes/
└── scripts/
```

---

# Step 1 — Create a New Godot Project

Open Godot and create a new 2D project.

Recommended settings:

- Renderer: Forward+
- Compatibility: optional for older hardware

Save the project.

---

# Step 2 — Enable Version Control (Recommended)

Initialize Git.

Example:

```bash
git init
```

Create `.gitignore`:

```text
.import/
.export/
```

---

# Step 3 — Create the Plugin Folder

Create:

```text
res://addons/fe_importer/
```

Inside it create:

```text
plugin.cfg
plugin.gd
importer.gd
```

---

# Step 4 — Create plugin.cfg

Contents:

```ini
[plugin]
name="FE Importer"
description="Imports FE-style map sprites"
author="YourName"
version="1.0"
script="plugin.gd"
```

---

# Step 5 — Create plugin.gd

This creates a toolbar button inside the Godot editor.

```gdscript
extends EditorPlugin

var import_button

func _enter_tree():
    import_button = Button.new()
    import_button.text = "Import FE Sprites"

    import_button.pressed.connect(_on_import_pressed)

    add_control_to_container(
        CONTAINER_TOOLBAR,
        import_button
    )

func _exit_tree():
    remove_control_from_container(
        CONTAINER_TOOLBAR,
        import_button
    )

    import_button.queue_free()

func _on_import_pressed():
    var importer = preload("res://addons/fe_importer/importer.gd").new()
    importer.run_import()
```

---

# Step 6 — Enable the Plugin

In Godot:

```text
Project → Project Settings → Plugins
```

Enable:
```text
FE Importer
```

You should now see:

```text
Import FE Sprites
```

in the toolbar.

---

# Step 7 — Create the Raw Asset Folder

Create:

```text
res://assets/raw/
```

Add your sprite sheets.

Example:

```text
res://assets/raw/mage/
    mage-walk.png
    mage-stand.png
```

---

# Step 8 — Understand the Expected Layout

This initial importer assumes:

- 32x32 frames
- 4 directions
- 4 walk frames
- rows represent directions

Expected layout:

```text
Down   [1][2][3][4]
Left   [1][2][3][4]
Right  [1][2][3][4]
Up     [1][2][3][4]
```

Stand sheet:

```text
Down   [1]
Left   [1]
Right  [1]
Up     [1]
```

---

# Step 9 — Create importer.gd

This script performs all importing.

Initial structure:

```gdscript
extends RefCounted

const RAW_PATH = "res://assets/raw/"
const GENERATED_PATH = "res://assets/generated/"

const FRAME_WIDTH = 32
const FRAME_HEIGHT = 32

const DIRECTIONS = [
    "down",
    "left",
    "right",
    "up"
]

func run_import():
    print("Starting FE sprite import...")

    var raw_dir = DirAccess.open(RAW_PATH)

    if raw_dir == null:
        push_error("Could not open raw asset folder")
        return

    raw_dir.list_dir_begin()

    var folder_name = raw_dir.get_next()

    while folder_name != "":
        if raw_dir.current_is_dir():
            if folder_name != "." and folder_name != "..":
                import_unit(folder_name)

        folder_name = raw_dir.get_next()

    raw_dir.list_dir_end()

    print("Import complete.")
```

---

# Step 10 — Add Unit Import Logic

Add:

```gdscript
func import_unit(unit_name):
    print("Importing: ", unit_name)

    var unit_path = RAW_PATH + unit_name + "/"

    var walk_path = unit_path + unit_name + "-walk.png"
    var stand_path = unit_path + unit_name + "-stand.png"

    if not FileAccess.file_exists(walk_path):
        push_error("Missing walk sheet: " + walk_path)
        return

    if not FileAccess.file_exists(stand_path):
        push_error("Missing stand sheet: " + stand_path)
        return

    var frames = build_sprite_frames(
        walk_path,
        stand_path
    )

    save_resources(unit_name, frames)
```

---

# Step 11 — Build SpriteFrames

Add:

```gdscript
func build_sprite_frames(walk_path, stand_path):
    var frames = SpriteFrames.new()

    add_walk_animations(frames, walk_path)
    add_idle_animations(frames, stand_path)

    return frames
```

---

# Step 12 — Add Walk Animation Extraction

Add:

```gdscript
func add_walk_animations(frames, texture_path):
    var texture = load(texture_path)

    for row in range(4):
        var direction = DIRECTIONS[row]

        var animation_name = "walk_" + direction

        frames.add_animation(animation_name)
        frames.set_animation_speed(animation_name, 6)

        for col in range(4):
            var atlas = AtlasTexture.new()

            atlas.atlas = texture

            atlas.region = Rect2(
                col * FRAME_WIDTH,
                row * FRAME_HEIGHT,
                FRAME_WIDTH,
                FRAME_HEIGHT
            )

            frames.add_frame(animation_name, atlas)
```

---

# Step 13 — Add Idle Animation Extraction

Add:

```gdscript
func add_idle_animations(frames, texture_path):
    var texture = load(texture_path)

    for row in range(4):
        var direction = DIRECTIONS[row]

        var animation_name = "idle_" + direction

        frames.add_animation(animation_name)
        frames.set_animation_speed(animation_name, 1)

        var atlas = AtlasTexture.new()

        atlas.atlas = texture

        atlas.region = Rect2(
            0,
            row * FRAME_HEIGHT,
            FRAME_WIDTH,
            FRAME_HEIGHT
        )

        frames.add_frame(animation_name, atlas)
```

---

# Step 14 — Save Resources

Add:

```gdscript
func save_resources(unit_name, frames):
    var unit_output = GENERATED_PATH + unit_name + "/"

    DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path(unit_output)
    )

    var frames_path = unit_output + unit_name + "_frames.tres"

    ResourceSaver.save(
        frames,
        frames_path
    )

    create_unit_scene(
        unit_name,
        frames,
        unit_output
    )
```

---

# Step 15 — Create the Unit Scene

Add:

```gdscript
func create_unit_scene(unit_name, frames, output_path):
    var root = Node2D.new()

    root.name = unit_name.capitalize()

    var sprite = AnimatedSprite2D.new()

    sprite.sprite_frames = frames
    sprite.animation = "idle_down"

    root.add_child(sprite)

    sprite.owner = root

    var packed = PackedScene.new()

    packed.pack(root)

    var scene_path = output_path + unit_name + "_unit.tscn"

    ResourceSaver.save(
        packed,
        scene_path
    )
```

---

# Step 16 — Test the Importer

Place spritesheets into:

```text
res://assets/raw/mage/
```

Example:

```text
mage-walk.png
mage-stand.png
```

Then press:

```text
Import FE Sprites
```

Expected output:

```text
res://assets/generated/mage/
```

containing:

```text
mage_frames.tres
mage_unit.tscn
```

---

# Step 17 — Verify Animations

Open:

```text
mage_unit.tscn
```

Select:
```text
AnimatedSprite2D
```

Verify animations exist:

```text
idle_down
idle_left
idle_right
idle_up

walk_down
walk_left
walk_right
walk_up
```

Play them in the preview panel.

---

# Step 18 — Add Runtime Movement (Optional)

Simple movement test:

```gdscript
extends CharacterBody2D

@onready var sprite = $AnimatedSprite2D

func _physics_process(delta):
    var input_vector = Input.get_vector(
        "ui_left",
        "ui_right",
        "ui_up",
        "ui_down"
    )

    velocity = input_vector * 100

    move_and_slide()

    update_animation(input_vector)

func update_animation(direction):
    if direction.length() == 0:
        sprite.play("idle_down")
        return

    if abs(direction.x) > abs(direction.y):
        if direction.x > 0:
            sprite.play("walk_right")
        else:
            sprite.play("walk_left")
    else:
        if direction.y > 0:
            sprite.play("walk_down")
        else:
            sprite.play("walk_up")
```

---

# Step 19 — Common Problems

## Problem: Frames Are Offset

Cause:
- wrong frame size

Fix:
- adjust:
  ```gdscript
  FRAME_WIDTH
  FRAME_HEIGHT
  ```

---

## Problem: Wrong Directions

Cause:
- source sheet uses different row order

Fix:
- change:

```gdscript
const DIRECTIONS = [...]
```

---

## Problem: Texture Bleeding

Fix:
- disable filtering

In import settings:
```text
Filter = Off
```

---

# Step 20 — Recommended Next Improvements

Once the basic importer works, add:

## Priority 1
- automatic filename parsing
- recursive folder scanning
- configurable layouts

## Priority 2
- metadata files
- combat animations
- mounted units

## Priority 3
- palette swapping
- editor UI
- animation previews

---

# Recommended Long-Term Architecture

The ideal future system:

```text
Raw Assets
    ↓
Importer
    ↓
Generated Resources
    ↓
Runtime Unit Database
    ↓
Gameplay Systems
```

Keep imported assets generated automatically.

Avoid hand-editing generated resources whenever possible.

---

# Final Advice

The biggest success factor is consistency.

Do not attempt:
- automatic visual detection
- AI parsing
- arbitrary spritesheet guessing

Instead:
- define standards
- import into YOUR format
- adapt source assets into those standards

That keeps the pipeline maintainable and scalable.
