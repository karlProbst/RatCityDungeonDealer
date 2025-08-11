extends MeshInstance3D


@export var player_path: Node
@onready var player_camera: Node = player_path.get_node("Camera3D")



func _process(delta):



	# Posiciona o quad 1 unidade à frente da câmera do jogador
	global_transform.origin = player_camera.global_transform.origin + player_camera.global_transform.basis.z * -5.0
	global_transform.basis = player_camera.global_transform.basis
