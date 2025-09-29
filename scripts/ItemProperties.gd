extends Resource
class_name ItemResource

@export var id: int = 0
@export var item_name: String
@export var icon: Texture2D = preload("res://textures/blackTexture.tres")
@export var stackable: bool = false
@export var stack: int
@export var MAX_STACK: int
@export var price: float
@export var dropable: bool = true
