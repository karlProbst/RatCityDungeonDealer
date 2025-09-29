extends RigidBody2D
@onready var sprite = get_node_or_null("AnimatedSprite2D")
func _ready() -> void:
	sprite.scale.x=2.75
	sprite.scale.y=sprite.scale.x
	randomize()
	var impulse = Vector2(
		randf_range(-250.0, 250.0),    # random X
		randf_range(-500.0, -100.0)    # random Y upward
	)

	apply_impulse(impulse,impulse)
	
	
func _process(delta: float) -> void:

	sprite.scale.x -=delta*1.45
	sprite.scale.y = sprite.scale.x  # keep uniform
	if sprite.speed_scale>0:
		sprite.speed_scale-=delta*8
	var step = delta * 0.5
	sprite.modulate.r -= step
	sprite.modulate.g -= step
	sprite.modulate.b -= step
	if self.global_position.y>800 or sprite.scale.x<0.001:
		queue_free()
