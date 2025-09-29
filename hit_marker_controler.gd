extends AspectRatioContainer  # Or CanvasLayer, depending on your setup

@export var duration := 0.5      # Time to track enemy
@export var distance := 150      # Pixels from center
@onready var hitmarker := get_child(0)
var player:Node
var timer := 0.0
var target_enemy: Node3D = null
var target_enemy_pos:=Vector3.ZERO
func show_hit(enemy: Node3D,player_node:Node3D):
	player=player_node
	target_enemy = enemy
	hitmarker.visible = true
	hitmarker.modulate.a = 1.0
	timer = duration

func _process(delta):
	
	if timer > 0:
		timer -= delta/1.3
		hitmarker.modulate.a = clamp(timer / duration, 0, 1)
		
		if target_enemy:
			target_enemy_pos=target_enemy.global_position
		if player:
			var dir = (target_enemy_pos - player.global_position)
			dir.y = 0
			dir = dir.normalized()
			var local_dir = player.global_transform.basis.inverse() * dir
			hitmarker.rotation = atan2(-local_dir.x, local_dir.z)
			
	else:
		hitmarker.visible = false
		target_enemy = null
