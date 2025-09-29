extends CharacterBody3D

#STATES
enum State { IDLE, PATROL, CHASE, ATTACK, DEAD, RANGED }
@export var state: State = State.CHASE
var patrol_points: Array[Vector3] = []
var patrol_i : Vector3= Vector3.ZERO
var last_patrol: Vector3 = Vector3.ZERO

#PHYSICS
@export var speed: float = 5.0
var speed_default: float = speed
@onready var root = get_tree().current_scene
@onready var target = root.get_node("Char")
@export var distance_radius:int=14
@export var smooth_factor := 0.15
@export var stuck_time := 0.2
@onready var agent : NavigationAgent3D = $NavigationAgent3D
@export var gravity: float = -35.0
@export var health:int=100
var stuck_timer := 0.0
var next_point:Vector3 = Vector3(0,0,0)
var direction:Vector3 = Vector3(0,0,0)
var last_position: Vector3
var dodge_speed=150
var dodge_vector:Vector3=Vector3.ONE
var dodge_timer:float=0.0
var attjump:= Vector3.ONE
var ranged_timer:=randf_range(1,8)
var projectile_scene = preload("res://ProjectileCrack.tscn")
var gibs_scene = preload("res://gibsEnemy.tscn")
#fire
var results: Array[Vector3] = []
var sample_count := 10
var sample_interval := 0.06 
var projectile_speed:=39
var avg_point:=Vector3.ZERO

func _ready() -> void:
	#create array of points of patrol
	var p := $Patrol
	if p:
		for child in p.get_children():
			patrol_points.append(child.global_position)
func _idle_update(delta):
	pass

func prepare_dodge(approach_speed: float, forward: Vector3, proj_pos: Vector3) -> void:
	#var str_num = int(dodge_vector.length() * 100)
	#if str_num>150 and str_num<180:
	if dodge_timer>0:
		return
	var dodge_base_force  : float = 0.5   # minimum lateral push
	var dodge_max_force   : float = 2.5   # cap the lateral push
	var dodge_vel   : Vector3 = Vector3.ZERO
	var distance        = global_transform.origin.distance_to(proj_pos)
	var time_to_impact  = distance / max(0.001, abs(approach_speed))
	var inv_t           = 1.0 / time_to_impact

	# --- horizontal forward & right (robust, avoids near-zero crosses)
	var f = forward
	f.y = 0.0
	if f.length_squared() < 0.0001:
	# fallback: use projectile->enemy direction if forward is unusable
		f = (global_transform.origin - proj_pos)
		f.y = 0.0
		f = f.normalized()

	var right = Vector3.UP.cross(f).normalized()  # "right" in the ground plane

	# --- choose side based on where the projectile is relative to enemy
	var to_enemy = (global_transform.origin - proj_pos)
	to_enemy.y = 0.0
	if to_enemy.length_squared() > 0.0:
		to_enemy = to_enemy.normalized()
	if right.dot(to_enemy) < 0.0:
		right = -right  # projectile will pass on the right -> dodge left

	# --- strength scales with urgency (lower TTI -> stronger)
	var force = clamp(dodge_base_force * inv_t, dodge_base_force, dodge_max_force)

	# --- set dodge impulse (horizontal only)
	dodge_vector = right * force
	dodge_timer = randf_range(0.1,2.0)

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
# Godot GDScript
func predictive_aim(points: Array[Vector3], velocity: Vector3, max_lookahead: float = 1.0) -> Vector3:
	if points.size() < 2:
		return points[-1]

	# Estimate velocity from recent positions (average of last few steps)
	var est_velocity = Vector3.ZERO
	var samples = min(5, points.size() - 1)
	for i in range(samples):
		est_velocity += points[-1 - i] - points[-2 - i]
	est_velocity /= samples

	# Blend estimated velocity with given velocity
	var blended_velocity = est_velocity.lerp(velocity, 0.5)

	# Predict future position with capped lookahead
	var lookahead_time = min(max_lookahead, blended_velocity.length() * 0.05)
	return points[-1] + blended_velocity * lookahead_time

	
