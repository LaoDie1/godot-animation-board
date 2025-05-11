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
@onready var line: Line2D = %Line
@onready var canvas: Control = %Canvas
@onready var canvas_border: ReferenceRect = %CanvasBorder
@onready var canvas_zoom_label: Label = %CanvasZoomLabel
@onready var background_panel: ColorRect = %BackgroundPanel
@onready var canvas_margin_container: MarginContainer = %CanvasMarginContainer


var _last_size : Vector2 = Vector2()
var _image_rect : Rect2i = Rect2i()
var _layer_id_to_layer_node : Dictionary = {} # ID 对应的层级节点
var _current_tool : ToolBase # 当前使用的工具
var _middle_pressed_mouse_pos : Vector2 = Vector2(-1, -1) # 中键按下时的鼠标位置
var _middle_pressed_canvas_pos : Vector2 = Vector2() # 中键按下时画布所在位置
var _last_canvas_zoom_change_time = 0 # 上次画布缩放时的时间


#============================================================
#  内置
#============================================================
func _init() -> void:
	ProjectData.listen_config(PropertyName.KEY.CANVAS_BACKGROUND_COLOR, func(last, curr):
		background_panel.color = curr
	)
	ProjectData.listen_config(PropertyName.KEY.IMAGE_RECT, func(last_rect, image_rect):
		if typeof(last_rect) == TYPE_NIL:
			last_rect = Rect2i()
		var last_image_size : Vector2i = last_rect.size
		var image_size : Vector2i = image_rect.size
		
		_image_rect = Rect2i(Vector2i(), image_size)
		input_board.custom_minimum_size = image_size
		input_board.size = image_size
		canvas_margin_container.custom_minimum_size = image_size
		canvas_margin_container.size = image_size
		
		# 更新节点
		for tool:ToolBase in tools.get_children():
			tool.image_rect = _image_rect
		
	)
	ProjectData.listen_config(PropertyName.KEY.CURRENT_TOOL, func(last, curr: String):
		match curr.to_lower():
			"move":
				input_board.mouse_default_cursor_shape = Control.CURSOR_MOVE
			_:
				input_board.mouse_default_cursor_shape = Control.CURSOR_ARROW
		
	)
	ProjectData.newly_file.connect(
		func():
			for layer_id in _layer_id_to_layer_node:
				_layer_id_to_layer_node[layer_id].queue_free()
			_layer_id_to_layer_node.clear()
	)
	ProjectData.newly_layer.connect(create_layer, Object.CONNECT_DEFERRED)
	ProjectData.removed_layer.connect(
		func(layer_id):
			_layer_id_to_layer_node[layer_id].visible = false
	)
	ProjectData.listen_config(PropertyName.KEY.CANVAS_ZOOM, func(last, canvas_zoom):
		var last_pos = canvas.get_local_mouse_position()
		canvas.scale = ProjectData.get_canvas_scale()
		canvas_border.border_width = pow(1.25, -canvas_zoom ) * 4
		canvas_zoom_label.text = str(canvas_zoom)
		
		# 位置偏移。正确偏移到鼠标位置的点
		var current_pos = canvas.get_local_mouse_position()
		var offset = current_pos - last_pos
		if offset > canvas.size:
			offset = canvas.size
		canvas.position += offset * canvas.scale
	)


func _ready() -> void:
	# 图层
	move_image_ref.visible = false
	# 工具
	tools.set_input_board(input_board)
	# 画布缩放
	ProjectData.set_config(PropertyName.KEY.CANVAS_ZOOM, 0)
	
	await Engine.get_main_loop().process_frame
	# 画布重定位
	_last_size = self.size
	resized.connect(
		func():
			var v = (self.size / _last_size)
			_last_size = self.size
	)


func _gui_input(event: InputEvent) -> void:
	# 缩放拖动画布
	if event is InputEventMouseMotion:
		if _middle_pressed_mouse_pos != Vector2(-1, -1):
			var diff = get_local_mouse_position() - _middle_pressed_mouse_pos
			canvas.position = _middle_pressed_canvas_pos + diff
	
	elif event is InputEventMouseButton:
		if event.pressed:
			var dir = 0
			match event.button_index:
				MOUSE_BUTTON_WHEEL_DOWN: 
					dir = 1
				MOUSE_BUTTON_WHEEL_UP: 
					dir = -1
				MOUSE_BUTTON_MIDDLE: 
					_middle_pressed_mouse_pos = get_local_mouse_position()
					_middle_pressed_canvas_pos = canvas.position
			
			if dir != 0:
				# 缩放间隔时间需要超过 0.02 秒
				if Time.get_ticks_msec() - _last_canvas_zoom_change_time > 20:
					var canvas_zoom : float = ProjectData.get_config(PropertyName.KEY.CANVAS_ZOOM, 1)
					var new_zoom = clampf(canvas_zoom - sign(dir), -20, 20) # 缩放范围 20
					if new_zoom != canvas_zoom:
						ProjectData.set_config(PropertyName.KEY.CANVAS_ZOOM, new_zoom)
						_last_canvas_zoom_change_time = Time.get_ticks_msec()
				
		else:
			_middle_pressed_mouse_pos = Vector2(-1, -1)
		


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



