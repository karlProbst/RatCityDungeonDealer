extends AudioStreamPlayer3D
#footsteps
var footstep_time: float = 0.0
var last_step_value: float = 0.0
@export var footstep_speed_scale: float = 0.5
var min_velocity_for_steps: float = 0.2

@onready var father_node=get_parent()
func _process(delta):
	#footsteps
	var horizontal_speed = Vector2(father_node.velocity.x, father_node.velocity.z).length()
	
	if horizontal_speed>40:
		horizontal_speed=40
	if not father_node.is_on_floor():
		horizontal_speed = 0
	if horizontal_speed>min_velocity_for_steps:
		footstep_time += delta * horizontal_speed * footstep_speed_scale
		
		var sine_val = sin(footstep_time)
		if last_step_value <= 0 and sine_val > 0:
			play()
		last_step_value = sine_val
	else:
		footstep_time = 0
		last_step_value = 0