func predict_next_point(points: Array[Vector3]) -> Vector3:
	# --- Weighted velocity from all points ---
	var weighted_velocity = Vector3.ZERO
	var weight_sum = 0.0
	for i in range(1, points.size()):
		var step = points[i] - points[i - 1]
		var weight = float(i) # last steps have more weight
		weighted_velocity += step * weight
		weight_sum += weight
	weighted_velocity /= weight_sum
	var straight = points[-1] + weighted_velocity*0.7
	
	var curvy= predictive_aim(points,target.velocity,randf_range(0.5,1.0))
	#
	var center := Vector3.ZERO
	for p in points:
		center += p
	center /= points.size()
	var predictive = get_intercept($AttackPoint.global_position, projectile_speed, target.global_position, target.velocity)
	
	var w_straight = clampf(randf_range(-1.0, 1.0),0,1.0)
	var w_curvy = clampf(randf_range(-1.0, 1.0),0,1.0)
	var w_predictive = clampf(randf_range(-1.0, 1.0),0,1.0)
	
	# Normalize weights
	var w_sum = w_straight + w_curvy + w_predictive
	if w_sum==0:
		w_predictive=1.0
		w_sum=1.0
	w_straight /= w_sum
	w_curvy /= w_sum
	w_predictive /= w_sum
	# --- Final predicted point ---
	return straight * w_straight + curvy * w_curvy + predictive * w_predictive



func Fire(pos:Vector3,rot:Vector3,target:Node)->void:
	$AttackSound.stop()
	$AttackSound.play()
	
	var projectile = projectile_scene.instantiate()
	get_parent().add_child(projectile)
	projectile.position = pos
	projectile.rotation = rot
	projectile.speed=projectile_speed
	projectile.father=self
	projectile.distance_to_explode=500
	#var dir = get_intercept_direction(global_position, target.global_position, target.velocity, speed)
	projectile.set_target(target,Vector3(0,2.5,0),avg_point)
	avg_point=Vector3.ZERO

func get_intercept(shooter_pos:Vector3,
	bullet_speed: float,
	target_position: Vector3,
	target_velocity: Vector3) -> Vector3:
	target_velocity.y=0.0
	var a:float = bullet_speed*bullet_speed - target_velocity.dot(target_velocity)
	var b:float = 2*target_velocity.dot(target_position-shooter_pos)
	var c:float = (target_position-shooter_pos).dot(target_position-shooter_pos)
	# Protect against divide by zero and/or imaginary results
	# which occur when bullet speed is slower than target speed
	var time:float = 0.0
	if bullet_speed > target_velocity. length() :
		time = (b+sqrt(b*b+4*a*c)) / (2*a)
	return target_position+time*target_velocity
	
func start_sampling():
	results.clear()
	_sample(0)
func _sample(i: int):
	if i >= sample_count:
		avg_point = predict_next_point(results)
		return
	else:
		avg_point=Vector3.ONE
	#var point = get_intercept($AttackPoint.global_position, projectile_speed, target.global_position, target.velocity)
	var point = target.global_position
	results.append(point)
	await get_tree().create_timer(sample_interval).timeout
	_sample(i + 1)
		
func _ranged_update(delta)->void:
	look_at(target.global_position)
	var ray = $AttackPoint/RayCast3D
	if ray:
		ray.force_raycast_update()
		if ray.is_colliding():
			var collider = ray.get_collider()
			if collider and collider != target:
				var hit_pos = ray.get_collision_point()
				var dist_to_hit = global_position.distance_to(hit_pos)
				var dist_to_target = global_position.distance_to(target.global_position)

				if dist_to_hit < dist_to_target:
					# Randomly sidestep left or right
					var side = 1.0
					if (randf() > 0.5):
						side= -1.0 
					dodge_vector = transform.basis.x * side * 1.1
					ranged_timer = clampf(randi_range(-5, 5), 0.0, 1.0)
					state = State.CHASE
	speed=0
	$AnimatedSprite3D.speed_scale=1
	if avg_point==Vector3.ZERO:
		start_sampling()
	if avg_point!=Vector3.ZERO and avg_point!=Vector3.ONE:
		Fire($AttackPoint.global_position,global_rotation,target)
		ranged_timer=clampf(randi_range(-10.0,5.0),0.0,5.0)
		state=State.CHASE

func _chase_update(delta)->void:
	#anim
	
	look_at(target.global_position)
	if not is_on_floor():
		direction=Vector3.ZERO
	# Define o destino do agente como a posição do player
	if not target:
		printerr("target or navigation agent not found!")
		return
	agent.target_position = target.global_transform.origin
	var distance = global_transform.origin.distance_to(target.global_transform.origin)
	if distance >distance_radius:
		next_point = agent.get_next_path_position()
		direction = (next_point - global_transform.origin).normalized()
	else:
		state=State.ATTACK
		
