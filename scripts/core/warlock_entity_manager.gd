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


## Rolls Initial Skill/Stamina/Luck per Rules_reference.md's adapted
## starting ranges (Skill = 1d6+6, Stamina = 2d6+12, Luck = 1d6+6) and
## builds the PC entity around them: [WarlockAbilitiesComponent] for
## Skill/Luck, [WarlockHealthComponent] for Stamina (per §13.1, Stamina
## lives on HealthComponent, not the AbilityScore/modifier-stack system),
## [PlayerComponent] for the session-state fields nothing populates yet,
## and a [WarlockScriptComponent] running [PlayerScript] (currently a
## dummy ScriptEvent.INITIALIZED handler — see player_script.gd).
##
## Every component is attached to the [Entity] object directly
## (entity.set_component(), not this class's own add_component()) BEFORE
## the entity is registered. This ordering matters, not just style:
## add_entity_immediately() below is what makes the entity valid, and it
## does so by emitting entity_added and a script_event(INITIALIZED) in
## the same call — which is also when ScriptSystem's Switchboard
## subscription auto-attaches whatever ScriptComponent it finds on the
## entity (systems/script_system.gd _attach_scripts()). Register first
## and attach components after (the previous version of this method) and
## that lookup finds nothing yet: the ScriptComponent doesn't exist, the
## auto-attach silently no-ops, and ScriptEvent.INITIALIZED fires into
## nothing — no error, just a lost event, since nothing re-sends it
## later. Attaching components first means _notify_components_added()
## (called by add_entity_immediately(), same as this class's own
## add_component() would have done) still runs each component's
## on_added() normally — nothing about the component lifecycle contract
## is skipped, only the registration order changes.
func create_player_entity() -> String:
	var entity := Entity.new()
	entity.id = uuidv4()
	entity.tags.add(PlayerTags.Tag.PC)

	var abilities := WarlockAbilitiesComponent.new()
	abilities.add(WarlockAbilityType.ability_key(WarlockAbilityType.Type.SKILL), DiceTower_auto.roll_dx_plus_y(6, 6))
	abilities.add(WarlockAbilityType.ability_key(WarlockAbilityType.Type.LUCK), DiceTower_auto.roll_dx_plus_y(6, 6))
	entity.set_component(abilities)

	var rolled_stamina: int = DiceTower_auto.roll_x_dy(2, 6) + 12
	var health := WarlockHealthComponent.new()
	health.max_hp = rolled_stamina
	health.current_hp = rolled_stamina
	entity.set_component(health)

	entity.set_component(PlayerComponent.new())

	var script_component := WarlockScriptComponent.new()
	script_component.main_script = PlayerScript.new()
	entity.set_component(script_component)

	add_entity(entity)
	add_entity_immediately(entity.id)

	return entity.id
