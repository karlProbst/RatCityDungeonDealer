extends Node

@export var rigid_sprite_scene:PackedScene
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
	if (sprite == null) or (text == null):
		printerr("HUD TEXT or SPRITE NOT FOUND!")
		return
	text.text=str(stat_n)
func _stop_start(sprite:Node):
	if is_instance_valid(sprite) and sprite.has_method("play"):
		sprite.play()
func get_stat()->int:
	return stat_n
func change_text(number:int)->String:
	var text_n:=int(text.text)

	text_n+=number
	if text_n>99:
		text_n=99
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
			if rigid_sprite_scene:
				var rigid_instance = rigid_sprite_scene.instantiate()
				add_child(rigid_instance)
				rigid_instance.global_position=sprite.global_position
				if rigid_instance is AnimatedSprite2D:
					rigid_instance.frame=sprite.frame
