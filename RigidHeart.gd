extends RigidBody2D

func _ready() -> void:
	$AnimatedSprite2D.scale.x=2.75
	$AnimatedSprite2D.scale.y=$AnimatedSprite2D.scale.x
	randomize()
	var impulse = Vector2(
		randf_range(-250.0, 250.0),    # random X
		randf_range(-500.0, -100.0)    # random Y upward
	)

	apply_impulse(impulse,impulse)
	
	
func _process(delta: float) -> void:

	$AnimatedSprite2D.scale.x -=delta*1.45
	$AnimatedSprite2D.scale.y = $AnimatedSprite2D.scale.x  # keep uniform
	if $AnimatedSprite2D.speed_scale>0:
		$AnimatedSprite2D.speed_scale-=delta*8
	var step = delta * 0.5
	$AnimatedSprite2D.modulate.r -= step
	$AnimatedSprite2D.modulate.g -= step
	$AnimatedSprite2D.modulate.b -= step
	if self.global_position.y>800 or $AnimatedSprite2D.scale.x<0.001:
		queue_free()
