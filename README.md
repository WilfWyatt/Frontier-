# FRONTIER — Rebuild 01

Clean Godot 4.7.x mobile-first vertical slice built from the canonical FRONTIER Story, Universe, Game Design and GDScript reference documents.

## Included
- Landscape 1280x720 project.
- Clean screen architecture: cockpit, galaxy, system, exploration, market, ship, missions, combat.
- Frontier economy, cargo, repairs, upgrades and salvage.
- Local galaxy navigation with fuel costs.
- Quiet exploration mode distinct from combat.
- Arcade combat loop with movement, primary fire and missile.
- First canonical story hook: lost survey vessel and “They are not where the records say they are.”
- Faction reputation and discovery data.
- Original SVG ship/enemy art assets.
- No external asset dependencies.

## Verification note
This environment does not include a Godot executable, so the project was statically reviewed rather than launched in the Godot editor. The code follows the project’s Godot 4.7 typed-GDScript conventions and deliberately avoids the previous giant-script/UI-state architecture, but editor/runtime verification should be the next check on a machine with Godot 4.7.x.
