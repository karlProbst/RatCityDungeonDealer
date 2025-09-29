extends CharacterBody3D

@export var speed: float = 11.0
@export var mouse_sensitivity: float = 0.002
@export var gravity: float = -50.0
@export var run: float = 1.0
var projectile_scene = preload("res://Projectile.tscn")
var mouse_delta: Vector2
#MAGIC
var projectiles:Array[Node]=[]
var firing=false
var charging = false
var charge_time = 0.0
var max_charge = 1.7  # segundos para carga máxima
var min_ball_scale = 0.6
var max_ball_scale =3.0
# Referências
@onready var cam_pivot = $Camera3D
@onready var sprite = $Camera3D/AnimatedSprite3D
@export var hud:Node
var reverb:AudioEffect
var knockback : Vector3=Vector3.ZERO
var lowpasseffect:AudioEffect
@onready var laser = get_node_or_null("Camera3D/Laserray")
@onready var lasermesh = get_node_or_null("Camera3D/Laserray/Mesh")
@onready var laserball = get_node_or_null("LaserBall")
@onready var root = get_tree().current_scene
func _ready():
	$Camera3D.fov=105
	var bus := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(bus,0)
	for i in range(AudioServer.get_bus_effect_count(bus) - 1, -1, -1):
		var effect := AudioServer.get_bus_effect(bus, i)
		if effect is AudioEffectReverb:
			AudioServer.remove_bus_effect(bus, i)
		if effect is AudioEffectLowPassFilter:
			lowpasseffect = effect
	lowpasseffect.cutoff_hz=20500


	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	var mat = hud.get_node("ViewportRect").material
	if mat is ShaderMaterial:
		mat.set_shader_parameter("u_noise",0)
		mat.set_shader_parameter("white_tint",0.5)
	$Camera3D.attributes.exposure_multiplier=1
func _input(event):
	if event is InputEventMouseMotion:
		mouse_delta = event.relative

func remove_from_projectiles(node:Node)->void:
	for p in projectiles:
		if p:
			if p == node:
				projectiles.erase(p)
				hud.get_node("Control/Mp").add_stat()
func Fire(scale_factor:float,_att:int, pos:Vector3,rot:Vector3)->void:
	
	var projectile = projectile_scene.instantiate()
	projectile.position = pos
	#aim correction
	rot.x+=0.012
	
	projectile.rotation = rot
	projectile.scale.x=scale_factor
	projectile.scale.y=scale_factor
	projectile.speed=60-(scale_factor*5)
	projectile.father=self
	
	get_parent().add_child(projectile)
	projectiles.append(projectile)
	hud.get_node("Control/Mp").remove_stat()
	



func _process(delta):
	if Engine.time_scale == 0.0:
		return
	#sound
	Engine.time_scale = clamp(Engine.time_scale + delta * 0.4, 0.0, 1.0)
	$Breakcore1.pitch_scale = Engine.time_scale
	if lowpasseffect:
		if lowpasseffect.cutoff_hz<20000:
			lowpasseffect.cutoff_hz=clamp(lowpasseffect.cutoff_hz + delta * 1700, 0.0, 20000.0)
	#footsteps
	if Input.is_action_pressed("restart"):
	# Obtém a cena atual
		get_tree().reload_current_scene()
	#look
	
	rotate_y(-mouse_delta.x * mouse_sensitivity)
	var x_rot = cam_pivot.rotation.x - mouse_delta.y * mouse_sensitivity
	x_rot = clamp(x_rot, deg_to_rad(-89), deg_to_rad(89))
	cam_pivot.rotation.x = x_rot
	
	mouse_delta = Vector2.ZERO
	#JUMP

	#MAGIC
	
	if Input.is_action_pressed("altfire"):	
		var collision_point: Vector3
		var origin = laser.global_transform.origin
		
		if laser.is_colliding():
			collision_point = laser.get_collision_point()
			laserball.global_position = collision_point
			laserball.visible = true
		else:
			var max_dist = 1000.0
			var dir = (-cam_pivot.global_transform.basis.z + cam_pivot.global_transform.basis.y * -0.1).normalized()
			
			collision_point = origin + dir * max_dist
			laserball.visible = false  # hide ball if no collision

		var dist = origin.distance_to(collision_point)


		lasermesh.visible = true
		lasermesh.look_at(collision_point)
		lasermesh.scale.z = dist

		# Scale laser ball if visible
		if laserball.visible:
			laserball.scale = Vector3.ONE * (dist / 10.0)

		for p in projectiles:
			if p:
				if p is Node:
					if laserball:
						p.look_at(laserball.global_position)
	else:
		pass
		lasermesh.visible=false
		laserball.visible=false
	if Input.is_action_just_pressed("fire") and not charging and sprite.animation == "Idle":
		if hud.get_node("Control/Mp").get_stat()>0:
			charging = true
			charge_time = 0.0
			sprite.animation = "ChargingFire"
	if sprite.animation == "Attack01" and sprite.frame==4:
		sprite.animation = "Idle"
	if charging:
		charge_time += delta
		var scale_factor = lerp(min_ball_scale, max_ball_scale, min(charge_time / max_charge, 1))
		$Camera3D/EnergyBall.scale.x=scale_factor
		$Camera3D/EnergyBall.scale.y=scale_factor
		$Camera3D/EnergyBall.visible=true
		$Camera3D/MagicLight.visible = true
		$Camera3D/MagicLight.light_energy=0.1+(scale_factor*7)+(sin(charge_time*10)*3)-2
		
		if Input.is_action_just_released("fire"):
			sprite.animation="Attack01"
			$Shoot.play()
			var pontodefogopos = $Camera3D/PontoDefogo.global_position
			Fire(scale_factor, 1,pontodefogopos,Vector3(cam_pivot.rotation.x,self.rotation.y,0))
			charging = false
			charge_time = 0.0
			$Camera3D/MagicLight.visible = false
			$Camera3D/EnergyBall.visible=false	

	if is_on_floor():
		if Input.is_action_pressed("run"):
			run=2.0
		else:
			run=1.0
	revert_hud_noise(delta)


