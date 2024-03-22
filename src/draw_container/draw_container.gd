#============================================================
#    Draw Container
#============================================================
# - author: zhangxuetu
# - datetime: 2024-03-22 15:47:49
# - version: 4.2.1
#============================================================
class_name DrawContainer
extends Control


@onready var image_layers: Control = %ImageLayers
@onready var input_board: InputBoard = %InputBoard
@onready var tools: Node = %tools
@onready var move_image_ref: ReferenceRect = %move_image_ref

var _image_rect : Rect2i = Rect2i()
var _stroke_points : Array[Vector2i] = [] # 绘制时的笔触大小
var _id_to_layer_data : Dictionary = {} # ID 对应的层级的数据
var _draw_layer_ids : Array = [] # 绘制时绘制到这些图层上
var _current_tool : ToolBase # 当前使用的工具
var _layer_node_offset_dict : Dictionary = {} # 图层节点已偏移的值
var _queue_draw_data : Dictionary = {} # 准备绘制的数据


#============================================================
#  内置
#============================================================
func _ready() -> void:
	# 图像大小
	ProjectConfig.config_changed.connect(_config_changed)
	var image_size = ProjectConfig.get_config(PropertyName.IMAGE.SIZE, Vector2i(100, 100))
	_config_changed(PropertyName.IMAGE.SIZE, image_size, image_size )
	
	# 笔触
	_stroke_points.append(Vector2i(0, 0))
	# 图层
	create_layer(1)
	move_image_ref.visible = false
	
	# 工具
	for tool:ToolBase in tools.get_children():
		tool.input_board = input_board
	active_tool("pen")


func _process(delta: float) -> void:
	if not _queue_draw_data.is_empty():
		# 绘制到层上
		var image_layer : ImageLayer
		for id in _draw_layer_ids:
			image_layer = get_image_layer(id)
			image_layer.set_color_by_data(_queue_draw_data)
		_queue_draw_data.clear()



#============================================================
#  自定义
#============================================================
func _config_changed(property, last_value, image_size):
	if property == PropertyName.IMAGE.SIZE:
		var max_size : Vector2i 
		if typeof(last_value) != TYPE_NIL:
			max_size = Vector2i(
				max(last_value.x, image_size.x),
				max(last_value.y, image_size.y),
			)
		else:
			max_size = image_size
		
		_image_rect = Rect2i(Vector2i(), max_size)
		custom_minimum_size = max_size
		input_board.custom_minimum_size = max_size
		
		# 更新节点
		var image_layer : ImageLayer
		for data in _id_to_layer_data.values():
			image_layer = data["layer_node"]
			#image_layer.resize(image_size)
		for tool:ToolBase in tools.get_children():
			tool.image_rect = _image_rect


func active_tool(tool_name: String):
	var tool = get_tool(tool_name)
	if tool == _current_tool:
		return
	if _current_tool != null:
		_current_tool.deactive()
	_current_tool = tool
	_current_tool.active()

func get_tool(tool_name: String) -> ToolBase:
	return tools.get_node(tool_name)

func create_layer(id: int):
	if _id_to_layer_data.has(id):
		return
	# 创建相关数据
	var data : Dictionary = {}
	var image_layer = ImageLayer.new()
	image_layer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	image_layer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	image_layers.add_child(image_layer)
	data["id"] = id
	data["layer_node"] = image_layer
	# 记录
	_id_to_layer_data[id] = data

# 添加可绘制到的层
func add_draw_layer(layer_id: int):
	_draw_layer_ids.push_back(layer_id)

# 添加可绘制到的层
func add_draw_layers(layer_ids: Array):
	_draw_layer_ids.append_array(layer_ids)

# 清除可绘制到的层
func clear_draw_layer():
	_draw_layer_ids.clear()

func get_image_layer(id: int) -> ImageLayer:
	return _id_to_layer_data[id]["layer_node"]

func set_image_offset(layer_id: int, pos: Vector2i):
	get_image_layer(layer_id).position = pos

func get_draw_layer_ids() -> Array:
	return _draw_layer_ids

func get_draw_layer_nodes() -> Array[ImageLayer]:
	var list : Array[ImageLayer] = []
	for id in _draw_layer_ids:
		list.append(_id_to_layer_data[id]["layer_node"])
	return list


func draw_by_data(data: Dictionary) -> void:
	# 添加到队列进行绘制，防止卡顿
	_queue_draw_data = data


#============================================================
#  连接信号
#============================================================
func _on_move_ready_move() -> void:
	move_image_ref.position = Vector2(0, 0)
	move_image_ref.size = ProjectConfig.get_config(PropertyName.IMAGE.SIZE)
	move_image_ref.visible = true
	
	# 移动前记录偏移的值
	for image_layer in get_draw_layer_nodes():
		_layer_node_offset_dict[image_layer] = image_layer.position


func _on_move_move_position(last_point: Vector2i, current_point: Vector2i) -> void:
	var offset : Vector2 = Vector2(current_point - input_board.get_last_pressed_point())
	move_image_ref.position = offset


func _on_move_move_finished() -> void:
	move_image_ref.visible = false
	var offset : Vector2 = Vector2(input_board.get_last_release_point() - input_board.get_last_pressed_point())
	for image_layer in get_draw_layer_nodes():
		image_layer.set_offset_colors(offset)

