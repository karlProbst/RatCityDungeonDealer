extends Camera3D

@export var player_path: Node
@onready var player_camera: Node = player_path.get_node("Camera3D")

func _ready():
	current = true


func _process(delta):
	
	global_transform = player_camera.global_transform
