## TitleScene per §12.2. The diorama backdrop is now rendered directly as
## the scene's own 3D world (`World/mountain_landscape`, wireframe-shaded by
## [DioramaWireframeShader]) instead of into a SubViewport/TextureRect —
## see docs/title_diorama_requirements.md for the diorama asset itself. The
## `UI` CanvasLayer holds a 2D overlay on top of that 3D world.
##
## The menu is now a single four-row keyboard-navigable list (`New Game` /
## `Continue` / `Settings` / `Credits`, per TitleScene.tscn's
## `UI/Root/MenuPanel/Column/ItemPadding/Items`) rather than one `Button`
## node — there are no Button/pressed-signal nodes left in the scene at
## all, and no node in the tree sets `unique_name_in_owner` anymore, so
## `%NewGameButton`-style unique-name lookups no longer resolve to
## anything. Navigation is wired through [Scene]'s existing
## register_action()/do_action() key-routing instead of Control's own
## focus system, since the row highlight is driven entirely by swapping
## `theme_type_variation` on the row/caret/name labels (MenuItem* /
## Caret* / Menu* pairs), not by Godot's built-in focus-outline styling.
##
## Still deliberately NOT wired to real behavior this pass, per this
## session's scoping: `Continue`, `Settings`, and `Credits` are now
## visually complete (including Continue's placeholder "DEPTH 3" meta
## label), but selecting them stays a no-op — same missing-systems gap as
## before (save-existence detection per §12.2/§7, and Settings/Credits
## screens that don't exist yet), just extended to rows that are now
## visible instead of simply absent. `New Game` is still "always shown,
## always enabled, never gated by save state" (§12.2) and is the only row
## wired to a real action.
class_name TitleScene
extends Scene


enum MenuItem { NEW_GAME, CONTINUE, SETTINGS, CREDITS }

const ITEMS_PATH: NodePath = ^"UI/Root/MenuPanel/Column/ItemPadding/Items"

## Row -> {panel, caret, name} node refs, indexed by MenuItem.
var _rows: Array[Dictionary] = []

## Untyped as `int` rather than `MenuItem` so wrapi()'s plain-int result can
## be assigned back without a static-typing cast; the values still line up
## 1:1 with MenuItem's enum constants.
var _selected: int = MenuItem.NEW_GAME


func _ready() -> void:
	var items: Node = get_node(ITEMS_PATH)
	for child in items.get_children():
		var row: HBoxContainer = child.get_node(^"Row") as HBoxContainer
		_rows.append({
			"panel": child as PanelContainer,
			"caret": row.get_node(^"Caret") as Label,
			"name": row.get_node(^"Name") as Label,
		})

	register_action("Up", "ui_up")
	register_action("Down", "ui_down")
	register_action("Enter", "ui_confirm")

	_set_row_highlighted(_selected, true)


## Routes ui_up/ui_down to move the highlighted row, ui_confirm to act on
## whichever row is currently selected. Only reacts on key-down (START) so
## releasing Up/Down/Enter doesn't double-fire.
func do_action(action: GameAction) -> void:
	if not action.is_pressed():
		return

	match action.name:
		"ui_up":
			_move_selection(-1)
		"ui_down":
			_move_selection(1)
		"ui_confirm":
			_confirm_selection()


func on_enter() -> void:
	pass


func _move_selection(delta: int) -> void:
	_set_row_highlighted(_selected, false)
	_selected = wrapi(_selected + delta, 0, _rows.size())
	_set_row_highlighted(_selected, true)


## Swaps the panel/caret/name theme_type_variations between the *Selected
## and *Normal pairs baked into the scene's theme resource — mirrors
## Item0's default-selected state (MenuItemSelected/CaretSelected/
## MenuSelected) vs. Item1-3's default-normal state
## (MenuItemNormal/CaretNormal/MenuNormal).
func _set_row_highlighted(item: int, is_selected: bool) -> void:
	var row: Dictionary = _rows[item]
	(row["panel"] as PanelContainer).theme_type_variation = (
		&"MenuItemSelected" if is_selected else &"MenuItemNormal"
	)
	(row["caret"] as Label).theme_type_variation = (
		&"CaretSelected" if is_selected else &"CaretNormal"
	)
	(row["name"] as Label).theme_type_variation = (
		&"MenuSelected" if is_selected else &"MenuNormal"
	)


## NOTE: CharacterCreationScene doesn't exist yet (next step after this
## one) — until it does, this will push_error via change_scene()'s own
## "not registered and no path provided"-adjacent failure path (the path
## IS provided, but the file doesn't exist yet, so
## get_tree().change_scene_to_file() itself will fail) rather than
## silently doing nothing. Left wired now rather than stubbed out, so
## there's nothing left to come back and connect later.
func _confirm_selection() -> void:
	match _selected:
		MenuItem.NEW_GAME:
			_game_engine.change_scene("CharacterCreation", "res://scenes/CharacterCreation.tscn")
		_:
			# Continue/Settings/Credits: visible and navigable, but each is
			# still blocked on a system that doesn't exist yet (save
			# detection, Settings screen, Credits screen respectively).
			# Logged rather than silent so the gap stays visible.
			push_warning("TitleScene: '%s' selected but not implemented yet." % MenuItem.keys()[_selected])
