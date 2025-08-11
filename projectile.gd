extends Node3D

@export var speed: float = 30.0
@export var life_time: float = 30.0  # tempo para desaparecer
@export var damage:int=25
var life_timer: float = 0.0
var exploding=false
func _ready():
	$Light.light_energy=scale.x*150
	$SplashSound.pitch_scale = 1.8 / scale.x

func _physics_process(delta):
	if exploding:
		if $Splash/OmniLight3D.light_energy>0:
			$Splash/OmniLight3D.light_energy *= pow(0.0005, delta) 

		else:
			$Splash/OmniLight3D.light_energy=0
	# Move para frente local (eixo -Z)
	translate(Vector3(0, 0, -speed * delta))
	
	# Timer para destruir depois de um tempo
	life_timer += delta
	if life_timer >= life_time:
		queue_free()

func _on_body_entered(body):
	var damage = 26.47 * scale.x - 2.94
	damage = max(damage, 0)
	if body.has_method("projectile_hit"):
		body.projectile_hit(damage)
	Explode()

func Explode()->void:
	if speed>0:
		exploding=true
		$Splash/OmniLight3D.light_energy=70*scale.x
		$AnimatedSprite3D.visible=false
		$Splash.visible=true
		$Splash.play("default")
		$Splash/AnimationPlayer.play("lightFade")
		$SplashSound.play()
		$Light.visible=false
		
	speed=0.0
	
	
func _on_area_entered(area: Area3D) -> void:
	Explode()


func _on_area_shape_entered(area_rid: RID, area: Area3D, area_shape_index: int, local_shape_index: int) -> void:
	Explode()


func _on_splash_animation_finished() -> void:
	queue_free()
