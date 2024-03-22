#============================================================
#    Layer Buttons
#============================================================
# - author: zhangxuetu
# - datetime: 2024-03-22 14:30:39
# - version: 4.2.1
#============================================================
class_name LayerButtons
extends VBoxContainer


signal selected_layers()

const META_KEY_ID = "_id"

var _id_to_layer_data : Dictionary = {}
var _selected_layer_ids : Array = []
var _selected_layers : Array = []
var _button_groups : ButtonGroup = ButtonGroup.new()


#============================================================
#  内置
#============================================================
func _init() -> void:
	_button_groups.pressed.connect(
		func(button):
			var id = button.get_meta(META_KEY_ID)
			var data = get_layer_data(id)
			_selected_layers.append(data["node"])
			
			_selected_layer_ids.clear()
			_selected_layer_ids = [id]
			self.selected_layers.emit()
	)


#============================================================
#  自定义
#============================================================
func _create_layer_node(b_name: String) -> Control:
	var button = Button.new()
	button.text = b_name
	button.toggle_mode = true
	button.focus_mode = Control.FOCUS_NONE
	button.button_group = _button_groups
	add_child(button)
	move_child(button, 0)
	return button

func get_selected_layer_ids() -> Array:
	return _selected_layer_ids

func get_layer_data(id: int) -> Dictionary:
	return _id_to_layer_data.get(id, {})

func create_layer(id: int) -> bool:
	if _id_to_layer_data.has(id):
		return false
	# 创建相关数据
	var data : Dictionary = {}
	data["id"] = id
	data["name"] = "Layer %d" % id
	var button = _create_layer_node(data["name"])
	data["node"] = button
	button.set_meta(META_KEY_ID, id)
	# 记录
	_id_to_layer_data[id] = data
	return true

func select_layer(layer_id: int):
	get_layer_data(layer_id)["node"].button_pressed = true

