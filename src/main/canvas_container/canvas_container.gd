#============================================================
#    Canvas Container
#============================================================
# - author: zhangxuetu
# - datetime: 2024-03-22 15:47:49
# - version: 4.2.1
#============================================================
## 绘图容器
class_name CanvasContainer
extends Control


@onready var image_layers: Control = %ImageLayers
@onready var input_board: InputBoard = %InputBoard
@onready var tools: Tools = %tools
@onready var move_image_ref: ReferenceRect = %MoveImageRef
@onready var onionskin: Control = %Onionskin # 洋葱皮节点


var _image_rect : Rect2i = Rect2i()
var _layer_id_to_layer_node : Dictionary = {} # ID 对应的层级节点
var _current_tool : ToolBase # 当前使用的工具


#============================================================
#  内置
#============================================================
func _init() -> void:
	ProjectData.listen_config(PropertyName.IMAGE.RECT, func(last_rect, image_rect):
		if typeof(last_rect) == TYPE_NIL:
			last_rect = Rect2i()
		var last_image_size : Vector2i = last_rect.size
		var image_size : Vector2i = image_rect.size
		var max_size : Vector2i 
		if typeof(last_image_size) != TYPE_NIL:
			max_size = Vector2i(
				max(last_image_size.x, image_size.x),
				max(last_image_size.y, image_size.y),
			)
		else:
			max_size = image_size
		
		_image_rect = Rect2i(Vector2i(), max_size)
		custom_minimum_size = max_size
		input_board.custom_minimum_size = max_size
		
		# 更新节点
		for tool:ToolBase in tools.get_children():
			tool.image_rect = _image_rect
	)
	ProjectData.listen_config(PropertyName.TOOL.CURRENT, func(last, current):
		tools.active_tool(current)
	)
	ProjectData.new_file.connect(
		func():
			for layer_id in _layer_id_to_layer_node:
				_layer_id_to_layer_node[layer_id].queue_free()
			_layer_id_to_layer_node.clear()
			tools.active_tool(PropertyName.TOOL.PEN)
	)
	ProjectData.newly_layer.connect(create_layer, Object.CONNECT_DEFERRED)
	ProjectData.removed_layer.connect(
		func(layer_id):
			_layer_id_to_layer_node[layer_id].visible = false
	)


func _ready() -> void:
	# 图层
	move_image_ref.visible = false
	# 工具
	tools.set_input_board(input_board)
	tools.active_tool(PropertyName.TOOL.PEN)


#============================================================
#  自定义
#============================================================
func create_layer(layer_id: float):
	if _layer_id_to_layer_node.has(layer_id):
		return
	# ID对应节点
	var image_layer : ImageLayer = ImageLayer.new()
	image_layer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	image_layer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	image_layer.load_data( layer_id, ProjectData.get_current_frame_id() )
	image_layers.add_child(image_layer)
	# 记录
	_layer_id_to_layer_node[layer_id] = image_layer

## 获取这个画布层节点
func get_image_layer(layer_id: float) -> ImageLayer:
	return _layer_id_to_layer_node[layer_id]

## 获取所有画布节点
func get_image_layer_nodes() -> Array[ImageLayer]:
	return Array(_layer_id_to_layer_node.values(), TYPE_OBJECT, "Control", ImageLayer)

## 更新画布
func update_canvas():
	var frame_id = ProjectData.get_current_frame_id()
	if frame_id > 0:
		for layer_id in ProjectData.get_layer_ids():
			var image_layer = get_image_layer(layer_id)
			var data = ProjectData.get_image_data(layer_id, frame_id)
			image_layer.load_data( layer_id, frame_id )


var _queue_draw_data : Dictionary
var _queue_draw_data_status : bool = false
## 根据数据绘制
func draw_by_data(data: Dictionary) -> void:
	# 添加到绘制队列，不进行实时绘制，防止卡顿
	_queue_draw_data = data
	if _queue_draw_data_status:
		return
	_queue_draw_data_status = true
	await Engine.get_main_loop().process_frame
	# 绘制
	for layer_id in ProjectData.get_select_layer_ids():
		get_image_layer(layer_id).draw_color_by_data(_queue_draw_data)
	_queue_draw_data_status = false


