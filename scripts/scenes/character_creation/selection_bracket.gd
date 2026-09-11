## Draws the four-corner "viewfinder" selection marker on
## CharacterCreationScene's potion-diorama overlay (see the reference
## screenshot attached to that scene's phase-2 potion-selection pass).
## A bare [Control] with this script attached — no child nodes; every
## corner is drawn directly in _draw() against `size`, so moving/resizing
## the Control (character_creation_scene.gd repositions it per selection
## via .position) just moves the whole marker with it, nothing to
## recompute here.
##
## Amber (StyleGuideColors.WIREFRAME_AMBER), not the cyan used for the
## selected potion's label text — matching the reference screenshot,
## where the bracket stays amber while the label above it goes cyan.
## Amber is also this project's established "notice this" functional
## accent (style guide §5), which a selection marker qualifies as.
class_name SelectionBracket
extends Control

const ARM_LENGTH := 18.0
const LINE_WIDTH := 2.0


func _draw() -> void:
	var w: float = size.x
	var h: float = size.y
	_draw_corner(Vector2(0.0, 0.0), Vector2(1, 0), Vector2(0, 1))
	_draw_corner(Vector2(w, 0.0), Vector2(-1, 0), Vector2(0, 1))
	_draw_corner(Vector2(0.0, h), Vector2(1, 0), Vector2(0, -1))
	_draw_corner(Vector2(w, h), Vector2(-1, 0), Vector2(0, -1))


## Draws one corner's two arms, each ARM_LENGTH long, running along
## `x_dir`/`y_dir` from `corner` — the unit directions "inward" along
## that corner's two edges (e.g. the top-left corner's arms point right
## and down).
func _draw_corner(corner: Vector2, x_dir: Vector2, y_dir: Vector2) -> void:
	draw_line(corner, corner + x_dir * ARM_LENGTH, StyleGuideColors.WIREFRAME_AMBER, LINE_WIDTH)
	draw_line(corner, corner + y_dir * ARM_LENGTH, StyleGuideColors.WIREFRAME_AMBER, LINE_WIDTH)
