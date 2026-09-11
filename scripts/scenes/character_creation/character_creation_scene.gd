## CharacterCreationScene — "The Antechamber" (§12.3). The bootstrap-only
## placeholder that used to live here (fixing GameEngine._on_scene_changed()'s
## Scene-subclass poll — see git history if that context is ever needed
## again) is retired now that this scene has real content: TitleScene's
## "New Game" already targets this file directly.
##
## Roadmap phase 1 (done): rolls the player's Initial Skill, Stamina, and
## Luck the instant the scene is entered — no animation, no reroll
## (Rules_reference.md "Character creation"; UI/UX shell spec §12.3) —
## and creates the actual PC [Entity] via WarlockEntityManager.
##
## Roadmap phase 2 (this pass): potion selection. §12.1 excludes the
## dungeon's hotspot/click-resolution layer (§5.1-§5.4) from this screen
## entirely — "neither screen has a hotspot... nothing to click" — so
## this is keyboard-driven (Left/Right), not raycast-driven. The diorama
## asset carries three [Node3D] markers (skill_marker/stamina_marker/
## luck_marker) at each flask's position; this script projects them
## through the diorama's Camera3D into the 2D WorldOverlay to place the
## three SlotLabels (the only potion labels this scene shows — full
## potion names, dim by default, switching to cyan on selection) and move
## SelectionBracket's self-drawn corner marks as the selection changes.
##
## Still open: Descend (phase 3) — granting the chosen potion to the
## player entity and transitioning onward.
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

## One entry per plinth, in the same left-to-right order already baked
## into the scene's SlotLabel0/1/2. marker_name matches the Node3D the
## diorama artist placed at each flask's position (found by name under
## potion_diorama, wherever the .glb's import nested it — see
## _find_potion_markers()). potion_type is the value
## WarlockItemComponent/PotionScript expect (Rules_reference.md
## "Potions": skill/strength/fortune). full_name is the SlotLabel text.
## label/effect feed the Flavor line — label names the flask by the stat
## it restores (matching the marker names), effect is this project's
## adapted potion power (a flat +1, not "restore to Initial" per the
## source book): Skill/Strength restore 1 point of their stat; Fortune
## restores Luck *and* raises Initial Luck by 1.
const POTION_SLOTS: Array[Dictionary] = [
	{"marker_name": "skill_marker", "potion_type": &"skill", "label": "Skill", "effect": "restores 1 point of Skill", "full_name": "POTION OF SKILL"},
	{"marker_name": "stamina_marker", "potion_type": &"strength", "label": "Stamina", "effect": "restores 1 point of Stamina", "full_name": "POTION OF STRENGTH"},
	{"marker_name": "luck_marker", "potion_type": &"fortune", "label": "Luck", "effect": "restores your Luck and adds 1 to your Initial Luck", "full_name": "POTION OF FORTUNE"},
	]

## Marker's projected point -> SlotLabel top-left, after centering on the
## label's size. Negative y places the label above the bracket (bracket
## is centered on the marker, half-height 70px, so -90 clears its top
## edge with a small gap) — the corner marks stay on the flask itself,
## the name reads above them. TUNING PLACEHOLDER: picked to be
## "plausible," not verified against the actual rendered diorama —
## revisit once the markers/camera framing are visible in-editor.
const SLOT_LABEL_OFFSET := Vector2(0.0, -90.0)

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

@onready var _camera: Camera3D = $Layout/Middle/ViewArea/SubViewportContainer/SubViewport/World/Camera3D
@onready var _sub_viewport: SubViewport = $Layout/Middle/ViewArea/SubViewportContainer/SubViewport
@onready var _potion_diorama: Node3D = $Layout/Middle/ViewArea/SubViewportContainer/SubViewport/World/potion_diorama
@onready var _world_overlay: Control = %WorldOverlay
@onready var _selection_bracket: Control = %SelectionBracket
@onready var _slot_labels: Array[Label] = [%SlotLabel0, %SlotLabel1, %SlotLabel2]
@onready var _flavor: Label = %Flavor

## One entry per POTION_SLOTS index, resolved once in _ready(). A null
## entry means that marker wasn't found under potion_diorama (logged,
## not fatal) — _reposition_potion_ui()/_update_selection_visuals() skip
## that slot rather than crashing on a missing Node3D.
var _potion_markers: Array[Node3D] = []

## Defaults to the centre plinth (index 1, Strength), matching this
## scene's original placeholder flavor text ("the wide flask from the
## centre plinth") — not a rule, just where selection starts.
var _selected_potion_index: int = 1

