## Bootstrap-only placeholder [Scene]. Exists solely to prove the
## WarlockGameEngine -> change_scene() -> Scene chain boots correctly.
## Not part of any spec'd content — delete once TitleScene (§12.2 of the
## UI/UX shell spec) is real and wired up as the actual first scene.
class_name BootTestScene
extends Scene


## Scene's only abstract method. Nothing to route yet — no actions are
## registered on this placeholder scene.
func do_action(_action: GameAction) -> void:
	pass


func on_enter() -> void:
	print("BootTestScene.on_enter() — engine bootstrap chain is alive.")