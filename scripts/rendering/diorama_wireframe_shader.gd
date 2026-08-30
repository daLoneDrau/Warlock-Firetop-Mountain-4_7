## Alternative to DioramaWireframe (Approach B) — single-pass barycentric
## wireframe shader (Approach C). Use ONE of DioramaWireframe /
## DioramaWireframeShader per diorama, not both.
class_name DioramaWireframeShader
extends Node

const WIREFRAME_SHADER: Shader = preload("res://shaders/wireframe_barycentric.gdshader")


func _ready() -> void:
	var root: Node = get_parent()
	if root != null:
		_apply_recursive(root)


func _apply_recursive(node: Node) -> void:
	if node is MeshInstance3D:
		_shade_mesh_instance(node as MeshInstance3D)
	for child in node.get_children():
		_apply_recursive(child)


func _shade_mesh_instance(mesh_instance: MeshInstance3D) -> void:
	var exploded: ArrayMesh = BarycentricMeshBuilder.build_exploded_mesh(mesh_instance)
	if exploded == null:
		return

	mesh_instance.mesh = exploded  # runtime-only swap; doesn't touch the source .glb

	var mat := ShaderMaterial.new()
	mat.shader = WIREFRAME_SHADER
	mat.set_shader_parameter("fill_color", StyleGuideColors.FILL_NEAR_BLACK)
	mat.set_shader_parameter("line_color", StyleGuideColors.WIREFRAME_AMBER)
	mat.set_shader_parameter("line_width", 1.5)
	mesh_instance.material_override = mat
