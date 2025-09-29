@tool
extends Control

@export var item_data: ItemResource:
	set(value):
		item_data = value
		_update_visual()
@onready var icon_node = get_node_or_null("Panel/TextureRect")
@onready var label_node = get_node_or_null("Label")
@export var force_update: bool = false:
	set(value):
		force_update = false   # always reset so checkbox unchecks itself
		_update_visual()



func _ready() -> void:
	if item_data:
		set_item_data(item_data)
	
func set_item_data(data: ItemResource) -> void:
	var resource = data.duplicate(true)
	if resource:
		item_data = resource
	_update_visual()
	#remove later
	if item_data.id==10000:
		$Panel/TextureRect.texture.noise.seed=randi_range(1,9999)
		$Panel/TextureRect.texture.noise.noise_type=randi_range(0,5)
		
		
func clear_item() -> void:
	item_data = null
	_update_visual()

func _update_visual()->void:
	if item_data==null:
		if icon_node:
			icon_node.texture=null
		label_node.visible=false
		label_node.text = "0"
		return 
	# Atualiza o ícone
	if icon_node:
		icon_node.texture = item_data.icon
	# Atualiza o stack label
	if label_node:
		if item_data.stackable and item_data.stack >= 0:
			label_node.visible = true
			label_node.text = str(item_data.stack)
		else:
			label_node.visible=false

# -------------------
# DRAG & DROP
# -------------------

func _get_drag_data(_position):
	print(_position)
	if item_data == null:
		return null
	
	# Criar preview visual enquanto arrasta
	var preview = TextureRect.new()
	preview.texture = item_data.icon
	preview.expand = true
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	set_drag_preview(preview)

	return item_data

func _can_drop_data(_pos, data):
	return data is ItemResource

func _drop_data(_pos, data):
	if data == null:
		return
	
	# Pega o InventoryManager acima para lidar com a troca
	var manager = get_parent().get_node("InventoryController") # supondo que os slots estão em GridContainer -> Manager
	if manager and manager.has_method("handle_drop"):
		manager.handle_drop(self, data)

			
