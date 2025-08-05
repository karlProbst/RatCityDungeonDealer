extends Node2D
# In Node2D or Scene3D script
@export var char:Node 
@onready var player_camera:Node
@onready var mini_camera = self
func _ready() -> void:
	player_camera=char.get_node("Camera3D")
func _process(delta):
	mini_camera.global_transform = player_camera.global_transform
