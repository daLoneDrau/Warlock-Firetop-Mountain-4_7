## Concrete [EntityManager] for Warlock of Firetop Mountain.
##
## Registered as an autoload singleton (name: "WarlockEntityManager_auto") in
## project.godot. Implements the abstract methods EntityManager requires to
## be instantiable at all — most are placeholder stubs (see TODOs) since
## nothing in the GDD, rules-reference, or UI/UX shell spec defines their
## real semantics yet for this project. They exist only to satisfy the
## abstract contract during engine bootstrap.
class_name WarlockEntityManager
extends EntityManager


## Determines if an [Entity] is tagged as the player character.
## This one IS spec'd: Scene.get_player() (engine/scene.gd) already relies
## on PlayerTags.Tag.PC to find the player entity, so this must agree with
## that convention.
func is_pc(e: Entity) -> bool:
	return e != null and e.tags.has(PlayerTags.Tag.PC)


## Determines if an [Entity] is an item — has an [ItemComponent] (or any
## subclass; ItemComponent's own IS_SLOT_ROOT means all concrete item
## types share this one check).
func is_item(e: Entity) -> bool:
	return e != null and e.has_component("ItemComponent")


## TODO: no "unique entity" concept has been defined for this project yet.
## Stubbed false until that's designed.
func is_unique(_e: Entity) -> bool:
	return false


## TODO: no spell system exists in this project (not in MVP scope, GDD §8).
## No-op until a spell/combat system is designed post-MVP.
func kill_spells_on(_e_id: String) -> void:
	pass


## TODO: the equipment system is explicitly deferred to implementation-level
## work (GDD §6) and hasn't been designed yet. Stubbed to return false
## (no unequip performed) until that design exists.
##
## NOTE (flagged, not fixed here): the base EntityManager.destroy_dynamic_entity()
## (core/entity_manager.gd, not overridden by this class) reads a
## `player_data.equipped_items` field. Confirmed against the actual
## PlayerComponent source (pulled from the full repo tree): that class has
## no `equipped_items` field at all — it's session-state only (is_alive,
## in_menu, in_cutscene, play_time). This is leftover scaffolding from a
## different game built on this same ECS, not something that will ever
## work as written. It will throw at runtime the first time any entity's
## `alive` is set false while a PC-tagged entity exists. Not reachable
## this session (nothing sets `alive = false` yet, and MVP has no death
## path per GDD §8) — noted here so it isn't a surprise later.
func unequip_from_inventory(_player_entity: Entity, _item_entity: Entity) -> bool:
	return false


## Still a no-op even though WarlockScriptSystem_auto now exists — scripts
## attach automatically via ScriptSystem's own Switchboard subscription to
## "entity_added" (see warlock_script_system.gd), not through this method.
## Nothing in this project calls send_init_script_event() as a trigger for
## anything; kept as a no-op stub to satisfy the abstract contract.
func send_init_script_event(_entity: Entity) -> void:
	pass
