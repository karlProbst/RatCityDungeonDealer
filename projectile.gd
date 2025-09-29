extends Node3D

@export var speed: float = 30.0
@export var life_time: float = 100.0  # tempo para desaparecer
@export var damage:int=25
var life_timer: float = 0.0
var exploding=false
var father:Node
var target:Node
var distance_to_explode=120
var _angle = 0.0
@onready var ray = get_node_or_null("Laserray")
var radius_scale = 0.03    
var radius = 0
var spin_speed =9.5 

func _ready():
	radius = radius_scale / (scale.x*1.35)
	spin_speed/=scale.x
	var light = get_node_or_null("Light")
	var particles=get_node_or_null("CPUParticles3D")
	if particles:
		var material = particles.get_mesh()
		if material:

			var sc=scale.x/3
			material.size=Vector3(sc,sc,sc)
			particles.set_mesh(material)
	if light:
		light.light_energy=scale.x*150
	$SplashSound.pitch_scale = 1.8 / scale.x
	var min_scale = 0.3
	var max_scale = 3.0
	var min_damage = 10
	var max_damage = 40
	damage = lerp(min_damage, max_damage, (scale.x - min_scale) / (max_scale - min_scale))
func set_target(_target:Node3D,offset:Vector3=Vector3.ZERO,dir:Vector3=Vector3.ZERO)->void:
	target = _target
	if dir==Vector3.ZERO:
		self.look_at(target.global_position+offset)
	else:
		self.look_at(dir+offset)
	
func _process(delta: float) -> void:
	if Engine.time_scale == 0.0:
		return
	if ray != null:
		if ray.is_colliding():
			var collider = ray.get_collider()
			if collider:
				if collider.is_in_group("Enemy"):
					if collider.has_method("prepare_dodge"):
						var forward = -transform.basis.z.normalized()
						collider.prepare_dodge(-speed,forward,global_position)
	var dist = 1
	if father:
		dist = global_position.distance_to(father.global_position)
	if dist>distance_to_explode:
		Explode()
	if exploding:
		if $Splash/OmniLight3D.light_energy>0:
			$Splash/OmniLight3D.light_energy *= pow(0.000005, delta) 
		else:
			$Splash/OmniLight3D.light_energy=0				
func _physics_process(delta):
	
	if Engine.time_scale == 0.0:
		return
		
	_angle += spin_speed * delta 

	# Calculate perpendicular offset
	var offset = Vector3(
		radius * cos(_angle),
		radius * sin(_angle),
		0
	)
	# Move forward along local z and add the circular offset
	translate(Vector3(0, 0, -speed * delta) + offset)	

	
	# Timer para destruir depois de um tempo
	life_timer += delta
	if life_timer >= life_time:
		Explode()

func emmit_blood():
	var bloodmanager = get_node_or_null("BloodManager")
	if not bloodmanager:
		return
	var rot = self.global_rotation
	bloodmanager.spawn_blood(global_position,rot)
func _on_body_entered(body):

	if global_position.is_finite():
		if body!=father:
			if self.collision_layer!=0:
				if body.has_method("projectile_hit"):
					body.projectile_hit(damage)
					emmit_blood()
				if body==target:
					if body.has_method("apply_knockback"):
						emmit_blood()
						var direction = (body.global_position - global_position).normalized()
						var knockback_strength = 35.0
						direction.y = 0.1
						direction = direction.normalized() 
						var nod=self
						if father:
							nod=father
						body.apply_knockback(direction * knockback_strength,nod)
			Explode()
	else:
		print(str(self)+" BUGGED FUCKED")
		queue_free()

func Explode()->void:
	self.collision_layer = 0
	self.collision_mask = 0
	if father:
		if father.has_method("remove_from_projectiles"):
			father.remove_from_projectiles(self)
	
	if speed>0:
		exploding=true
		
		$AnimatedSprite3D.visible=false
		$Splash/OmniLight3D.light_energy=70*scale.x
		$Splash.visible=true
		$Splash.play("default")
		$Splash/AnimationPlayer.play("lightFade")
		$SplashSound.play()
		if $Light:
			$Light.visible=false
	speed=0.0
	
	
func _on_area_entered(_area: Area3D) -> void:
	Explode()


func _on_splash_animation_finished() -> void:
	queue_free()
