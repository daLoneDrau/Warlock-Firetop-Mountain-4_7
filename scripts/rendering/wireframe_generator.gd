class_name WireframeGenerator
extends RefCounted

## World-space offset (meters) each edge vertex is pushed along its vertex
## normal, so the line overlay sits just off the fill mesh's surface and
## doesn't z-fight with it.
const EDGE_OFFSET: float = 0.004


## Builds a MeshInstance3D containing only the unique edges of the given
## mesh's geometry, rendered as PRIMITIVE_LINES. Returns null if the source
## mesh has no usable surfaces.
static func build_edge_mesh(source: MeshInstance3D) -> MeshInstance3D:
	var mesh: Mesh = source.mesh
	if mesh == null:
		return null

	var line_points: Array[Vector3] = []
	var seen_edges: Dictionary = {}

	for surface_idx in mesh.get_surface_count():
		var arrays: Array = mesh.surface_get_arrays(surface_idx)
		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]

		if indices.is_empty():
			var implicit_indices := PackedInt32Array()
			for i in verts.size():
				implicit_indices.append(i)
			indices = implicit_indices

		var tri_count: int = indices.size() / 3
		for t in tri_count:
			var tri := [indices[t * 3], indices[t * 3 + 1], indices[t * 3 + 2]]
			for edge_idx in 3:
				var a: int = tri[edge_idx]
				var b: int = tri[(edge_idx + 1) % 3]
				var key: String = "%d:%d" % [min(a, b), max(a, b)]
				if seen_edges.has(key):
					continue
				seen_edges[key] = true

				var pa: Vector3 = verts[a]
				var pb: Vector3 = verts[b]
				if normals.size() > a:
					pa += normals[a] * EDGE_OFFSET
				if normals.size() > b:
					pb += normals[b] * EDGE_OFFSET

				line_points.append(pa)
				line_points.append(pb)

	if line_points.is_empty():
		return null

	var line_arrays: Array = []
	line_arrays.resize(Mesh.ARRAY_MAX)
	line_arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array(line_points)

	var line_mesh := ArrayMesh.new()
	line_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, line_arrays)

	var line_instance := MeshInstance3D.new()
	line_instance.mesh = line_mesh
	line_instance.name = source.name + "Wireframe"
	return line_instance
