extends AnimatedSprite3D
func _ready() -> void:
	var mat := material_override
	if mat == null:
		mat = StandardMaterial3D.new()
		material_override = mat

	# Change the albedo color (tints the texture)
	mat.albedo_color = Color(1, 0, 0, 1) # Red, full opacity
