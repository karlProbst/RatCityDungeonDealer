extends CharacterBody3D

#STATES
enum State { IDLE, PATROL, CHASE, ATTACK, DEAD }
var state: State = State.PATROL
var patrol_points: Array[Vector3] = []
var patrol_i : Vector3= Vector3.ZERO
var last_patrol: Vector3 = Vector3.ZERO
#PHYSICS
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
	#create array of points of patrol
	var p := $Patrol
	if p:
		for child in p.get_children():
			patrol_points.append(child.global_position)
		print(patrol_points)
func _idle_update(delta):
	pass
func get_closest_target_patrol()->Vector3:
		#find closest target
	var closest_point
	for t in patrol_points:
		var min_dist=9999.0
		var dist_to=global_transform.origin.distance_to(t)
		if (last_patrol!=Vector3.ZERO and last_patrol!=t) or (last_patrol==Vector3.ZERO):
			if dist_to <min_dist and dist_to>15:
				min_dist = dist_to
				closest_point=t
		return closest_point
	return Vector3.ZERO
func _patrol_update(delta):
	#is there valid points of patrol
	if patrol_points.size()<2:
		printerr("patrol_points invalid")
		return
	if patrol_i==Vector3.ZERO:
		patrol_i = get_closest_target_patrol()
	#go to target
	agent.target_position = patrol_i
	next_point = agent.get_next_path_position()
	direction = (next_point - global_transform.origin).normalized()
	look_at(patrol_i, Vector3.UP)
	#chegou no target
	if global_transform.origin.distance_to(patrol_i)<5:
		# Descobre o índice atual do ponto de patrulha
		var current_index := -1
		for i in range(patrol_points.size()):
			var pos = patrol_points[i]
			if pos == patrol_i:
				current_index = i
				break
		var next_index = (current_index + 1) % patrol_points.size()
		patrol_i = patrol_points[next_index]


func _chase_update(delta):
	# Define o destino do agente como a posição do player
	if not target:
		printerr("target or navigation agent not found!")
		return
	agent.target_position = target.global_transform.origin
	var distance = global_transform.origin.distance_to(target.global_transform.origin)
	if distance >distance_radius:
		next_point = agent.get_next_path_position()
		direction = (next_point - global_transform.origin).normalized()

func _dead_update(delta):
	$OmniLight3D.visible=false
	$Blink.play("Death")
	$AnimatedSprite3D.translate(Vector3(0,-delta,0))
	$CollisionShape3D.disabled=true
	
	
func _process(delta: float) -> void:
	
	#STATE MACHINE
	match state:
		State.IDLE:
			_idle_update(delta)
		State.PATROL:
			_patrol_update(delta)
		State.CHASE:
			_chase_update(delta)
		State.DEAD:
			_dead_update(delta)
	#DIE
	if health <= 0:
		state=State.DEAD


func _physics_process(delta: float) -> void:

	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.x = direction.x * speed 
		velocity.z = direction.z * speed
	
	if health>0:
		move_and_slide()
	if speed<speed_default:
		speed+=delta*9
	
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
