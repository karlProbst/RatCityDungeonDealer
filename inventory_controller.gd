extends Node

var slots: Array[Control] = []
var highlighted: Control = null
var dragging: Control = null
@export var grid:Node
@export var dragnode:Control
func _ready():
	# pega todos os slots do GridContainer
	dragnode.visible=false
	for child in grid.get_children():
		if child.has_method("set_item_data"): # simples checagem
			slots.append(child)
func handle_highlight() -> Node:
	var mouse_pos = get_viewport().get_mouse_position()
	var new_highlight: Control = null

	for slot in slots:
		if slot.get_global_rect().has_point(mouse_pos):
			# mouse is hovering this slot
			if slot.has_node("Highlight"):
				slot.get_node("Highlight").visible = true
			new_highlight = slot
		else:
			if slot.has_node("Highlight"):
				slot.get_node("Highlight").visible = false

	highlighted = new_highlight
	return highlighted
	
func _process(delta: float) -> void:
	
	highlighted = handle_highlight()
	if highlighted:
		if Input.is_action_just_pressed("fire") and highlighted.item_data!=null:
			dragging = highlighted

	if dragging:
		if dragnode.visible==false:
			dragnode.get_node("Panel/TextureRect").texture = dragging.item_data.icon
			dragnode.global_position = get_viewport().get_mouse_position()
			dragnode.visible=true
		else:
			dragnode.global_position = get_viewport().get_mouse_position()
	if not Input.is_action_pressed("fire"):
		if dragging:
			var mouse_pos = get_viewport().get_mouse_position()
			for slot in slots:
				if slot.get_global_rect().has_point(mouse_pos):
					
					handle_drop(slot,dragging.item_data)
			dragnode.get_node("Panel/TextureRect").texture=null
			dragnode.visible=false
			dragging = null
			
# ------------------------------------
# Lógica de drag & drop centralizada
# ------------------------------------

func handle_drop(target_slot, item: ItemResource):
	var source_slot = _find_slot_with_item(item)
	if source_slot == null or source_slot == target_slot:
		return
	
	# Caso o item seja stackable e seja o mesmo ID, empilha
	if target_slot.item_data and target_slot.item_data.id == item.id and item.stackable:
		var space_left = target_slot.item_data.MAX_STACK - target_slot.item_data.stack
		var to_move = min(space_left, item.stack)

		target_slot.item_data.stack += to_move
		source_slot.item_data.stack -= to_move

		# se o source zerou, limpa
		if source_slot.item_data.stack <= 0:
			source_slot.clear_item()

		target_slot._update_visual()
		source_slot._update_visual()
		return

	# Caso contrário, troca os itens
	var temp = target_slot.item_data
	target_slot.set_item_data(item)
	if temp:
		source_slot.set_item_data(temp)
	else:
		source_slot.clear_item()


func _find_slot_with_item(item: ItemResource):
	for slot in slots:
		if slot.item_data == item:
			return slot
	return null


# ------------------------------------
# Funções auxiliares de inventário
# ------------------------------------

func add_item(item: ItemResource) -> bool:
	# tenta empilhar primeiro
	for slot in slots:
		if slot.item_data and slot.item_data.id == item.id and item.stackable:
			var space_left = slot.item_data.MAX_STACK - slot.item_data.stack
			if space_left > 0:
				var to_add = min(space_left, item.stack)
				slot.item_data.stack += to_add
				item.stack -= to_add
				slot._update_visual()
				if item.stack <= 0:
					return true
	# se sobrar, procura slot vazio
	for slot in slots:
		if slot.item_data == null:
			slot.set_item_data(item)
			return true
	return false

func remove_item(id: int, amount: int=1) -> bool:
	for slot in slots:
		if slot.item_data and slot.item_data.id == id:
			if slot.item_data.stack >= amount:
				slot.item_data.stack -= amount
				if slot.item_data.stack <= 0:
					slot.clear_item()
				slot._update_visual()
				return true
	return false

func get_item(slot_index: int) -> ItemResource:
	if slot_index >= 0 and slot_index < slots.size():
		return slots[slot_index].item_data
	return null
