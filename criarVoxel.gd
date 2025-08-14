extends Node

func create_and_save_voxel_sprite(texture_path: String, thickness: float = 0.2, save_path: String = "res://"):
	# Load texture
	var texture = load(texture_path)
	if not texture:
		push_error("Texture not found: " + texture_path)
		return
	
	# Create extruded mesh
	var mesh = create_extruded_sprite(texture, thickness)
	if not mesh:
		push_error("Failed to create mesh")
		return
	
	# Create MeshInstance for the scene
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = mesh
	
	# Ensure directory exists
	DirAccess.make_dir_recursive_absolute(save_path)
	
	# Save as OBJ
	save_mesh_as_obj(mesh, save_path.path_join("output.obj"))
	
	# Save as scene
	save_as_scene(mesh_instance, save_path.path_join("output.tscn"))

func create_extruded_sprite(texture: Texture, thickness: float) -> ArrayMesh:
	var mesh = ArrayMesh.new()
	var st = SurfaceTool.new()
	
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var width = texture.get_width() / 100.0  # Adjust scale as needed
	var height = texture.get_height() / 100.0
	var half_thickness = thickness / 2.0
	
	# Define vertices (8 vertices for a box)
	var vertices = PackedVector3Array([
		# Front face
		Vector3(-width/2, -height/2, half_thickness),  # 0
		Vector3(width/2, -height/2, half_thickness),   # 1
		Vector3(width/2, height/2, half_thickness),    # 2
		Vector3(-width/2, height/2, half_thickness),   # 3
		
		# Back face
		Vector3(-width/2, -height/2, -half_thickness), # 4
		Vector3(width/2, -height/2, -half_thickness),  # 5
		Vector3(width/2, height/2, -half_thickness),   # 6
		Vector3(-width/2, height/2, -half_thickness)   # 7
	])
	
	# Define UV coordinates (8 UVs matching vertices)
	var uvs = PackedVector2Array([
		# Front face UVs
		Vector2(0, 0),  # 0
		Vector2(1, 0),  # 1
		Vector2(1, 1),  # 2
		Vector2(0, 1),  # 3
		
		# Back face UVs (mirrored)
		Vector2(1, 0),  # 4
		Vector2(0, 0),  # 5
		Vector2(0, 1),  # 6
		Vector2(1, 1)   # 7
	])
	
	# Define indices for triangles (12 triangles = 36 indices)
	var indices = PackedInt32Array([
		# Front face (2 triangles)
		0, 1, 2, 0, 2, 3,
		# Back face (2 triangles)
		4, 6, 5, 4, 7, 6,
		# Side faces (8 triangles)
		0, 5, 1, 0, 4, 5,
		1, 6, 2, 1, 5, 6,
		2, 7, 3, 2, 6, 7,
		3, 4, 0, 3, 7, 4
	])
	
	# Add vertices, UVs, and build faces
	for i in indices.size():
		st.set_uv(uvs[indices[i]])
		st.add_vertex(vertices[indices[i]])
	
	# Configure material
	var mat = StandardMaterial3D.new()
	mat.albedo_texture = texture
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	
	# Generate normals and commit to mesh
	st.generate_normals()
	st.set_material(mat)
	st.commit(mesh)
	
	return mesh

func save_mesh_as_obj(mesh: ArrayMesh, path: String) -> bool:
	var file = FileAccess.open(path, FileAccess.WRITE)
	if not file:
		push_error("Failed to create file: ", path, " Error: ", FileAccess.get_open_error())
		return false
	
	# Write header
	file.store_string("# Exported from Godot Engine\n")
	file.store_string("mtllib output.mtl\n")
	
	# Get mesh data
	var arrays = mesh.surface_get_arrays(0)
	var vertices = arrays[ArrayMesh.ARRAY_VERTEX] as PackedVector3Array
	var uvs = arrays[ArrayMesh.ARRAY_TEX_UV] as PackedVector2Array
	var normals = arrays[ArrayMesh.ARRAY_NORMAL] as PackedVector3Array
	
	# Write vertices
	for v in vertices:
		file.store_string("v %.6f %.6f %.6f\n" % [v.x, v.y, v.z])
	
	# Write UVs
	for uv in uvs:
		file.store_string("vt %.6f %.6f\n" % [uv.x, uv.y])
	
	# Write normals if available
	if normals and normals.size() > 0:
		for n in normals:
			file.store_string("vn %.6f %.6f %.6f\n" % [n.x, n.y, n.z])
	
	# Write faces (assuming triangles)
	var face_count = vertices.size() / 3
	for i in range(0, face_count * 3, 3):
		var v1 = i + 1
		var v2 = i + 2
		var v3 = i + 3
		
		if normals and normals.size() > 0:
			file.store_string("f %d/%d/%d %d/%d/%d %d/%d/%d\n" % [v1,v1,v1, v2,v2,v2, v3,v3,v3])
		else:
			file.store_string("f %d/%d %d/%d %d/%d\n" % [v1,v1, v2,v2, v3,v3])
	
	file.close()
	print("OBJ saved successfully: ", path)
	return true

func save_as_scene(node: Node, path: String) -> bool:
	var scene = PackedScene.new()
	
	# Pack the node into the scene
	if scene.pack(node) != OK:
		push_error("Failed to pack scene")
		return false
	
	# Save the scene
	var error = ResourceSaver.save(scene, path)
	if error != OK:
		push_error("Failed to save scene: ", error_string(error))
		return false
	
	print("Scene saved successfully: ", path)
	return true

func _ready():
	# Example usage - call this to export
	create_and_save_voxel_sprite("res://Assets/glowieCIA/quadro0000_transparente.png", 0.2, "res://models/")
