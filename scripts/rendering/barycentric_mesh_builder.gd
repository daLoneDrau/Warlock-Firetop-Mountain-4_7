class_name BarycentricMeshBuilder
extends RefCounted

const BARY_A: Color = Color(1.0, 0.0, 0.0)
const BARY_B: Color = Color(0.0, 1.0, 0.0)
const BARY_C: Color = Color(0.0, 0.0, 1.0)

## Two triangles sharing an edge are treated as coplanar (and their shared
## edge suppressed from the wireframe) when the angle between their face
## normals is below this threshold. Deliberately tight — this should only
## catch genuine triangulation artifacts (a flat quad split into two
## triangles), not intentional low-poly faceting, which depends on visibly
## different face angles to read as faceted at all.
const COPLANAR_ANGLE_DEG: float = 1.0


static func build_exploded_mesh(source: MeshInstance3D) -> ArrayMesh:
	var mesh: Mesh = source.mesh
	if mesh == null:
		return null

	var out_verts: Array[Vector3] = []
	var out_normals: Array[Vector3] = []
	var out_colors: Array[Color] = []
	var out_uv: Array[Vector2] = []   # .x/.y = edge mask opposite corner 0/1
	var out_uv2: Array[Vector2] = []  # .x = edge mask opposite corner 2

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

		@warning_ignore("integer_division")
		var tri_count: int = indices.size() / 3

		# Pass 1: face normal per triangle + edge -> owning-triangle lookup,
		# keyed on the ORIGINAL shared vertex indices (before exploding).
		var face_normals: Array[Vector3] = []
		var edge_to_tris: Dictionary = {}  # "min:max" -> Array[int]

		for t in tri_count:
			var i0: int = indices[t * 3]
			var i1: int = indices[t * 3 + 1]
			var i2: int = indices[t * 3 + 2]
			face_normals.append((verts[i1] - verts[i0]).cross(verts[i2] - verts[i0]).normalized())

			for e in [[i0, i1], [i1, i2], [i2, i0]]:
				var key: String = "%d:%d" % [min(e[0], e[1]), max(e[0], e[1])]
				if not edge_to_tris.has(key):
					edge_to_tris[key] = []
				(edge_to_tris[key] as Array).append(t)

		# Pass 2: per-triangle, per-corner edge-visibility mask.
		var cos_threshold: float = cos(deg_to_rad(COPLANAR_ANGLE_DEG))

		for t in tri_count:
			var i0: int = indices[t * 3]
			var i1: int = indices[t * 3 + 1]
			var i2: int = indices[t * 3 + 2]
			var tri_verts := [i0, i1, i2]

			# opposite_edge[k] = the edge NOT touching corner k
			var opposite_edge := [[i1, i2], [i2, i0], [i0, i1]]
			var mask := [1.0, 1.0, 1.0]

			for k in 3:
				var e: Array = opposite_edge[k]
				var key: String = "%d:%d" % [min(e[0], e[1]), max(e[0], e[1])]
				var neighbors: Array = edge_to_tris[key]
				if neighbors.size() == 2:
					var other_t: int = neighbors[0] if neighbors[1] == t else neighbors[1]
					if face_normals[t].dot(face_normals[other_t]) >= cos_threshold:
						mask[k] = 0.0
			# neighbors.size() == 1 -> boundary/silhouette edge, always visible

			var bary := [BARY_A, BARY_B, BARY_C]
			for corner in 3:
				var idx: int = tri_verts[corner]
				out_verts.append(verts[idx])
				out_normals.append(normals[idx] if normals.size() > idx else face_normals[t])
				out_colors.append(bary[corner])
				out_uv.append(Vector2(mask[0], mask[1]))
				out_uv2.append(Vector2(mask[2], 0.0))

	if out_verts.is_empty():
		return null

	var out_arrays: Array = []
	out_arrays.resize(Mesh.ARRAY_MAX)
	out_arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array(out_verts)
	out_arrays[Mesh.ARRAY_NORMAL] = PackedVector3Array(out_normals)
	out_arrays[Mesh.ARRAY_COLOR] = PackedColorArray(out_colors)
	out_arrays[Mesh.ARRAY_TEX_UV] = PackedVector2Array(out_uv)
	out_arrays[Mesh.ARRAY_TEX_UV2] = PackedVector2Array(out_uv2)

	var exploded := ArrayMesh.new()
	exploded.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, out_arrays)
	return exploded
