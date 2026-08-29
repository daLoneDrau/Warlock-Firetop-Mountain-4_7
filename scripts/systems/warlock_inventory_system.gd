## Concrete [InventorySystem] for Warlock of Firetop Mountain, per §13.2.
##
## Not an autoload — this is a scene-scoped [GameSystem], instantiated and
## registered (`scene.register_system(...)`) by whichever [Scene] needs
## inventory access (CharacterCreationScene grants starting items;
## DungeonScene will need it too once room content exists). Uses the
## inherited `get_entity_manager()` (via `scene._game_engine.entity_manager`)
## rather than its own cached reference — unlike [WarlockScriptSystem],
## which is deliberately an autoload for reasons specific to that class.
##
## NOTE (flagged, not fixed here): base InventorySystem.add_item()'s
## `prefer_slot` branch (the first branch, before the "merge existing
## stacks" branch) writes to `InventorySlot.item_id` / `.count` — neither
## field exists on InventorySlot (only `entity_id`/`quantity` do). Another
## latent bug in the shared engine, dormant only because this override
## never passes an explicit `prefer_slot`, so that branch's guard
## (`prefer_slot >= 0`) is never entered.
class_name WarlockInventorySystem
extends InventorySystem


## Safety bound on the slot-growth retry loop in add_item() below — real
## usage this session never needs more than one extra slot per call.
const _MAX_GROWTH_ATTEMPTS: int = 64


func _on_ready() -> void:
	pass


func _on_initialize() -> void:
	pass


func _on_cleanup() -> void:
	pass


func _process_system(_delta: float) -> void:
	pass  # fully call/response driven — nothing to tick per frame


func handle_event(_event_name: String, _payload: Dictionary = {}) -> bool:
	return true  # no discrete events recognized yet


## Always true — unbounded inventory, per §13.2.
func has_space(_entity_id: StringName, _item_id: StringName, _count := 1, _at_slot := -1) -> bool:
	return true


## Overrides base add_item(): when no empty or stack-compatible slot
## exists, appends a new [InventorySlot] and retries, rather than
## returning `no_space`.
func add_item(entity_id: StringName, item_id: StringName, count: int = 1, prefer_slot: int = -1) -> Dictionary:
	var result := super.add_item(entity_id, item_id, count, prefer_slot)
	if result.get("reason", &"") != &"no_space":
		return result

	var inv := _get_inventory_component(entity_id)
	if inv == null:
		return result

	var attempts := 0
	while result.get("reason", &"") == &"no_space" and attempts < _MAX_GROWTH_ATTEMPTS:
		var new_slot := InventorySlot.new()
		new_slot.index = inv.slots.size()
		inv.slots.append(new_slot)
		result = super.add_item(entity_id, item_id, count, -1)
		attempts += 1

	if attempts >= _MAX_GROWTH_ATTEMPTS:
		push_error("WarlockInventorySystem.add_item: slot-growth safety bound hit for %s / %s" % [entity_id, item_id])

	return result


## Effectively unbounded — transfer_items() calls this for its own
## independent pre-check and would otherwise return `no_space_dest` before
## ever reaching add_item(), per §13.2.
func _compute_add_capacity(_inv, _item_id: StringName) -> int:
	return 999999999


func _get_item_component(item_id: StringName) -> ItemComponent:
	var em := get_entity_manager()
	if em == null:
		return null
	return em.get_component(item_id, ItemComponent) as ItemComponent


func _get_inventory_component(entity_id: StringName) -> InventoryComponent:
	var em := get_entity_manager()
	if em == null:
		return null
	return em.get_component(entity_id, WarlockInventoryComponent) as InventoryComponent
