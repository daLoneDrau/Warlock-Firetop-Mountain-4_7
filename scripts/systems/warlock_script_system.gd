## Concrete [ScriptSystem] for Warlock of Firetop Mountain.
##
## Registered as an autoload singleton (name: "WarlockScriptSystem_auto"),
## NOT a scene-registered [GameSystem] like [WarlockInventorySystem] —
## [ScriptSystem] maintains its own `_entity_manager` field separately
## from the `scene`-based `get_entity_manager()` convenience accessor,
## and its own doc comment says that field "will be set in concrete
## implementations using Autoload instances." Being an autoload also means
## its `_enter_tree()` Switchboard subscriptions (entity_added/removed,
## script_event) are live for the whole run regardless of which Scene is
## current — needed since item-use can happen whenever, not just in one
## scene.
##
## Must load AFTER WarlockEntityManager_auto in project.godot (this file's
## `_on_ready()` reads that autoload directly).
class_name WarlockScriptSystem
extends ScriptSystem


func _on_ready() -> void:
	_entity_manager = WarlockEntityManager_auto


func _on_initialize() -> void:
	pass  # never scene-registered, so never called — present to satisfy
# the abstract contract only.


func _on_cleanup() -> void:
	pass


func _process_system(_delta: float) -> void:
	pass  # fully event-driven via Switchboard subscriptions, no per-frame work


func handle_event(_event_name: String, _payload: Dictionary = {}) -> bool:
	return true


## TODO: no spatial/positional gameplay exists in this project — dungeon
## nodes aren't spatial coordinates, and nothing calls _resolve_targets()
## with a radius this session. Stubbed true (no filtering) rather than
## implemented, since there's nothing to measure distance between yet.
func _within_radius(_a, _b, _radius: int) -> bool:
	return true
