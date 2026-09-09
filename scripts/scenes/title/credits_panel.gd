class_name CreditsPanel
extends PanelContainer
## Credits panel (mockup 3b). Occupies the same slot as the main menu panel:
## the menu hides, this shows, nothing else on the title screen moves.
##
## Entrance is a stepped line-by-line reveal — no fade, no slide, no easing.
## Rows appear one per ROW_STEP tick, the way a period terminal painted a page.

signal dismissed

## Seconds between row reveals. 0.03 ≈ two frames at 60fps; 6 rows ≈ 180ms total.
const ROW_STEP := 0.03

@onready var _rows: VBoxContainer = $Column/Rows
@onready var _back: Button = $Column/HeaderBar/Header/BackButton

var _revealing := false

func _ready() -> void:
	_back.pressed.connect(_dismiss)
	hide()


## Call this instead of show(). Frame and header appear at once; rows paint in.
func reveal() -> void:
	_revealing = true
	for row in _rows.get_children():
		(row as Control).visible = false
	show()
	for row in _rows.get_children():
		await get_tree().create_timer(ROW_STEP).timeout
		if not visible:
			_revealing = false
			return
		(row as Control).visible = true
	_revealing = false
	_back.grab_focus()

## Instant on the way out — dismissal should never make the player wait.
func hide_panel() -> void:
	hide()

func _dismiss() -> void:
	hide()
	dismissed.emit()
