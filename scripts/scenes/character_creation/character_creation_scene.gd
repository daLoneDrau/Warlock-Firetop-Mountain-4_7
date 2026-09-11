## CharacterCreationScene — "The Antechamber" (§12.3). The bootstrap-only
## placeholder that used to live here (fixing GameEngine._on_scene_changed()'s
## Scene-subclass poll — see git history if that context is ever needed
## again) is retired now that this scene has real content: TitleScene's
## "New Game" already targets this file directly.
##
## This pass (roadmap phase 1 of 4) rolls the player's Initial Skill,
## Stamina, and Luck the instant the scene is entered — no animation, no
## reroll (Rules_reference.md "Character creation"; UI/UX shell spec
## §12.3) — and creates the actual PC [Entity], since nothing in the
## codebase creates one anywhere else. Later phases still to come:
## potion selection (keyboard-driven — §12.1 excludes the hotspot/click
## layer from both Title and CharacterCreation) and the Descend
## transition. Nothing below wires either of those yet.
class_name CharacterCreationScene
extends Scene

const AMBER_DIM := Color(0.788, 0.541, 0.071)
const PIP_EMPTY_BORDER := Color(0.227, 0.227, 0.227)
const PIP_SIZE := 6

## Top of each stat's pip range — the ceiling of Rules_reference.md's
## starting ranges (Skill/Luck 1d6+6 -> 7-12, Stamina 2d6+12 -> 14-24),
## NOT the rolled value. _build_pips() below wants "how many pips could
## this stat ever have," separately from "how many are filled."
const SKILL_PIP_TOTAL := 12
const STAMINA_PIP_TOTAL := 24
const LUCK_PIP_TOTAL := 12

## Skill/Stamina/Luck (the VBoxContainer wrapping each stat's Row+Pips+
## Range) are the only nodes in CharacterCreationScene.tscn with
## unique_name_in_owner set — Value/Pips are reached from there by plain
## relative path, same convention TitleScene.gd uses for its own non-
## unique children.
@onready var _skill_value: Label = %Skill.get_node(^"Row/Value")
@onready var _skill_pips: HFlowContainer = %Skill.get_node(^"Pips")
@onready var _stamina_value: Label = %Stamina.get_node(^"Row/Value")
@onready var _stamina_pips: HFlowContainer = %Stamina.get_node(^"Pips")
@onready var _luck_value: Label = %Luck.get_node(^"Row/Value")
@onready var _luck_pips: HFlowContainer = %Luck.get_node(^"Pips")

## Set once on_enter() creates the PC entity. Not used yet this phase —
## kept so phase 2/3 (potion grant, Descend) have the id ready without
## re-deriving it or re-querying by tag.
var _player_entity_id: String = ""


## Nothing to route yet — potion-selection input (phase 2) is the first
## real action this scene will register.
func do_action(_action: GameAction) -> void:
	pass


## Rolls Initial Skill/Stamina/Luck, creates the PC entity carrying them,
## and paints the result into the stat panel. Runs once per scene entry —
## there's no reroll, so nothing here is meant to run twice in a row for
## the same playthrough.
func on_enter() -> void:
	_player_entity_id = WarlockEntityManager_auto.create_player_entity()

	var abilities: WarlockAbilitiesComponent = WarlockEntityManager_auto.get_component(_player_entity_id, WarlockAbilitiesComponent) as WarlockAbilitiesComponent
	var health: WarlockHealthComponent = WarlockEntityManager_auto.get_component(_player_entity_id, WarlockHealthComponent) as WarlockHealthComponent

	var skill: int = abilities.base_value(WarlockAbilityType.ability_key(WarlockAbilityType.Type.SKILL))
	var luck: int = abilities.base_value(WarlockAbilityType.ability_key(WarlockAbilityType.Type.LUCK))
	var stamina: int = int(health.max_hp)

	_skill_value.text = "%02d" % skill
	_build_pips(_skill_pips, skill, SKILL_PIP_TOTAL)

	_stamina_value.text = "%02d" % stamina
	_build_pips(_stamina_pips, stamina, STAMINA_PIP_TOTAL)

	_luck_value.text = "%02d" % luck
	_build_pips(_luck_pips, luck, LUCK_PIP_TOTAL)


## One pip per possible point in the stat, filled up to the rolled value:
## 10 of 12 skill is ten filled squares and two empty, not a range-relative bar.
## The container is an HFlowContainer, so a stat with a max too large for the
## panel width wraps to a second line instead of overflowing.
func _build_pips(box: HFlowContainer, filled: int, total: int) -> void:
	for child in box.get_children():
		child.queue_free()
	for i in total:
		var pip: Control
		if i < filled:
			pip = ColorRect.new()
			pip.color = AMBER_DIM
		else:
			pip = Panel.new()
			var sb := StyleBoxFlat.new()
			sb.draw_center = false
			sb.set_border_width_all(1)
			sb.border_color = PIP_EMPTY_BORDER
			sb.corner_detail = 1
			pip.add_theme_stylebox_override("panel", sb)
		pip.custom_minimum_size = Vector2(PIP_SIZE, PIP_SIZE)
		box.add_child(pip)
