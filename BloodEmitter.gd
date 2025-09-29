extends Node

@onready var particle_scene = preload("res://blood.tscn")

func spawn_blood(pos: Vector3,rot: Vector3):
	var particle = particle_scene.instantiate()
	get_parent().get_parent().add_child(particle)
	particle.global_position = pos
	particle.global_rotation = rot
	
	particle.emitting = true
	
	particle.finished.connect(func():
		particle.queue_free()
	)