## Set once on_enter() creates the PC entity. Not used yet this phase —
## kept so phase 3 (potion grant, Descend) has the id ready without
## re-deriving it or re-querying by tag.
var _player_entity_id: String = ""


func _ready() -> void:
	register_action("Left", "select_prev_potion")
	register_action("Right", "select_next_potion")
	_find_potion_markers()
	_world_overlay.resized.connect(_reposition_potion_ui)


## Left/Right move the potion selection. Only reacts on key-down (START),
## same convention as TitleScene, so releasing a key doesn't double-fire.
func do_action(action: GameAction) -> void:
	if not action.is_pressed():
		return
	match action.name:
		"select_prev_potion":
			_move_selection(-1)
		"select_next_potion":
			_move_selection(1)


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

	# Deferred, not called inline: WorldOverlay/ViewArea's actual size
	# (used to scale SubViewport-space projections into overlay-space,
	# see _project_marker()) comes from container layout, which hasn't
	# necessarily settled yet on the same frame the scene is entered.
	_reposition_potion_ui.call_deferred()


## Finds each POTION_SLOTS marker under potion_diorama by name,
## regardless of how deeply the .glb import nested it — recursive,
## unowned search, since imported sub-scene children aren't necessarily
## owned by this scene's root the way find_child()'s default expects.
func _find_potion_markers() -> void:
	_potion_markers.clear()
	for slot in POTION_SLOTS:
		var marker_name: String = slot["marker_name"]
		var marker: Node3D = _potion_diorama.find_child(marker_name, true, false) as Node3D
		if marker == null:
			push_warning("CharacterCreationScene: potion marker '%s' not found under potion_diorama." % marker_name)
		_potion_markers.append(marker)


## Places the three always-visible SlotLabel captions under their
## markers (setting their full-name text in the same pass) then repaints
## whichever one is currently selected. Also the resize handler
## (WorldOverlay.resized) so the layout stays correct if the window/
## viewport is resized mid-screen.
func _reposition_potion_ui() -> void:
	for i in POTION_SLOTS.size():
		var slot: Dictionary = POTION_SLOTS[i]
		var label: Label = _slot_labels[i]
		label.text = slot["full_name"]

		var marker: Node3D = _potion_markers[i]
		if marker == null:
			continue
		var point: Vector2 = _project_marker(marker)
		label.position = point + SLOT_LABEL_OFFSET - label.size / 2.0

	_update_selection_visuals()


func _move_selection(delta: int) -> void:
	_selected_potion_index = wrapi(_selected_potion_index + delta, 0, POTION_SLOTS.size())
	_update_selection_visuals()


## Colors every SlotLabel each call (not just the one that changed) —
## simplest way to guarantee the previously-selected label always reverts
## when selection moves, with no separate "was this the last selected
## index" bookkeeping to get out of sync. Disabled is just "no override":
## HintLabel's own font_color already is the dim/disabled look these
## labels start with, so reverting to it is one call instead of
## duplicating that color here. Then moves SelectionBracket (self-drawing
## its own corner marks — see selection_bracket.gd) onto the selected
## marker's projected point, or hides it if that marker wasn't found.
func _update_selection_visuals() -> void:
	for i in POTION_SLOTS.size():
		var label: Label = _slot_labels[i]
		if i == _selected_potion_index:
			label.add_theme_color_override("font_color", StyleGuideColors.HOTSPOT_FILL)
		else:
			label.remove_theme_color_override("font_color")

	var marker: Node3D = _potion_markers[_selected_potion_index]
	if marker == null:
		_selection_bracket.visible = false
		return

	var point: Vector2 = _project_marker(marker)
	_selection_bracket.visible = true
	_selection_bracket.position = point - _selection_bracket.size / 2.0

	var slot: Dictionary = POTION_SLOTS[_selected_potion_index]
	_flavor.text = "You take the flask from the plinth. It %s." % slot["effect"]


## Projects a diorama-space point through the SubViewport's Camera3D
## into WorldOverlay's local 2D space. Mirrors the remap UI/UX shell
## spec §5.3 describes for click resolution (TextureRect/SubViewport size
## mismatch), just inverted: 3D point -> SubViewport pixel space ->
## scaled into WorldOverlay's actual on-screen size, since
## SubViewportContainer has stretch = true and its authored SubViewport
## resolution (722x488) won't generally match WorldOverlay's real size.
func _project_marker(marker: Node3D) -> Vector2:
	var viewport_point: Vector2 = _camera.unproject_position(marker.global_position)
	var scale: Vector2 = _world_overlay.size / Vector2(_sub_viewport.size)
	return viewport_point * scale


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
