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


## Scene's only abstract method. Nothing to route yet — no actions are
## registered on this placeholder scene.
func do_action(_action: GameAction) -> void:
	pass


func on_enter() -> void:
	print("CharacterCreationScene.on_enter() — placeholder, not real content yet.")
