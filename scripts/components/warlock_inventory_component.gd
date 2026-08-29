## Concrete [InventoryComponent] for Warlock of Firetop Mountain, per §13.2.
##
## `capacity = -1` is informational only, reusing the "unlimited" sentinel
## convention already established by [ItemComponent.max_count] — confirmed
## against source that nothing in [InventorySystem] actually reads
## `capacity`; only `slots.size()` matters functionally. The real unbounded
## behavior lives in [WarlockInventorySystem]'s overrides, not here.
class_name WarlockInventoryComponent
extends InventoryComponent


const IS_SLOT_ROOT: bool = true


func _init() -> void:
	super._init()
	capacity = -1
