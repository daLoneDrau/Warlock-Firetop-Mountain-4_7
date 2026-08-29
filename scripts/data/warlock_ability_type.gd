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
