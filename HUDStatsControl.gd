extends Node

@export var rigid_sprite_scene:PackedScene=preload("res://rigid_heart.tscn")
@export var animation_interval: float = 0.5
var timers:Array = []
var sprite:Node
var text:Node
@export var stat_n:int=5
func _ready():
	for child in self.get_children():
		var cc = child.get_child(0)
		if cc is AnimatedSprite2D:
			sprite=cc
		if cc is RichTextLabel:
			text=cc
	print(text)
	print(sprite)
	if (sprite == null) or (text == null):
		printerr("HUD TEXT or SPRITE NOT FOUND!")
		return
	add_stat(25)
	remove_stat(15)
func _stop_start(sprite:Node):
	if is_instance_valid(sprite) and sprite.has_method("play"):
		sprite.play()

func change_text(number:int)->String:
	var text_n:=int(text.text)
	if number>0:
		if text_n<99:
			text_n+=number
		if text_n>99:
			text_n=99
	elif number<0:
		if text_n>0:
			text_n+=number
		if text_n<0:
			text_n=0
	stat_n=text_n
	return str(text_n)
func add_stat(n:int=1):
	text.text=change_text(n)
func remove_stat(n:int=1):
	for i in n:
		if stat_n>0:
			text.text=change_text(-1)
			var rigid_instance = rigid_sprite_scene.instantiate() as RigidBody2D
			add_child(rigid_instance)
			rigid_instance.global_position=sprite.global_position