func _physics_process(delta):
	if Engine.time_scale == 0.0:
		return
	var input_dir = Vector2.ZERO
	input_dir.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	input_dir.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	input_dir = input_dir.normalized()

	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		if Input.is_action_just_pressed("jump"):
			velocity.y = 25

	var decay_rate = 180 * delta
	if knockback.length() > 2:
		velocity = knockback
		knockback -= knockback.normalized() * decay_rate
	else:
		knockback = Vector3.ZERO

	if knockback == Vector3.ZERO:
		if not is_on_floor():
			var air_control = 0.3
			velocity.x = lerp(velocity.x, direction.x * speed * run, air_control * delta * 5.0)
			velocity.z = lerp(velocity.z, direction.z * speed * run, air_control * delta * 5.0)
		else:
			velocity.x = direction.x * speed * run
			velocity.z = direction.z * speed * run
	move_and_slide()
func revert_hud_noise(delta)->void:
	var mat = hud.get_node("ViewportRect").material
	if mat is ShaderMaterial:
		var noise = mat.get_shader_parameter("u_noise")
		var min =0
		if hud.get_node("Control/Hp").get_stat()==1:
			min=1
		if noise>min:
			mat.set_shader_parameter("u_noise", noise-delta*11)
		if hud.get_node("Control/Hp").get_stat()==0:
			#REVERB
			var bus := AudioServer.get_bus_index("Master")
			if not reverb: # adiciona só uma vez
				reverb = AudioEffectReverb.new()
				reverb.room_size=0.0
				AudioServer.add_bus_effect(bus, reverb, 0)
			# aumenta room_size progressivamente até 1.0
			$Camera3D.fov+=delta*1.35
			$Camera3D/AnimatedSprite3D.position.y-=delta*1.5
			reverb.room_size = clamp(reverb.room_size + delta * 0.25, 0.0, 1.0)
			AudioServer.set_bus_volume_db(bus, max(AudioServer.get_bus_volume_db(bus) - delta*5, -80.0))
			$Breakcore1.pitch_scale = clamp($Breakcore1.pitch_scale - delta * 0.2, 0.0, 1.0)
			$Camera3D.attributes.exposure_multiplier=$Camera3D.attributes.exposure_multiplier+delta*2
			mat.set_shader_parameter("u_noise", 1)
			mat.set_shader_parameter("white_tint", mat.get_shader_parameter("white_tint")+delta/6)
			$CollisionShape3D.disabled=true
			velocity.y = 10
			knockback=Vector3.ZERO

			if mat.get_shader_parameter("white_tint")> 1:
				get_tree().reload_current_scene()
		else:
			if mat.get_shader_parameter("white_tint")>0:
				mat.set_shader_parameter("white_tint", mat.get_shader_parameter("white_tint")-delta)
	
func apply_knockback(knockback_vector: Vector3,enemy:Node):
	Engine.time_scale = 0.5
	lowpasseffect.cutoff_hz=950.0
	knockback= knockback_vector
	hud.get_node("Control/Hp").remove_stat()
	var mat = hud.get_node("ViewportRect").material
	if mat is ShaderMaterial:
		var noise = mat.get_shader_parameter("u_noise")
		mat.set_shader_parameter("u_noise", noise+4)
	hud.get_node("Control/HitMarkerContainer").show_hit(enemy,self)
	if enemy.has_method("cancel_attack"):
		enemy.cancel_attack()
func _on_animated_sprite_3d_animation_finished() -> void:
	if sprite.animation == "Attack01":
		sprite.animation = "Idle"	
		sprite.play()
