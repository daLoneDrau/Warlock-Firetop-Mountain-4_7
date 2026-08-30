## Attached (via [WarlockScriptComponent]) to the player's provisions item
## entity. Same on_item_used mechanism and ctx["data"]["user_id"]
## convention as [PotionScript] — see that file's header for the full
## explanation. Also not triggered by anything yet this session.
class_name ProvisionScript
extends EntityScript


func on_item_used(ctx: Dictionary) -> Dictionary:
	var data: Dictionary = ctx.get("data", {})
	var user_id: StringName = data.get("user_id", &"")
	if user_id == &"":
		push_warning("ProvisionScript.on_item_used: ctx.data has no user_id")
		return {}

	var provisions: WarlockItemComponent = WarlockEntityManager_auto.get_component(entity_id, WarlockItemComponent) as WarlockItemComponent
	if provisions == null:
		push_warning("ProvisionScript.on_item_used: no WarlockItemComponent on %s" % entity_id)
		return {}

	if provisions.quantity <= 0:
		return {"consumed": false, "reason": &"empty"}

	# Rules_reference.md "Provisions": "Consuming one restores a fixed
	# Stamina amount (adapted value: +4)" — clamped to max, same as
	# PotionScript's Strength-potion handling.
	var health: WarlockHealthComponent = WarlockEntityManager_auto.get_component(user_id, WarlockHealthComponent) as WarlockHealthComponent
	if health != null:
		health.current_hp = min(health.current_hp + 4.0, health.max_hp)

	provisions.quantity -= 1

	return {"consumed": true, "quantity": provisions.quantity}
