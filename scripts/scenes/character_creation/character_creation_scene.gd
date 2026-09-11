## Bootstrap-only placeholder [Scene] for the character creation screen —
## same role BootTestScene played before TitleScene existed. Its only job
## right now is to exist AS a [Scene] subclass, not to do anything yet.
##
## This isn't cosmetic: GameEngine._on_scene_changed() polls
## `get_tree().current_scene is Scene` after every change_scene() call and
## only assigns `primary_scene` once that's true. CharacterCreation.tscn's
## root was a bare Node2D with no script at all — never a Scene — so that
## poll could never succeed. It retried for 5 real seconds
## (_ON_SCENE_CHANGED_MAX_ATTEMPTS × _ON_SCENE_CHANGED_RETRY_DELAY_SEC),
## then gave up and returned *without* updating `primary_scene`, leaving
## it pointing at the just-freed TitleScene instance indefinitely. Any key
## press after that routed straight into a freed Object and crashed
## ("previously freed" error) — this is what fixes that, by giving
## _on_scene_changed() something it can actually resolve to. See the
## companion fix in GameEngine itself for the other half: it shouldn't be
## possible to crash this way even when a target scene forgets its script.
##
## Delete this once CharacterCreationScene (§12.2's next step after
## TitleScene) is real and wired up as actual content.
class_name CharacterCreationScene
extends Scene

const AMBER_DIM := Color(0.788, 0.541, 0.071)
const PIP_EMPTY_BORDER := Color(0.227, 0.227, 0.227)
const PIP_SIZE := 6

## Scene's only abstract method. Nothing to route yet — no actions are
## registered on this placeholder scene.
func do_action(_action: GameAction) -> void:
	pass


func on_enter() -> void:
	print("CharacterCreationScene.on_enter() — placeholder, not real content yet.")

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
