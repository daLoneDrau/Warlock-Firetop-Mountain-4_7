## Concrete [ItemComponent] for Warlock of Firetop Mountain.
class_name WarlockItemComponent
extends ItemComponent


## Which stat this bottle restores. Values are the same three named in
## Rules_reference.md "Potions": &"skill", &"strength" (restores Stamina),
## &"fortune" (restores Luck, plus permanently raises Initial Luck by 1).
var potion_type: StringName = &""