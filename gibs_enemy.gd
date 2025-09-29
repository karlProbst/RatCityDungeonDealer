extends Node3D
@onready var skull = $Area3D
@onready var skullray = $Area3D/RayCast3D
var a:float = 0.95
func _ready() -> void:
	$Bones.emitting=true
	$Bones.one_shot=true
	$Backbone.emitting=true
	$Backbone.one_shot=true
func _physics_process(delta: float) -> void:
	if not skullray.is_colliding():
		skull.translate(Vector3(0,a*10.5*delta,0))
		a-=delta*1.7
	else:
		self.set_script(null)


func _on_bones_finished() -> void:
	$Bones.queue_free()
	$Backbone.queue_free()
