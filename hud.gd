extends Node
@onready var menu_node:Node = $Menu 
var is_paused = false
var master_bus_index = AudioServer.get_bus_index("Master")
var is_muted:bool = true
func _ready():
	Engine.time_scale = 1.0
	menu_node.visible=false
func _input(event):
	if event.is_action_pressed("ui_cancel"): # "ui_cancel" is usually bound to Esc
		toggle_pause()

func toggle_pause():
	is_paused = not is_paused
	if is_paused:
		Engine.time_scale = 0.0
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		menu_node.visible=true
	else:
		menu_node.visible=false
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		Engine.time_scale = 1.0
		
		


func _on_mute_b_pressed() -> void:
	if is_muted:
		AudioServer.set_bus_mute(master_bus_index, false)
		is_muted = false
	else:
		AudioServer.set_bus_mute(master_bus_index, true)
		is_muted = true

func _on_exit_b_pressed() -> void:
	get_tree().quit()