## 根据 Texture2D 绘制
func draw_by_texture(texture: Texture2D) -> void:
	# 绘制
	for layer_id in ProjectData.get_select_layer_ids():
		get_image_layer(layer_id).draw_color_by_texture(texture)


#============================================================
#  连接信号
#============================================================
func _on_move_ready_move() -> void:
	move_image_ref.position = Vector2(0, 0)
	move_image_ref.size = ProjectData.get_config(PropertyName.IMAGE.RECT).size
	move_image_ref.visible = true


func _on_move_move_position(last_point: Vector2i, current_point: Vector2i) -> void:
	var offset : Vector2 = Vector2(current_point - input_board.get_last_pressed_point())
	move_image_ref.position = offset


func _on_move_move_finished() -> void:
	move_image_ref.visible = false
	var offset : Vector2 = Vector2(input_board.get_last_release_point() - input_board.get_last_pressed_point())
	if offset != Vector2.ZERO:
		for layer_id in ProjectData.get_select_layer_ids():
			get_image_layer(layer_id).set_offset_colors(offset)


# 当前画板的颜色
func _get_draw_colors_data() -> Dictionary:
	var colors_data = {}
	# 记录绘制前的颜色数据
	for layer_id in ProjectData.get_select_layer_ids():
		colors_data[layer_id] = {}
		for frame_id in ProjectData.get_frame_ids():
			var data = ProjectData.get_image_data(layer_id, frame_id)
			var colors = data[PropertyName.KEY.COLORS] as Dictionary
			colors_data[layer_id][frame_id] = colors.duplicate()
	return colors_data

# 当前层级对应的图片
func _get_current_layer_textures() -> Dictionary:
	var layer_id_to_textures = {}
	for layer_id in ProjectData.get_select_layer_ids():
		var texture = get_image_layer(layer_id).get_image_texture()
		layer_id_to_textures[layer_id] = texture.duplicate()
	return layer_id_to_textures


var _layer_id_to_before_colors : Dictionary = {}
var _layer_id_to_before_texture : Dictionary = {}

func draw_colors_data(colors_data: Dictionary, execute: bool = false):
	var layer_id_to_textures = _get_current_layer_textures()
	var current_frame_id = ProjectData.get_current_frame_id()
	var select_layer_ids = ProjectData.get_select_layer_ids()
	ProjectData.add_undo_redo(
		"绘制",
		__draw_colors.bind(colors_data, layer_id_to_textures, current_frame_id, select_layer_ids),
		__draw_colors.bind(_layer_id_to_before_colors.duplicate(), _layer_id_to_before_texture.duplicate(), current_frame_id, select_layer_ids),
		execute
	)

func __draw_colors(colors_data, layer_id_to_textures, current_frame_id, select_layer_ids):
	var colors : Dictionary
	for layer_id in colors_data:
		var frame_data : Dictionary = colors_data[layer_id]
		draw_by_data(colors_data[layer_id][current_frame_id])
		for frame_id in frame_data:
			colors = frame_data[frame_id]
			ProjectData.update_image_colors(layer_id, frame_id, colors)
	for layer_id in select_layer_ids:
		ProjectData.update_texture( layer_id, current_frame_id, layer_id_to_textures[layer_id])
		var image_layer : ImageLayer = get_image_layer(layer_id)
		image_layer.load_data(layer_id, current_frame_id)


func _ready_draw() -> void:
	grab_focus()
	# 绘制前的数据
	_layer_id_to_before_colors = _get_draw_colors_data()
	_layer_id_to_before_texture = _get_current_layer_textures()


func _draw_finished() -> void:
	draw_colors_data( _get_draw_colors_data())


func _on_line_released(colors) -> void:
	var data = {}
	var frame_id = ProjectData.get_current_frame_id()
	for layer_id in ProjectData.get_select_layer_ids():
		data[layer_id] = {
			frame_id: colors
		}
	draw_colors_data(data, true)
