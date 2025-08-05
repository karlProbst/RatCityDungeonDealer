extends Node3D

@export var speed: float = 20.0
@export var life_time: float = 3.0  # tempo para desaparecer

var life_timer: float = 0.0

func _physics_process(delta):
	# Move para frente local (eixo -Z)
	translate(Vector3(0, 0, -speed * delta))
	
	# Timer para destruir depois de um tempo
	life_timer += delta
	if life_timer >= life_time:
		queue_free()

func _on_body_entered(body):
	# Aqui você pode aplicar dano ou efeito
	queue_free()
