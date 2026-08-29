## Concrete [AbilityScore] for Warlock of Firetop Mountain, per §13.1.
##
## Enforces "Current may not exceed Initial except for exempt sources":
## non-exempt sources (Luck-test costs, future wound-like effects) can
## lower `full` below `base` freely but never push it above `base`.
## Exempt sources (equipment-style modifiers) are added on top uncapped.
class_name WarlockAbilityScore
extends AbilityScore


## Per-source exemption flag, keyed the same as base [_sources]. Base
## `_sources` is `Dictionary[StringName, int]` with no room for a flag,
## hence this companion dict rather than changing the base shape.
var _exempt_sources: Dictionary[StringName, bool] = {}


## Overrides the base two-arg signature to record exemption per-source.
## Existing two-arg callers are unaffected (default `exempt_from_cap: false`
## — GDScript default-parameter override is valid here).
func add_source(src: StringName, amount: int, exempt_from_cap: bool = false) -> void:
	_exempt_sources[src] = exempt_from_cap
	super.add_source(src, amount)  # sets _sources[src], then calls
# _recalc_modifier() — virtual dispatch means that resolves to our
# override below, not the base implementation.


## Cap algorithm per §13.1: split sources into exempt/non-exempt, sum each
## separately, clamp only the non-exempt sum to <= 0, add the exempt sum
## on top uncapped.
func _recalc_modifier() -> void:
	var non_exempt_sum: int = 0
	var exempt_sum: int = 0
	for src in _sources.keys():
		var amount: int = _sources[src]
		if _exempt_sources.get(src, false):
			exempt_sum += amount
		else:
			non_exempt_sum += amount

	var clamped_non_exempt: int = min(non_exempt_sum, 0)
	_modifier = clamped_non_exempt + exempt_sum
	_emit_change()
