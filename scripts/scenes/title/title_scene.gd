## TitleScene per §12.2. The diorama backdrop is rendered directly as the
## scene's own 3D world (`World/mountain_landscape`, wireframe-shaded by
## [DioramaWireframeShader]) instead of into a SubViewport/TextureRect —
## see docs/title_diorama_requirements.md for the diorama asset itself. The
## `UI` CanvasLayer holds a 2D overlay on top of that 3D world.
##
## The menu is a four-row list of plain Containers (no Button node, no
## unique names anywhere in the tree — see TitleScene.tscn's
## `UI/Root/MenuPanel/Column/ItemPadding/Items`), each row shaped:
##   PanelContainer (MenuItemSelected/MenuItemNormal/MenuItemDisabled)
##     HBoxContainer "Row"
##       Label "Caret"  (CaretSelected/CaretNormal — no disabled variant;
##                        a disabled row's caret just stays CaretNormal,
##                        since it can never become selected)
##       Label "Name"   (MenuSelected/MenuNormal/MenuDisabled)
##       Label "Meta"   (MetaLabel; visible = false when unused)
## All state — highlight AND disabled/enabled — is driven entirely by
## swapping `theme_type_variation` on those three labels/panel from here;
## there's nothing for Godot's built-in Control focus/disabled styling to
## do, since these are Containers, not Buttons.
##
## Keyboard nav (Up/Down/Enter, routed through [Scene]'s
## register_action()/do_action(), per the established key-routing
## convention — see GameEngine._route_input_to_scene()) skips disabled
## rows entirely, wrapping past them rather than landing on them.
##
## Mouse support is new this pass: hovering a row moves the keyboard
## selection to it, and every non-disabled row gets
## `mouse_default_cursor_shape = CURSOR_POINTING_HAND` so the pointer
## itself signals "this is clickable" — disabled rows keep the default
## arrow and don't respond to hover or click at all. `Row`'s mouse_filter
## is forced to IGNORE here (rather than trusted to the scene file) so
## clicks on the label text still bubble up to the row's own
## PanelContainer instead of being swallowed by the HBoxContainer.
##
## `Settings` and `Credits` are marked disabled here because those screens
## don't exist yet — this replaces the previous pass's approach of
## leaving them selectable and logging a no-op warning on confirm, now
## that a real disabled state exists to express the gap instead. `Continue`
## stays enabled (unchanged from before) since no save-existence check
## exists yet to gate it on; this is a judgment call worth revisiting once
## save detection (§12.2/§7) is real. `New Game` is still "always shown,
## always enabled, never gated by save state" (§12.2).
##
## NOTE for theme authoring: `theme/ui_theme.tres` defines `MenuDisabled`
## (Label) but has no `MenuItemDisabled` (PanelContainer) entry yet, so a
## disabled row's panel currently falls back to whatever
## `theme_type_variation = &"MenuItemDisabled"` resolves to when the
## variation is missing (Godot's default PanelContainer style) rather than
## a genuinely dimmed panel — only the Name label actually dims. Flagging
## rather than inventing a style here, since the visual treatment (border/
## fill color for a disabled panel) isn't specified.
class_name TitleScene
extends Scene


enum MenuItem { NEW_GAME, CONTINUE, SETTINGS, CREDITS }

const ITEMS_PATH: NodePath = ^"UI/Root/MenuPanel/Column/ItemPadding/Items"

## Row -> {panel, caret, name_label, disabled} node refs, indexed by
## MenuItem. Built once in _ready() from whatever children ITEMS_PATH
## actually has, rather than hard node-path per row, so row count/order
## still comes from the scene rather than being duplicated here.
var _rows: Array[Dictionary] = []

## Untyped as `int` rather than `MenuItem` so wrapi()'s plain-int result can
## be assigned back without a static-typing cast; the values still line up
## 1:1 with MenuItem's enum constants.
var _selected: int = MenuItem.NEW_GAME


