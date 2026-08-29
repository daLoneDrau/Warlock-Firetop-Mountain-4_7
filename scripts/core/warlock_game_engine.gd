## Concrete [GameEngine] for Warlock of Firetop Mountain.
##
## Registered as an autoload singleton (name: "WarlockGameEngine") in
## project.godot — must load AFTER Switchboard_auto, DiceTower, and
## WarlockEntityManager, since _initialize_systems() below references the
## WarlockEntityManager autoload directly by its global name.
##
## This session's scope is deliberately bare: wire the engine substrate
## together and prove the boot chain works end to end via a trivial
## placeholder scene. No Title/CharacterCreation content yet (§12 of the
## UI/UX shell spec) — that's the next step once this is confirmed working.
class_name WarlockGameEngine
extends GameEngine


## GameEngine's base _ready() sets process_mode, running, and caches the
## window reference — call it first, then bootstrap.
##
## run() is deferred rather than called inline: GameEngine.run() eventually
## reaches change_scene() -> get_tree().change_scene_to_file(), which calls
## remove_child() on the tree root internally. During an autoload's own
## _ready(), the SceneTree is still busy adding the initial scene, and
## remove_child() isn't allowed while the tree is in that blocked state
## ("Parent node is busy adding/removing children"). Deferring run() lets
## that initial setup finish first.
func _ready() -> void:
	super._ready()
	call_deferred("run")


## Wires the EntityManager autoload onto this engine instance. GameEngine
## itself never assigns `entity_manager` — per §1 of the UI/UX shell spec,
## WarlockEntityManager is its own autoload singleton, not something
## GameEngine instantiates itself.
func _initialize_systems() -> void:
	entity_manager = WarlockEntityManager_auto


## No game assets to preload yet — content authoring (rooms, fonts, UI
## sprites, sounds) comes later. Just stand up an empty AssetsLibrary so
## `assets` isn't null for anything that checks it.
func load_resources() -> void:
	assets = AssetsLibrary.new()


## No game-specific window setup yet (resolution, fullscreen policy, etc.)
## — nothing in the GDD specifies this beyond the HTML5/itch.io target
## already reflected in project.godot's [display] section.
func _setup_window() -> void:
	pass


## Bootstrap-only initial scene: a trivial placeholder proving the chain
## booted, NOT the real TitleScene (§12.2 of the UI/UX shell spec) — that
## still needs the diorama pipeline (§5, not built yet) and save-existence
## detection (§7, not built yet).
func _start_game() -> void:
	change_scene("boot_test", "res://scenes/BootTest.tscn")