func _dead_update(delta):
	if $OmniLight3D.visible:
		var gibs = gibs_scene.instantiate()
		get_parent().add_child(gibs)
		gibs.global_position=self.global_position
		gibs.global_rotation=self.global_rotation
	$OmniLight3D.visible=false
	$Blink.play("Death")
	$AnimatedSprite3D.translate(Vector3(0,-delta,0))
	$CollisionShape3D.disabled=true
func play_anim(anim:String)->void:
	$AnimatedSprite3D.play(anim)
func get_anim_frame()->int:
	return $AnimatedSprite3D.frame
func cancel_attack():
	state=State.CHASE
	attjump=Vector3(0.1,0.1,0.1)
func _attack_update(delta)->void:
	#still move
	agent.target_position = target.global_transform.origin
	next_point = agent.get_next_path_position()
	var desired_dir = (next_point - global_transform.origin).normalized()
	direction = direction.lerp(desired_dir, 10 * delta).normalized()
	#direction=Vector3.ZERO
	$AnimatedSprite3D.speed_scale=1
	if get_anim_frame()==1:
		attjump=Vector3(1.4,1.4,1.4)
		$AttackHitbox.monitoring = true
		if is_on_floor():
			velocity.y+=13
	else:
		$AttackHitbox.monitoring = false
	if get_anim_frame()==2:
		cancel_attack()
func _process(delta: float) -> void:
	
	if ranged_timer>0:
		ranged_timer-=delta
	else:
		var distance = global_transform.origin.distance_to(target.global_transform.origin)
		if distance<50:
			state=State.RANGED
	if dodge_timer>0:
		dodge_timer-=delta
	#STATE MACHINE
	if health > 0:
		match state:
			State.IDLE:
				_idle_update(delta)
			State.PATROL:
				_patrol_update(delta)
				walk_anim()
			State.CHASE:
				_chase_update(delta)
				walk_anim()
			State.ATTACK:
				if dodge_vector!=Vector3.ZERO:
					walk_anim()
				else:
					play_anim("Attack")
				_attack_update(delta)
			State.RANGED:
				if dodge_vector!=Vector3.ZERO:
					walk_anim()
				else:
					play_anim("Attack")
				_ranged_update(delta)
	else:
		#DIE
		state=State.DEAD
		_dead_update(delta)
	

	
func walk_anim()->void:
	
	var forward = -global_transform.basis.z 
	var right = global_transform.basis.x
	var to_player = (target.global_position - global_position).normalized()
	var dot_forward = forward.dot(to_player) 
	var dot_right = right.dot(to_player)   
	

		
	# decide animação
	if abs(dot_forward) > abs(dot_right):		
		$AnimatedSprite3D.speed_scale=velocity.length()/16
		if dot_forward > 0:
			play_anim("Forward")
		else:
			play_anim("Back")
	else:
		$AnimatedSprite3D.speed_scale=velocity.length()/12
		if dot_right > 0:
			play_anim("Left")
			$AnimatedSprite3D.flip_h=true
		else:
			play_anim("Left")
			$AnimatedSprite3D.flip_h=false
	if not is_on_floor():
		$AnimatedSprite3D.speed_scale=0
func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
	# Base chasing movement
		velocity.x = direction.x * speed * attjump.x
		velocity.z = direction.z * speed * attjump.z
		
		# Apply dodge influence additively

		velocity.x += dodge_vector.x *20
		velocity.z += dodge_vector.z *20



	# Gradualmente retorna para (1,1,1)
	dodge_vector = dodge_vector.lerp(Vector3.ZERO, 3.0 * delta)
	attjump = attjump.lerp(Vector3.ONE, 3.0 * delta)

	
	if health>0:
		move_and_slide()
	if speed<speed_default:
		speed+=delta*9
	
func projectile_hit(amount):
	cancel_attack()
	$Blink.play("Hurt")
	$Blink.seek(0)
	speed-=(amount/2.0)
	health -= amount
	$DamageSound.play()
	if health <= 0:
		$DeathSound.play()
		

func _on_death_sound_finished() -> void:
	queue_free()


func _on_attack_hitbox_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player"):
		var direction = (body.global_position - global_position).normalized()
		var knockback_strength = 45.0
		direction.y = 0.25
		direction = direction.normalized() 
		if body.has_method("apply_knockback"):
			body.apply_knockback(direction * knockback_strength,self)
