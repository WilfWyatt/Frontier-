# FRONTIER — Build 03 GitHub Update

Apply this package **on top of FRONTIER Build 02**.

## Replace these files

```text
scripts/main.gd
scripts/combat.gd
```

Copy both files into the matching `scripts/` directory in your GitHub working copy and replace the existing files.

## No asset changes

Build 03 does not add, remove or change assets, scenes, or `project.godot`.

## What this fixes

- The terminal UI was intercepting touch/mouse input before the combat Node2D could receive it.
- The mobile FIRE button was only registering a momentary touch rather than a held state.
- Combat processing/input handling is now explicitly enabled while the combat node is active.

## Suggested commit

`Fix mobile combat input and continuous fire`
