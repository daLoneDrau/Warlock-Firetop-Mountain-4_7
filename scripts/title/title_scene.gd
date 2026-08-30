## TitleScene per §12.2. This pass: diorama backdrop (Godot-primitive
## placeholder standing in for the real Blender asset — see
## docs/title_diorama_requirements.md for the swap-in spec) + `New Game`.
##
## Deliberately NOT built yet, per this session's scoping: `Continue` and
## save-existence detection (§12.2/§7 — no save system exists), credits/
## version text. `New Game` is "always shown, always enabled, never gated
## by save state" (§12.2) — since no save system exists yet, there's also
## no in-progress-save-discard-confirm dialog to wire up; that's the same
## save-system dependency as Continue, not a separate gap.
class_name TitleScene
extends Scene


@onready var _diorama_viewport: SubViewport = %DioramaViewport
@onready var _diorama_display: TextureRect = %DioramaDisplay
@onready var _new_game_button: Button = %NewGameButton


func _ready() -> void:
	_diorama_display.texture = _diorama_viewport.get_texture()
	_new_game_button.pressed.connect(_on_new_game_pressed)


func do_action(_action: GameAction) -> void:
	pass  # no registered actions on this screen — button press handles the
# one available action directly.


func on_enter() -> void:
	pass


## NOTE: CharacterCreationScene doesn't exist yet (next step after this
## one) — until it does, this will push_error via change_scene()'s own
## "not registered and no path provided"-adjacent failure path (the path
## IS provided, but the file doesn't exist yet, so
## get_tree().change_scene_to_file() itself will fail) rather than
## silently doing nothing. Left wired now rather than stubbed out, so
## there's nothing left to come back and connect later.
func _on_new_game_pressed() -> void:
	_game_engine.change_scene("CharacterCreation", "res://scenes/CharacterCreation.tscn")
