## Item data for the player's chosen potion bottle. One item entity per
## run — the player selects exactly one potion type at chargen
## (Rules_reference.md "Potions") — not three separate item entities.
##
## Shares [ItemComponent]'s `IS_SLOT_ROOT = "ItemComponent"` slot
## (inherited, not redeclared) — this is the actual intended use of that
## mechanism: many concrete item subtypes, one item-component slot per
## item entity.
##
## Effect behavior lives in [PotionUseScript] (attached via
## [WarlockScriptComponent]), not here — this class is pure data, matching
## the rest of the ECS's component/script split.
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