## TitleScene per §12.2. The diorama backdrop is rendered directly as the
## scene's own 3D world (`World/mountain_landscape`, wireframe-shaded by
## [DioramaWireframeShader]) instead of into a SubViewport/TextureRect —
## see docs/title_diorama_requirements.md for the diorama asset itself. The
## `UI` CanvasLayer holds a 2D overlay on top of that 3D world.
##
## The menu is a four-row list of plain Containers (no Button node, no
## unique names anywhere in the tree except `Hint/Cursor` — see
## TitleScene.tscn's `UI/Root/MenuPanel/Column/ItemPadding/Items`), each
## row shaped:
##   PanelContainer (MenuItemSelected/MenuItemNormal — no disabled
##                    variant; a disabled row's panel just stays
##                    MenuItemNormal, same as an unselected enabled row)
##     HBoxContainer "Row"
##       Label "Caret"  (CaretSelected/CaretNormal — no disabled variant
##                        either, for the same reason: it can never
##                        become selected)
##       Label "Name"   (MenuSelected/MenuNormal/MenuDisabled — the only
##                        one of the three with a real disabled look)
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
## `Hint/Cursor` (the ColorRect standing in for an old-terminal-style
## blinking caret next to the "↑↓ SELECT · RETURN CONFIRM" hint) blinks
## by toggling `modulate.a` between 0 and 1 on a loop — not `visible`,
## because Cursor sits in an HBoxContainer next to the hint text, and an
## invisible Control drops out of container layout entirely; toggling
## `visible` made the Hint row itself resize every half-second as the
## container reflowed around the cursor's absence/presence. Alpha keeps
## the Control "there" (still taking up its layout slot) while making it
## disappear visually. It's a hard cut (no tweened fade) so it still reads
## as a blocky terminal caret rather than a soft pulse.
##
## `Credits` now does something real: `UI/Root/CreditsPanel` (a
## [CreditsPanel] instance, res://scenes/title/credits_panel.tscn) sits in
## the exact same rect as `MenuPanel` and swaps with it — MenuPanel hides,
## CreditsPanel.reveal()'s stepped line-by-line paint-in runs, nothing
## else on the title screen moves. Coming back is the reverse: CreditsPanel
## emits `dismissed` (from its own BackButton), MenuPanel shows again.
## While `_credits_active` is true, do_action() ignores ui_up/ui_down/
## ui_confirm entirely — CreditsPanel's BackButton has its own Godot-focus
## Enter/click handling (grabbed via `_back.grab_focus()` at the end of
## reveal()), which runs during normal GUI input, ahead of this scene's
## custom key-routing. But nothing stops an Up/Down that the focus system
## doesn't consume from falling through to `_unhandled_key_input` and
## reaching this scene's do_action() anyway — without the guard, that
## would silently move the *hidden* main menu's selection underneath the
## credits panel.
##
## Escape is the other way out of the credits panel, alongside the Back
## button — checked first in do_action(), before the `_credits_active`
## guard, so it's the one action that still works while that guard is up.
## Escape while the main menu itself is showing is a no-op for now; there's
## nothing else on this screen for it to back out of. Dismissing via
## Escape calls `_credits_panel.hide_panel()` directly rather than routing
## through `_dismiss()`/the `dismissed` signal the Back button uses —
## `hide_panel()` is CreditsPanel's own public instant-hide entry point,
## so this stays a call to CreditsPanel's public API rather than reaching
## into its private `_dismiss()`. `_dismiss_credits()` here just mirrors
## `_on_credits_dismissed()`'s menu-restoring half locally, since no
## signal fires on this path.
##
## `Hint/Text` reads "ESC BACK" while the credits panel is up, and reverts
## to its authored text (captured once in _ready(), not hardcoded a second
## time here) once it's dismissed — same hint row, no layout change,
## since only the label's text changes, not the Hint container itself.
class_name TitleScene
extends Scene


enum MenuItem { NEW_GAME, CONTINUE, SETTINGS, CREDITS }

const ITEMS_PATH: NodePath = ^"UI/Root/MenuPanel/Column/ItemPadding/Items"

## How long the cursor stays visible/hidden per blink phase. 0.5s reads as
## a classic ~1Hz terminal-caret blink rather than something frantic.
const CURSOR_BLINK_PHASE_SEC: float = 0.5

## What `Hint/Text` shows while the credits panel is up. Its normal text
## ("↑↓ SELECT · RETURN CONFIRM") isn't duplicated as a constant here —
## it's read back from the node itself in _ready() and restored from that,
## so this script isn't a second source of truth for that string.
const CREDITS_HINT_TEXT := "ESC BACK"

## `Hint/Cursor` is the one node in TitleScene.tscn with
## unique_name_in_owner set.
@onready var _cursor: ColorRect = %Cursor

## Not unique-named (see header comment) — plain `$Path` lookup.
@onready var _hint_text: Label = $UI/Root/Hint/Text

## Captured once in _ready() from `_hint_text.text` itself, so swapping to
## CREDITS_HINT_TEXT and back doesn't require hardcoding the normal hint
## string a second time here.
var _default_hint_text: String = ""

