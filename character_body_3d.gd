extends CharacterBody3D

@export var speed: float = 11.0
@export var mouse_sensitivity: float = 0.002
@export var gravity: float = -9.8
@export var run: float = 1.0

var mouse_delta: Vector2
var firing=false
# Referências
@onready var cam_pivot = $Camera3D
@onready var sprite = $Camera3D/AnimatedSprite3D

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	if event is InputEventMouseMotion:
		mouse_delta = event.relative

func Fire(att:int, pos:Vector3,rot:Vector3)->void:
	var projectile_scene = preload("res://Projectile.tscn")
	var projectile = projectile_scene.instantiate()
	projectile.position = pos
	projectile.rotation = rot
	get_tree().current_scene.add_child(projectile)

	
func _process(_delta):
	
	rotate_y(-mouse_delta.x * mouse_sensitivity)
	var x_rot = cam_pivot.rotation.x - mouse_delta.y * mouse_sensitivity
	x_rot = clamp(x_rot, deg_to_rad(-89), deg_to_rad(89))
	cam_pivot.rotation.x = x_rot
	
	mouse_delta = Vector2.ZERO
	#JUMP

	if firing:
		$MagicLight.visible=true
		sprite.animation="Attack01"
		if sprite.frame==2:
			var local_offset = Vector3(0.7, 1.414, -2.188)
			var spawn_position = self.global_transform.origin + self.global_transform.basis * local_offset
			Fire(1,spawn_position,Vector3(cam_pivot.rotation.x,self.rotation.y,0))
			firing=false
			$MagicLight.visible=false
	if Input.is_action_just_pressed("fire") and not firing and sprite.animation=="Idle":
		firing = true
		
	if is_on_floor():
		if Input.is_action_pressed("run"):
			run=3.5
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
		velocity.y = 0.0

	velocity.x = direction.x * speed * run
	velocity.z = direction.z * speed * run

	move_and_slide()


func _on_animated_sprite_3d_animation_finished() -> void:
	if sprite.animation == "Attack01":
		sprite.animation = "Idle"	
		sprite.play()
