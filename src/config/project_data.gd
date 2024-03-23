#============================================================
#    Project Data
#============================================================
# - author: zhangxuetu
# - datetime: 2024-03-22 16:26:16
# - version: 4.2.1
#============================================================
## 项目数据
##
##这里统一处理整个项目的数据
extends Node


## 缩略图大小
const THUMBNAILS_SIZE = Vector2i(40, 40)
## 默认数值
const DEFAULT_INT = -10000000


#============================================================
#  内置
#============================================================
func _init() -> void:
	init_property_name()


#============================================================
#  配置相关
#============================================================
## 配置发生改变
signal config_changed(property:String, last_value, value)


var _config_data: Dictionary = {} # 配置数据
var _listen_property_callback: Dictionary = {} # 监听属性改变

func set_config(property: String, value):
	var last_value = _config_data.get(property)
	if typeof(last_value) != typeof(value) or last_value != value:
		_config_data[property] = value
		if _listen_property_callback.has(property):
			for method:Callable in _listen_property_callback[property]:
				method.call(last_value, value)
		config_changed.emit(property, last_value, value)

func get_config(property, default = null):
	if _config_data.has(property):
		return _config_data[property]
	else:
		_config_data[property] = default
		return default

## 监听这个属性的改变。监听的方法需要有两个参数，一个接收修改前的值，一个为当前的值
func listen_property(property: String, method: Callable):
	if not _listen_property_callback.has(property):
		_listen_property_callback[property] = []
	_listen_property_callback[property].append(method)


## 更新 PropertyName 子类的静态变量的值为自身的名称
static func init_property_name():
	var class_regex = RegEx.new()
	class_regex.compile("^class\\s+(?<class_name>\\w+)\\s*:")
	var var_regex = RegEx.new()
	var_regex.compile("\\s+static\\s+var\\s+(?<var_name>\\w+)")
	
	# 分析
	var script = (PropertyName as GDScript)
	var data : Dictionary = {}
	var last_class : String = ""
	var last_var_list : Array
	var lines = script.source_code.split("\n")
	var result : RegExMatch
	for line in lines:
		result = class_regex.search(line)
		if result:
			# 类名
			last_class = result.get_string("class_name")
			last_var_list =[]
			data[last_class] = last_var_list
		else:
			# 变量名
			if last_class != "":
				result = var_regex.search(line)
				if result:
					var var_name = result.get_string("var_name")
					last_var_list.append(var_name)
	
	# 设置值
	var const_map = script.get_script_constant_map()
	var object : Object
	for c_name:String in data:
		object = const_map[c_name].new()
		var property_list = data[c_name]
		for property:String in property_list:
			object[property] = StringName("/" + c_name.to_lower() + "/" + property.to_lower())

var _size_to_stroke_points : Dictionary = {}

## 获取笔触点
func get_stroke_points(size: int) -> Array:
	if not _size_to_stroke_points.has(size):
		var points : Array = []
		var point : Vector2i = Vector2i()
		for x in range(-size, size+1):
			point.x = x
			for y in range(-size, size+1):
				point.y = y
				if point.length() < size:
					points.append(point)
		_size_to_stroke_points[size] = points
	return _size_to_stroke_points[size]


#============================================================
#  项目数据
#============================================================
signal newly_layer(layer_id: float)
signal newly_frame(frame_id: float)
signal removed_layer(layer_id: float)
signal removed_frame(frame_id: float)
signal frame_changed(last_frame_id: float, frame_id: float)
signal texture_changed(layer_id: float, frame_id: float)
signal select_layers_changed()


var _auto_incr_layer_id : float = 0
var _auto_incr_frame_id : float = 0
var _frame_ids : Array = [] # 可用的帧 ID 列表（用于确定显示的 frame 顺序的，不要修改数据类型）
var _layer_ids : Array = [] # 可用的层 ID 列表（用于确定显示的 frame 顺序的，不要修改数据类型）
var _current_frame_point : int = 0 # 当前帧在 _frame_ids 中的位置
var _layer_frame_to_image_data : Dictionary = {} # 层级对应的帧的图像数据
var _selected_layer_ids : Dictionary = {} # 选中的层级
var _id_to_thumbnails : Dictionary = {} # id对应的缩略图


