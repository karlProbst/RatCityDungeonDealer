extends Node

var sprites:Array[Node]=[]
@export var animation_interval: float = 0.5
var timers:Array = []

func _ready():
	for c in self.get_children(true):
		var cc = c.get_child(0)
		if cc is AnimatedSprite2D:
			sprites.append(cc)
			
	play_animations_sequentially(sprites,animation_interval)
	new_child(25)
	kill_child(15)
func _stop_start(sprite:Node):
	if is_instance_valid(sprite) and sprite.has_method("play"):
		sprite.play()
func play_animations_sequentially(sprites: Array, interval: float):
	kill_all_timers()  # Clear any existing timers

	for i in range(sprites.size()):
		var sprite = sprites[i]
		sprite.stop()
		var timer = Timer.new()
		add_child(timer)
		timers.append(timer)
		timer.wait_time = i * interval
		timer.one_shot = true
		timer.timeout.connect(_stop_start.bind(sprite))
		timer.start()

func kill_child(n:int=1):

	if sprites.size()==0:
		return
	for i in n:
		var heartscene=preload("res://rigid_heart.tscn")
		var heart_instance = heartscene.instantiate() as RigidBody2D
		add_child(heart_instance)
		heart_instance.global_position=sprites.back().get_parent().global_position
		sprites.back().get_parent().queue_free()
		sprites.pop_back()
		
func new_child(n:int=1):
	for i in n:
		var new_node = self.get_child(0).duplicate()
		add_child(new_node)
		sprites.append(new_node.get_child(0))
	play_animations_sequentially(sprites,animation_interval)

func kill_all_timers():
	for timer in timers:
		if is_instance_valid(timer):
			timer.stop()
			timer.queue_free()
	timers.clear()
