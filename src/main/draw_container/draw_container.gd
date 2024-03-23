#============================================================
#    Draw Container
#============================================================
# - author: zhangxuetu
# - datetime: 2024-03-22 15:47:49
# - version: 4.2.1
#============================================================
## 绘图容器
class_name DrawContainer
extends Control


@onready var image_layers: Control = %ImageLayers
@onready var input_board: InputBoard = %InputBoard
@onready var tools: Tools = %tools
@onready var move_image_ref: ReferenceRect = %move_image_ref

var _image_rect : Rect2i = Rect2i()
var _stroke_points : Array[Vector2i] = [ Vector2i(0,0) ] # 绘制时的笔触大小
var _id_to_layer_node : Dictionary = {} # ID 对应的层级节点
var _current_tool : ToolBase # 当前使用的工具
var _queue_draw_data : Dictionary = {} # 准备绘制的数据


#============================================================
#  内置
#============================================================
func _init() -> void:
	ProjectData.newly_layer.connect(create_layer)
	ProjectData.config_changed.connect(_config_changed)


func _ready() -> void:
	# 图像大小
	var image_size = ProjectData.get_config(PropertyName.IMAGE.SIZE, Vector2i(100, 100))
	_config_changed(PropertyName.IMAGE.SIZE, image_size, image_size )
	
	# 图层
	move_image_ref.visible = false
	
	# 工具
	tools.set_input_board(input_board)
	tools.active_tool("pen")


func _process(delta: float) -> void:
	if not _queue_draw_data.is_empty():
		# 绘制到层上
		var image_layer : ImageLayer
		for layer_id in ProjectData.get_select_layer_ids():
			image_layer = get_image_layer(layer_id)
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
		for tool:ToolBase in tools.get_children():
			tool.image_rect = _image_rect

func active_tool(tool_name: String):
	tools.active_tool(tool_name)

func create_layer(layer_id: int):
	if _id_to_layer_node.has(layer_id):
		return
	# ID对应节点
	var image_layer : ImageLayer = ImageLayer.new()
	image_layer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	image_layer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	image_layer.load_data( ProjectData.get_image_data_by_current_frame(layer_id) )
	image_layers.add_child(image_layer)
	# 记录
	_id_to_layer_node[layer_id] = image_layer

## 获取这个画布层节点
func get_image_layer(layer_id: int) -> ImageLayer:
	return _id_to_layer_node[layer_id]

func get_image_layer_nodes() -> Array[ImageLayer]:
	var list : Array[ImageLayer] = []
	for layer_id in _id_to_layer_node:
		list.append(_id_to_layer_node[layer_id])
	return list

## 更新画布
func update_canvas():
	var frame_id = ProjectData.get_current_frame()
	if frame_id > 0:
		for layer_id in ProjectData.get_layer_ids():
			var image_layer = get_image_layer(layer_id)
			var data = ProjectData.get_image_data(layer_id, frame_id)
			image_layer.load_data(data)

func draw_by_data(data: Dictionary) -> void:
	# 添加到队列进行绘制，防止卡顿
	_queue_draw_data = data



#============================================================
#  连接信号
#============================================================
func _on_move_ready_move() -> void:
	move_image_ref.position = Vector2(0, 0)
	move_image_ref.size = ProjectData.get_config(PropertyName.IMAGE.SIZE)
	move_image_ref.visible = true


func _on_move_move_position(last_point: Vector2i, current_point: Vector2i) -> void:
	var offset : Vector2 = Vector2(current_point - input_board.get_last_pressed_point())
	move_image_ref.position = offset


func _on_move_move_finished() -> void:
	move_image_ref.visible = false
	var offset : Vector2 = Vector2(input_board.get_last_release_point() - input_board.get_last_pressed_point())
	for layer_id in ProjectData.get_select_layer_ids():
		get_image_layer(layer_id).set_offset_colors(offset)

