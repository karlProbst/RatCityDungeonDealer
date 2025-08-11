extends CharacterBody3D

@export var speed: float = 11.0
@export var mouse_sensitivity: float = 0.002
@export var gravity: float = -35.0
@export var run: float = 1.0

var mouse_delta: Vector2
#MAGIC
var firing=false
var charging = false
var charge_time = 0.0
var max_charge = 2.0  # segundos para carga máxima
var min_ball_scale = 0.3
var max_ball_scale = 2.0
# Referências
@onready var cam_pivot = $Camera3D
@onready var sprite = $Camera3D/AnimatedSprite3D



func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	if event is InputEventMouseMotion:
		mouse_delta = event.relative

func Fire(scale_factor:float,att:int, pos:Vector3,rot:Vector3)->void:
	var projectile_scene = preload("res://Projectile.tscn")
	var projectile = projectile_scene.instantiate()
	projectile.position = pos
	projectile.rotation = rot
	projectile.scale.x=scale_factor
	projectile.scale.y=scale_factor
	projectile.speed=25-(scale_factor*5)
	get_tree().current_scene.add_child(projectile)

	
func _process(delta):
	#footsteps

	#look
	rotate_y(-mouse_delta.x * mouse_sensitivity)
	var x_rot = cam_pivot.rotation.x - mouse_delta.y * mouse_sensitivity
	x_rot = clamp(x_rot, deg_to_rad(-89), deg_to_rad(89))
	cam_pivot.rotation.x = x_rot
	
	mouse_delta = Vector2.ZERO
	#JUMP

	#MAGIC
	if Input.is_action_just_pressed("fire") and not charging and sprite.animation == "Idle":
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
		$Camera3D/MagicLight.light_energy=1+(scale_factor*6)+(sin(charge_time*10)*3)
		
		if Input.is_action_just_released("fire"):
			sprite.animation="Attack01"
			$Shoot.play()
			var local_offset = Vector3(0.7, 1.414, -2.188)
			var spawn_position = self.global_transform.origin + self.global_transform.basis * local_offset

			
			Fire(scale_factor, 1,spawn_position,Vector3(cam_pivot.rotation.x,self.rotation.y,0))

			charging = false
			charge_time = 0.0
			$Camera3D/MagicLight.visible = false
			$Camera3D/EnergyBall.visible=false
			
	
	if is_on_floor():
		
		if Input.is_action_pressed("run"):
			run=2.3
		else:
			run=1.0



func _physics_process(delta):
	var input_dir = Vector2.ZERO
	input_dir.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	input_dir.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	input_dir = input_dir.normalized()

	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y))
	direction.y = 0
	direction = direction.normalized()

	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		if Input.is_action_pressed("jump"):
			velocity.y =25

	velocity.x = direction.x * speed * run
	velocity.z = direction.z * speed * run

	move_and_slide()
	

func _on_animated_sprite_3d_animation_finished() -> void:
	if sprite.animation == "Attack01":
		sprite.animation = "Idle"	
		sprite.play()
