## Attached (via [WarlockScriptComponent]) to the player's potion item
## entity. Fires automatically on [ScriptEvent.ITEM_USED] — [EntityScript]
## wires `on_item_used` to that event purely by method-name convention,
## no manual subscription needed.
##
## Not triggered by anything yet this session — no "Use" action exists in
## the UI (§7's Inventory tab is currently a plain list). This class is
## the plumbing only; real triggering is deferred until §7's overlay
## build happens.
##
## **ctx payload convention (this class's own, not dictated anywhere in
## the engine):** whoever eventually emits ScriptEvent.ITEM_USED for a
## potion must call it as
## `emit_script_event(ScriptEvent.ITEM_USED, potion_item_id, {"user_id": player_entity_id})`
## — `ctx["data"]["user_id"]` is how this script knows which entity's
## stats to affect, since `self.entity_id` (set by EntityScript.on_attach)
## is the ITEM's id, not the user's.
class_name PotionScript
extends EntityScript


func on_item_used(ctx: Dictionary) -> Dictionary:
	var data: Dictionary = ctx.get("data", {})
	var user_id: StringName = data.get("user_id", &"")
	if user_id == &"":
		push_warning("PotionScript.on_item_used: ctx.data has no user_id")
		return {}

	var potion: WarlockItemComponent = WarlockEntityManager_auto.get_component(entity_id, WarlockItemComponent) as WarlockItemComponent
	if potion == null:
		push_warning("PotionScript.on_item_used: no WarlockPotionItemComponent on %s" % entity_id)
		return {}

	if potion.charges_remaining <= 0:
		return {"consumed": false, "reason": &"empty"}

	match potion.potion_type:
		&"skill":
			_restore_ability(user_id, WarlockAbilityType.Type.SKILL)
		&"strength":
			_restore_stamina(user_id)
		&"fortune":
			_apply_fortune(user_id)
		_:
			push_warning("PotionScript.on_item_used: unrecognized potion_type '%s'" % potion.potion_type)
			return {}

	potion.charges_remaining -= 1
	# NOTE: not handling "remove the item entity once charges_remaining
	# hits 0" here — untested this session since nothing triggers use yet.
	# Worth revisiting once §7's overlay actually calls this.

	return {"consumed": true, "potion_type": potion.potion_type, "charges_remaining": potion.charges_remaining}


## Rules_reference.md "Potions": "Using a measure restores the associated
## stat's Current value to its Initial value" — per §13.1, that's
## clear_sources() on the relevant AbilityScore.
func _restore_ability(user_id: StringName, ability: int) -> void:
	var abilities: WarlockAbilitiesComponent = WarlockEntityManager_auto.get_component(user_id, WarlockAbilitiesComponent) as WarlockAbilitiesComponent
	if abilities == null:
		return
	var score := abilities.value(ability)
	if score != null:
		score.clear_sources()


## Strength potion restores Stamina — which lives on HealthComponent, not
## the AbilityScore/modifier-stack system (§13.1), so "Current to Initial"
## here is just current_hp = max_hp directly.
func _restore_stamina(user_id: StringName) -> void:
	var health: WarlockHealthComponent = WarlockEntityManager_auto.get_component(user_id, WarlockHealthComponent) as WarlockHealthComponent
	if health != null:
		health.current_hp = health.max_hp


## Rules_reference.md: "The Fortune potion additionally raises Initial
## Luck by 1 before restoring Current to the new Initial." Per §13.1: a
## base mutation (set_base), never a source, followed by clear_sources()
## to also restore Current to the new Initial.
func _apply_fortune(user_id: StringName) -> void:
	var abilities: WarlockAbilitiesComponent = WarlockEntityManager_auto.get_component(user_id, WarlockAbilitiesComponent) as WarlockAbilitiesComponent
	if abilities == null:
		return
	var luck := abilities.value(WarlockAbilityType.Type.LUCK)
	if luck != null:
		luck.set_base(luck.base + 1)
		luck.clear_sources()