func _ready() -> void:
	var items: Node = get_node(ITEMS_PATH)
	var children: Array = items.get_children()
	for i in children.size():
		var panel: PanelContainer = children[i] as PanelContainer
		var row: HBoxContainer = panel.get_node(^"Row") as HBoxContainer
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE  # let clicks bubble to `panel`

		var disabled: bool = i == MenuItem.SETTINGS or i == MenuItem.CREDITS

		_rows.append({
			"panel": panel,
			"caret": row.get_node(^"Caret") as Label,
			"name_label": row.get_node(^"Name") as Label,
			"disabled": disabled,
		})

		panel.mouse_default_cursor_shape = (
			Control.CURSOR_ARROW if disabled else Control.CURSOR_POINTING_HAND
		)
		if not disabled:
			panel.mouse_entered.connect(_on_row_mouse_entered.bind(i))
			panel.gui_input.connect(_on_row_gui_input.bind(i))

	register_action("Up", "ui_up")
	register_action("Down", "ui_down")
	register_action("Enter", "ui_confirm")

	if _rows[_selected]["disabled"]:
		_selected = _next_enabled_index(_selected, 1)
	_apply_row_style(_selected)


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


func _on_row_mouse_entered(index: int) -> void:
	_move_selection_to(index)


func _on_row_gui_input(event: InputEvent, index: int) -> void:
	if not (event is InputEventMouseButton):
		return
	var mouse_event: InputEventMouseButton = event as InputEventMouseButton
	if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
		_move_selection_to(index)
		_confirm_selection()


func _move_selection(delta: int) -> void:
	_move_selection_to(_next_enabled_index(_selected, delta))


func _move_selection_to(index: int) -> void:
	if index == _selected or _rows[index]["disabled"]:
		return
	_apply_row_style(_selected, false)
	_selected = index
	_apply_row_style(_selected, true)


## Steps `delta` at a time from `from`, wrapping around, until it lands on
## a non-disabled row. Guards against an all-disabled menu (would otherwise
## spin forever) by giving up and returning `from` after one full lap.
func _next_enabled_index(from: int, delta: int) -> int:
	var index: int = from
	for _i in _rows.size():
		index = wrapi(index + delta, 0, _rows.size())
		if not _rows[index]["disabled"]:
			return index
	return from


## Swaps the panel/caret/name theme_type_variations for `index` between its
## disabled / selected / normal states. `is_selected` only matters when the
## row isn't disabled — a disabled row is never drawn as selected.
func _apply_row_style(index: int, is_selected: bool = true) -> void:
	var row: Dictionary = _rows[index]
	var disabled: bool = row["disabled"]
	var selected: bool = is_selected and not disabled

	(row["panel"] as PanelContainer).theme_type_variation = (
		&"MenuItemDisabled" if disabled
		else (&"MenuItemSelected" if selected else &"MenuItemNormal")
	)
	(row["caret"] as Label).theme_type_variation = (
		&"CaretSelected" if selected else &"CaretNormal"
	)
	(row["name_label"] as Label).theme_type_variation = (
		&"MenuDisabled" if disabled
		else (&"MenuSelected" if selected else &"MenuNormal")
	)


## NOTE: CharacterCreationScene doesn't exist yet (next step after this
## one) — until it does, this will push_error via change_scene()'s own
## "not registered and no path provided"-adjacent failure path (the path
## IS provided, but the file doesn't exist yet, so
## get_tree().change_scene_to_file() itself will fail) rather than
## silently doing nothing. Left wired now rather than stubbed out, so
## there's nothing left to come back and connect later.
func _confirm_selection() -> void:
	if _rows[_selected]["disabled"]:
		return  # nav/mouse guards already prevent this; belt-and-braces.

	match _selected:
		MenuItem.NEW_GAME:
			_game_engine.change_scene("CharacterCreation", "res://scenes/CharacterCreation.tscn")
		_:
			# Continue: visible, enabled, and navigable, but still blocked
			# on save-existence detection (§12.2/§7), which doesn't exist
			# yet. Logged rather than silent so the gap stays visible.
			push_warning("TitleScene: '%s' selected but not implemented yet." % MenuItem.keys()[_selected])
