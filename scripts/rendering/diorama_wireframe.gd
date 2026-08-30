## Attach as a child of any diorama root node to automatically apply the
## project's wireframe rendering treatment (style guide §1–§2) to every
## MeshInstance3D underneath its parent, at runtime.
class_name DioramaWireframe
extends Node


func _ready() -> void:
	var root: Node = get_parent()
	if root != null:
		_apply_recursive(root)


func _apply_recursive(node: Node) -> void:
	if node is MeshInstance3D:
		_wireframe_mesh_instance(node as MeshInstance3D)
	for child in node.get_children():
		if child.name.ends_with("Wireframe"):
			continue  # skip line meshes we've already generated
		_apply_recursive(child)


func _wireframe_mesh_instance(mesh_instance: MeshInstance3D) -> void:
	mesh_instance.material_override = _make_fill_material()

	var line_instance: MeshInstance3D = WireframeGenerator.build_edge_mesh(mesh_instance)
	if line_instance == null:
		return
	line_instance.material_override = _make_line_material()
	mesh_instance.add_child(line_instance)


func _make_fill_material() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = StyleGuideColors.FILL_NEAR_BLACK
	return mat


func _make_line_material() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = StyleGuideColors.WIREFRAME_AMBER
	return mat
