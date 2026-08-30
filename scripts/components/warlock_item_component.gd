## Concrete [ItemComponent] for Warlock of Firetop Mountain.
class_name WarlockItemComponent
extends ItemComponent


## Which stat this bottle restores. Values are the same three named in
## Rules_reference.md "Potions": &"skill", &"strength" (restores Stamina),
## &"fortune" (restores Luck, plus permanently raises Initial Luck by 1).
var potion_type: StringName = &""

## Measures remaining. Rules_reference.md: "Each bottle provides 2
## measures across the run" — starts at 2, decremented per use. Kept as
## its own field rather than reusing [ItemComponent.quantity] or
## [InventorySlot.quantity], both of which mean "how many item stacks/
## units," a different concept from "uses remaining on this one bottle."
var charges_remaining: int = 2