## 获取图像数据
func get_image_data(layer_id: float, frame_id: float) -> Dictionary:
	return _layer_frame_to_image_data[layer_id][frame_id]

## 获取图像贴图
func get_image_texture(layer_id: float, frame_id: float) -> ImageTexture:
	var data : Dictionary = get_image_data(layer_id, frame_id)
	return data[PropertyName.KEY.TEXTURE]

## 获取这个图像的颜色
func get_image_colors(layer_id: float, frame_id: float) -> Dictionary:
	var data : Dictionary = get_image_data(layer_id, frame_id)
	return data[PropertyName.KEY.COLORS]

func update_image_colors(layer_id: float, frame_id: float, colors: Dictionary):
	var data : Dictionary = get_image_data(layer_id, frame_id)
	data[PropertyName.KEY.COLORS] = colors

func get_max_layer_id() -> float:
	return _auto_incr_layer_id

func get_max_frame_id() -> float:
	return _auto_incr_frame_id

## 获取所有图层ID
func get_layer_ids() -> Array:
	return _layer_ids

## 获取所有帧ID
func get_frame_ids() -> Array:
	return _frame_ids

## 获取动画帧数
func get_frame_id_count() -> int:
	return _frame_ids.size()

func has_frame(frame_id: float) -> bool:
	return _frame_ids.has(frame_id)

## 新的图层
func new_layer(layer_id: float = DEFAULT_INT, insert_layer_front: float = DEFAULT_INT) -> float:
	if _layer_ids.has(layer_id):
		push_error("已添加过这个ID的图层")
		return layer_id
	
	if layer_id == DEFAULT_INT:
		if insert_layer_front == DEFAULT_INT:
			_auto_incr_layer_id += 1
			layer_id = _auto_incr_layer_id
		else:
			var map = {}
			for id in _layer_ids:
				map[id] = null
			layer_id = insert_layer_front - 1
			while true:
				layer_id += 0.001
				if not map.has(layer_id):
					break
	
	if insert_layer_front == DEFAULT_INT:
		_layer_ids.append(layer_id)
	else:
		var id = _layer_ids.find(insert_layer_front)
		_layer_ids.insert(id, layer_id)
	
	# 对应层级数据
	if not _layer_frame_to_image_data.has(layer_id):
		_layer_frame_to_image_data[layer_id] = {}
	for frame_id in get_frame_ids():
		new_texture(layer_id, frame_id)
	
	# 发出信号
	newly_layer.emit(layer_id)
	return layer_id

## 移除图层
func remove_layer(layer_id: float) -> bool:
	var idx = _layer_ids.find(layer_id)
	if idx != -1:
		_layer_ids.remove_at(idx)
		removed_layer.emit(layer_id)
		return true
	return false

## 新的动画帧
func new_frame(frame_id = DEFAULT_INT, insert_frame_front = DEFAULT_INT) -> float:
	if _frame_ids.has(frame_id):
		push_error("已添加过这个ID")
		return frame_id
	
	# 记录数据
	if frame_id == DEFAULT_INT:
		if insert_frame_front == DEFAULT_INT:
			_auto_incr_frame_id += 1
			frame_id = _auto_incr_frame_id
		else:
			var map = {}
			for id in _frame_ids:
				map[id] = null
			frame_id = insert_frame_front - 1
			while true:
				frame_id += 0.001
				if not map.has(frame_id):
					break
	
	if insert_frame_front == DEFAULT_INT:
		_frame_ids.append(frame_id)
	else:
		var id = _frame_ids.find(insert_frame_front)
		_frame_ids.insert(id, frame_id)
	
	# 所有层增加新的帧图像
	for layer_id in get_layer_ids():
		new_texture(layer_id, frame_id)
	# 发出信号
	newly_frame.emit(frame_id)
	return frame_id

## 移除动画帧
func remove_frame(frame_id: float) -> bool:
	var idx = _frame_ids.find(frame_id)
	if idx != -1:
		_frame_ids.remove_at(idx)
		removed_frame.emit(frame_id)
		return true
	return false