#============================================================
#  绘制
#============================================================
var _queue_draw_data : Dictionary
var _queue_draw_data_state : bool = false
## 根据数据绘制
func draw_by_data(data: Dictionary) -> void:
	# 添加到绘制队列，不进行实时绘制，防止卡顿
	_queue_draw_data = data
	if _queue_draw_data_state:
		return
	_queue_draw_data_state = true
	await Engine.get_main_loop().process_frame
	# 绘制
	for layer_id in ProjectData.get_select_layer_ids():
		get_image_layer(layer_id).draw_color_by_data(_queue_draw_data)
	_queue_draw_data_state = false


## 根据 Texture2D 绘制
func draw_by_texture(texture: Texture2D) -> void:
	# 绘制
	for layer_id in ProjectData.get_select_layer_ids():
		get_image_layer(layer_id).draw_color_by_texture(texture)



#============================================================
#  撤销重做绘制
#============================================================
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

# 绘制颜色数据。这个会记录修改后的数据，所以调用前先修改好数据在调用这个方法
func draw_colors_data(colors_data: Dictionary):
	var layer_id_to_textures = _get_current_layer_textures()
	var current_frame_id = ProjectData.get_current_frame_id()
	var select_layer_ids = ProjectData.get_select_layer_ids()
	ProjectData.add_undo_redo(
		"绘制",
		__draw_colors.bind(colors_data.duplicate(), layer_id_to_textures, current_frame_id, select_layer_ids),
		__draw_colors.bind(_layer_id_to_before_colors.duplicate(), _layer_id_to_before_texture.duplicate(), current_frame_id, select_layer_ids),
		false
	)


func __draw_colors(colors_data, layer_id_to_textures, current_frame_id, select_layer_ids):
	var colors : Dictionary
	for layer_id in colors_data:
		var frame_data : Dictionary = colors_data[layer_id]
		draw_by_data(frame_data[current_frame_id])
		for frame_id in frame_data:
			colors = frame_data[frame_id]
			ProjectData.update_image_colors(layer_id, frame_id, colors)
	for layer_id in select_layer_ids:
		ProjectData.update_texture( layer_id, current_frame_id, layer_id_to_textures[layer_id])
		var image_layer : ImageLayer = get_image_layer(layer_id)
		image_layer.load_data(layer_id, current_frame_id)



#============================================================
#  连接信号
#============================================================
func _on_move_ready_move() -> void:
	move_image_ref.position = canvas.position
	move_image_ref.size = ProjectData.get_config(PropertyName.KEY.IMAGE_RECT).size
	move_image_ref.visible = true


func _on_move_move_position(last_point: Vector2, current_point: Vector2) -> void:
	var offset : Vector2 = (current_point - input_board.get_last_pressed_point()).floor()
	move_image_ref.position = offset


func _on_move_move_finished() -> void:
	move_image_ref.visible = false
	var offset : Vector2 = Vector2(input_board.get_last_release_point() - input_board.get_last_pressed_point())
	if offset != Vector2.ZERO:
		for layer_id in ProjectData.get_select_layer_ids():
			get_image_layer(layer_id).set_offset_colors(offset)


func _ready_draw() -> void:
	grab_focus()
	
	line.points = [get_local_mouse_position()]
	line.width = ProjectData.get_config(PropertyName.LINE.WIDTH, 1)
	
	# 绘制前的数据（这之后，可以随意图像操作的数据，撤销后即会还原为绘制前的数据）
	_layer_id_to_before_colors = _get_draw_colors_data()
	_layer_id_to_before_texture = _get_current_layer_textures()


func _draw_finished() -> void:
	draw_colors_data( _get_draw_colors_data())


func _on_line_moved(last_point: Vector2, current_point: Vector2) -> void:
	line.visible = true
	line.points = [
		input_board.get_last_pressed_point(), current_point
	]


func _on_line_released(colors: Dictionary) -> void:
	var data = {}
	var frame_id = ProjectData.get_current_frame_id()
	for layer_id in ProjectData.get_select_layer_ids():
		ProjectData.add_image_colors(layer_id, frame_id, colors)
		data[layer_id] = {
			frame_id: colors
		}
	draw_colors_data(data)
	line.visible = false


func _on_reset_canvas_zoom_button_pressed() -> void:
	var pos = canvas.position
	ProjectData.set_config(PropertyName.KEY.CANVAS_ZOOM, 0)
	canvas.position = pos
