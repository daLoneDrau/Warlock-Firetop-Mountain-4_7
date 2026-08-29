## Concrete [EntityManager] for Warlock of Firetop Mountain.
##
## Registered as an autoload singleton (name: "WarlockEntityManager") in
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


## TODO: no item-entity tagging convention has been defined for this
## project yet (no ItemFlags/item-category decision made in any design doc).
## Stubbed false until that's designed.
func is_item(_e: Entity) -> bool:
	return false


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
## (core/entity_manager.gd, not overridden by this class) assumes a
## PlayerComponent with an `equipped_items` field that doesn't exist anywhere
## in this project's design — it looks like leftover scaffolding from a
## different game built on this same ECS. It will throw at runtime the first
## time any entity's `alive` is set false while a PC-tagged entity exists.
## Not reachable this session (nothing sets `alive = false` yet, and MVP has
## no death path per GDD §8) — noted here so it isn't a surprise later.
func unequip_from_inventory(_player_entity: Entity, _item_entity: Entity) -> bool:
	return false


## TODO: no ScriptSystem wiring exists yet for this project. No-op until
## entity scripting is actually used.
func send_init_script_event(_entity: Entity) -> void:
	pass