## 添加新的图片
func new_texture(layer_id: float, frame_id: float, texture: ImageTexture = null):
	var image_size : Vector2i = get_config(PropertyName.IMAGE.RECT).size
	if texture == null:
		texture = _layer_frame_to_image_data[layer_id] \
			.get(frame_id, {}) \
			.get(PropertyName.KEY.TEXTURE, null)
		if texture == null:
			var image = Image.create(image_size.x, image_size.y, true, Image.FORMAT_RGBA8)
			texture = ImageTexture.create_from_image(image)
	
	if not _layer_frame_to_image_data.has(layer_id):
		_layer_frame_to_image_data[layer_id] = {}
	
	if not _layer_frame_to_image_data[layer_id].has(frame_id):
		var data : Dictionary = {
			PropertyName.KEY.LAYER_ID: layer_id,
			PropertyName.KEY.FRAME_ID: frame_id,
			PropertyName.KEY.TEXTURE: texture,
			PropertyName.KEY.COLORS: {},
		}
		_layer_frame_to_image_data[layer_id][frame_id] = data
	else:
		_layer_frame_to_image_data[layer_id][frame_id][PropertyName.KEY.TEXTURE] = texture


## 更新贴图数据
func update_texture(layer_id: float, frame_id: float, texture: ImageTexture):
	var data = get_image_data(layer_id, frame_id)
	data[PropertyName.KEY.TEXTURE] = texture
	var id = "%d,%d" % [layer_id, frame_id]
	_update_thumbnails(layer_id, frame_id, texture)
	texture_changed.emit(layer_id, frame_id, texture)

func _update_thumbnails(layer_id: float, frame_id: float, texture: ImageTexture):
	var id = "%d,%d" % [layer_id, frame_id]
	var _texture := get_image_texture(layer_id, frame_id).duplicate(true) as ImageTexture
	_texture.set_size_override( THUMBNAILS_SIZE )
	_id_to_thumbnails[ id ] = _texture

## 获取缩略图
func get_thumbnails(layer_id: float, frame_id: float) -> ImageTexture:
	var id = "%d,%d" % [layer_id, frame_id]
	#var id = "%d,%d,%s" % [layer_id, frame_id, size]
	if not _id_to_thumbnails.has(id):
		var texture = get_image_texture(layer_id, frame_id).duplicate(true)
		_update_thumbnails(layer_id, frame_id, texture)
	return _id_to_thumbnails[id]

## 添加选中的层
func add_select_layer(layer_id: float) -> bool:
	if not _selected_layer_ids.has(layer_id):
		_selected_layer_ids[layer_id] = null
		select_layers_changed.emit()
		return true
	return false

## 移除选中的层
func remove_select_layer(layer_id: float) -> bool:
	if _selected_layer_ids.erase(layer_id):
		select_layers_changed.emit()
		return true
	return false

## 添加可绘制到的层
func add_select_layers(layer_ids: Array):
	var added = false
	for layer_id in layer_ids:
		if add_select_layer(layer_id):
			added = true
	if added:
		select_layers_changed.emit()

## 清除可绘制到的层
func clear_select_layer():
	_selected_layer_ids.clear()

## 是选中的层
func is_select_layer(layer_id: float) -> bool:
	return _selected_layer_ids.has(layer_id)

## 获取选中的层
func get_select_layer_ids() -> Array:
	return _selected_layer_ids.keys()

## 更新当前帧
func update_current_frame(frame_id: float):
	var last_frame_idx = _current_frame_point
	_current_frame_point = _frame_ids.find(frame_id)
	frame_changed.emit(_frame_ids[last_frame_idx], _frame_ids[_current_frame_point])

## 获取当前帧ID
func get_current_frame_id():
	return _frame_ids[_current_frame_point]

## 获取当前帧的ID索引
func get_current_frame_point():
	return _current_frame_point

## 获取当前帧的这一层的图像数据
func get_image_data_by_current_frame(layer_id: float) -> Dictionary:
	return get_image_data(layer_id, get_current_frame_id())
