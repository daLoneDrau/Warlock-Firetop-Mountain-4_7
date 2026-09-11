## Identifies which ability an [AbilityScore] represents, for use as the
## int key into [AbilitiesComponent.ability_set]. New this session — §13
## resolved the stats *architecture* (modifier stack, cap algorithm) but
## never named the int constants identifying Skill vs. Luck, since
## `AbilitiesComponent.ability_set` is keyed by plain int with no existing
## enum anywhere in the ECS repo for it.
##
## Stamina is NOT here — per §13.1 it stays on HealthComponent entirely,
## outside the AbilityScore/modifier-stack system.
class_name WarlockAbilityType

enum Type {
	SKILL = 0,
	LUCK = 1,
}


## Centralizes the find_key()-to-StringName conversion potion_script.gd
## already does inline elsewhere, so ability_set's StringName keys are
## derived the same way at every call site instead of being retyped.
static func ability_key(ability: int) -> StringName:
	return StringName(Type.find_key(ability))