## Sibling nodes under UI/Root that swap with each other — never both
## visible at once. No unique names on either (see header comment), so
## these are plain `$Path` lookups like everything else that isn't Cursor.
@onready var _menu_panel: PanelContainer = %MenuPanel
@onready var _credits_panel: CreditsPanel = %CreditsPanel

## True for as long as CreditsPanel is the visible one. Gates do_action()
## so a stray Up/Down that CreditsPanel's own focus/GUI-input handling
## doesn't consume can't reach the hidden main menu underneath — see
## header comment.
var _credits_active: bool = false

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

		var disabled: bool = i == MenuItem.SETTINGS or i == MenuItem.CONTINUE

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
	register_action("Escape", "ui_cancel")

	_default_hint_text = _hint_text.text

	if _rows[_selected]["disabled"]:
		_selected = _next_enabled_index(_selected, 1)

	# Every row needs its style set at init, not just the selected one —
	# otherwise Settings/Credits keep whatever theme_type_variation was
	# baked into the .tscn (MenuNormal on the Name label) instead of
	# actually switching to MenuDisabled, even though `disabled` is
	# correctly true in `_rows`. This was the bug: only the initially-
	# selected row was ever visited here before.
	for i in _rows.size():
		_apply_row_style(i, i == _selected)

	_credits_panel.dismissed.connect(_on_credits_dismissed)

	_start_cursor_blink()


## Routes ui_up/ui_down to move the highlighted row, ui_confirm to act on
## whichever row is currently selected, and ui_cancel (Escape) to back out
## of the credits panel if it's the thing currently showing. Only reacts
## on key-down (START) so releasing a key doesn't double-fire.
func do_action(action: GameAction) -> void:
	if not action.is_pressed():
		return

	if action.name == "ui_cancel":
		if _credits_active:
			_dismiss_credits()
		return  # No-op on the main menu — nothing else to back out of yet.

	if _credits_active:
		return  # CreditsPanel's own BackButton owns input right now.

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
## row isn't disabled — a disabled row is never drawn as selected. There's
## no MenuItemDisabled/CaretDisabled in the theme — only the Name label has
## a real disabled look (MenuDisabled); a disabled row's panel and caret
## just render the same as an unselected enabled row.
func _apply_row_style(index: int, is_selected: bool = true) -> void:
	var row: Dictionary = _rows[index]
	var disabled: bool = row["disabled"]
	var selected: bool = is_selected and not disabled

	(row["panel"] as PanelContainer).theme_type_variation = (
		&"MenuItemSelected" if selected else &"MenuItemNormal"
	)
	(row["caret"] as Label).theme_type_variation = (
		&"CaretSelected" if selected else &"CaretNormal"
	)
	(row["name_label"] as Label).theme_type_variation = (
		&"MenuDisabled" if disabled
		else (&"MenuSelected" if selected else &"MenuNormal")
	)


## Toggles `_cursor.modulate.a` between 0 and 1 on a loop — see the header
## comment for why alpha and not `visible`. The Tween is created on `self`
## (this Scene node), so it's owned by and stops with the scene the normal
## way; nothing to clean up in on_exit().
func _start_cursor_blink() -> void:
	var tween: Tween = create_tween()
	tween.set_loops()
	tween.tween_interval(CURSOR_BLINK_PHASE_SEC)
	tween.tween_callback(_set_cursor_alpha.bind(0.0))
	tween.tween_interval(CURSOR_BLINK_PHASE_SEC)
	tween.tween_callback(_set_cursor_alpha.bind(1.0))


func _set_cursor_alpha(alpha: float) -> void:
	_cursor.modulate.a = alpha


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
		MenuItem.CREDITS:
			_show_credits()
		_:
			# Continue: visible, enabled, and navigable, but still blocked
			# on save-existence detection (§12.2/§7), which doesn't exist
			# yet. (Settings can't reach this match at all — it's disabled,
			# caught by the guard above.) Logged rather than silent so the
			# gap stays visible.
			push_warning("TitleScene: '%s' selected but not implemented yet." % MenuItem.keys()[_selected])


## Swaps MenuPanel out for CreditsPanel in the same rect, and the hint text
## to match. reveal() runs its own stepped paint-in and ends by grabbing
## focus on its BackButton.
func _show_credits() -> void:
	_credits_active = true
	_menu_panel.hide()
	_hint_text.text = CREDITS_HINT_TEXT
	_credits_panel.reveal()


## CreditsPanel already hid itself (hide_panel()/_dismiss() both call
## hide() before emitting) — just swap MenuPanel and the hint text back,
## and hand keyboard input back to do_action(). Reached via the `dismissed`
## signal (Back button path).
func _on_credits_dismissed() -> void:
	_menu_panel.show()
	_hint_text.text = _default_hint_text
	_credits_active = false


## Escape path: CreditsPanel has no signal for this, so hide it directly
## via its public hide_panel() (not the private _dismiss() the Back button
## uses) and mirror _on_credits_dismissed()'s menu-restoring half locally.
func _dismiss_credits() -> void:
	_credits_panel.hide_panel()
	_on_credits_dismissed()
