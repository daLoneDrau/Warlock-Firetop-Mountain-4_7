## Concrete [AbilitiesComponent] for Warlock of Firetop Mountain, per §13.1.
## Overrides add() to instantiate [WarlockAbilityScore] instead of the base
## [AbilityScore], so the whole ability set gets the clamped subclass.
##
## Scope per §13.1: both Skill and Luck get populated via add() this
## session, despite no MVP content testing Skill yet — for consistency,
## and because add() operates per-ability (not a structural requirement).
## Stamina is NOT here — it stays on HealthComponent entirely.
class_name WarlockAbilitiesComponent
extends AbilitiesComponent


const IS_SLOT_ROOT: bool = true


func add(ability: StringName, initial_score: int = 0) -> void:
	var score := WarlockAbilityScore.new(self)
	score.base = initial_score
	ability_set[ability] = score
	emit_update_signal()
