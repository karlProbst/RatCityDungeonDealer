extends CharacterBody3D

@export var speed: float = 10.0
var speed_default: float = speed
@onready var root = get_tree().current_scene
@onready var target = root.get_node("Char")
@export var distance_radius:int= 8
@export var smooth_factor := 0.15
@export var stuck_time := 0.2
@onready var agent : NavigationAgent3D = $NavigationAgent3D
@export var gravity: float = -35.0
@export var health:int=100
var stuck_timer := 0.0
var next_point:Vector3 = Vector3(0,0,0)
var direction:Vector3 = Vector3(0,0,0)
var last_position: Vector3
func _ready() -> void:
	pass
func _physics_process(delta: float) -> void:

	if health <= 0:
		$OmniLight3D.visible=false
		$Blink.play("Death")
		$AnimatedSprite3D.translate(Vector3(0,-delta,0))
		$CollisionShape3D.disabled=true
	agent.path_desired_distance = distance_radius  # Stop before touching
	agent.path_max_distance = 1.0
	agent.avoidance_enabled = true
	# Define o destino do agente como a posição do player
	if not target:
		printerr("target or navigation agent not found!")
		return
	
	agent.target_position = target.global_transform.origin
	
	var distance = global_transform.origin.distance_to(target.global_transform.origin)
	if distance >distance_radius:
		next_point = agent.get_next_path_position()
		direction = (next_point - global_transform.origin).normalized()
	
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.x = direction.x * speed 
		velocity.z = direction.z * speed
	
	if health>0:
		move_and_slide()
	if speed<speed_default:
		speed+=delta*8
	
func projectile_hit(amount):
	$Blink.play("Hurt")
	$Blink.seek(0)
	speed-=(amount/2.0)
	health -= amount
	$DamageSound.play()
	print("Inimigo recebeu ", amount, " de dano. Vida: ", health)
	if health <= 0:
		$DeathSound.play()
		

	
	


func _on_death_sound_finished() -> void:
	queue_free()
