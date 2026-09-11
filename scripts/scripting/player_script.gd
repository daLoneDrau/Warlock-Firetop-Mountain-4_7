## Attached (via [WarlockScriptComponent]) to the player entity —
## WarlockEntityManager.create_player_entity() is the only place that
## constructs one. Shaped like PotionScript (scripts/scripting/
## potion_script.gd): an [EntityScript] with on_<event> methods that
## EntityScript itself discovers by reflection against ScriptEvent's
## registry (see _build_event_method_map()) — nothing here subscribes
## manually.
##
## on_initialized() is a dummy on purpose: nothing in the GDD/rules-
## reference/UI-UX shell spec defines real player-entity setup logic
## yet. Its job right now is just to prove the chain actually fires —
## ScriptComponent attached -> ScriptSystem's entity_added-driven
## auto-attach picks it up -> ScriptEvent.INITIALIZED dispatches into
## this method — so whatever real logic eventually belongs here has a
## proven place to land instead of being bolted onto
## WarlockEntityManager.create_player_entity() directly.
class_name PlayerScript
extends EntityScript


func on_initialized(ctx: Dictionary) -> Dictionary:
	push_warning("PlayerScript.on_initialized: dummy handler fired for %s" % entity_id)
	return {}
