extends CharacterBody3D

@export var speed: float = 2.0
@onready var root = get_tree().current_scene
@onready var target = root.get_node("Char")

@onready var agent : NavigationAgent3D = $NavigationAgent3D

func _physics_process(delta: float) -> void:
	

	
	# Define o destino do agente como a posição do player
	agent.target_position = target.global_transform.origin

	# Calcula direção até o próximo ponto do caminho
	var next_point = agent.get_next_path_position()
	var direction = (next_point - global_transform.origin).normalized()

	# Move o inimigo nessa direção
	velocity = direction * speed
	move_and_slide()

	# Rotaciona para olhar na direção do movimento (opcional)
	if velocity.length() > 0.1:
		look_at(global_transform.origin + velocity, Vector3.UP)
