#============================================================
#    Layer Buttons
#============================================================
# - author: zhangxuetu
# - datetime: 2024-03-22 14:30:39
# - version: 4.2.1
#============================================================
class_name LayerButtons
extends VBoxContainer


const META_KEY_ID = "_id"

var _id_to_layer_data : Dictionary = {}
var _selected_layers : Array = []
var _button_groups : ButtonGroup = ButtonGroup.new()


#============================================================
#  内置
#============================================================
func _init() -> void:
	_button_groups.pressed.connect(
		func(button):
			var id = button.get_meta(META_KEY_ID)
			ProjectData.clear_select_layer()
			ProjectData.add_select_layers([id])
	)
	ProjectData.newly_layer.connect(create_layer)
	ProjectData.select_layers_changed.connect(
		func():
			var layers_ids = ProjectData.get_select_layer_ids()
			for layer_id in _id_to_layer_data:
				var button : BaseButton = _id_to_layer_data[layer_id]["node"]
				if layers_ids.has(layer_id):
					if not button.button_pressed:
						button.button_pressed = true
				else:
					button.button_pressed = false
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
	ProjectData.add_select_layer(layer_id)

