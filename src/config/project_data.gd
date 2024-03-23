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

## 监听这个配置的改变。监听的方法需要有两个参数，一个接收修改前的值，一个为当前的值
func listen_config(property: String, method: Callable):
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
#  菜单功能
#============================================================
signal new_file()

var menu : SimpleMenu
var undo_redo : UndoRedo = UndoRedo.new()

func add_undo_redo(action_name: String, do_method: Callable, undo_method: Callable, execute_do: bool):
	undo_redo.create_action(action_name)
	undo_redo.add_do_method(do_method)
	undo_redo.add_undo_method(undo_method)
	undo_redo.commit_action(execute_do)
	menu.set_menu_disabled_by_path("/Edit/Undo", false)

func menu_new():
	undo_redo.clear_history(true)
	_auto_incr_frame_id = 0
	_auto_incr_layer_id = 0
	
	_frame_ids.clear()
	_layer_ids.clear()
	_current_frame_point = 0
	_layer_frame_to_image_data.clear()
	_selected_layer_ids.clear()
	_id_to_thumbnails.clear()
	
	new_file.emit()


func menu_undo():
	undo_redo.undo()
	menu.set_menu_disabled_by_path("/Edit/Undo", not undo_redo.has_undo())
	menu.set_menu_disabled_by_path("/Edit/Redo", not undo_redo.has_redo())

func menu_redo():
	undo_redo.redo()
	menu.set_menu_disabled_by_path("/Edit/Undo", not undo_redo.has_undo())
	menu.set_menu_disabled_by_path("/Edit/Redo", not undo_redo.has_redo())

func menu_add_layer():
	var layer_id = get_new_layer_id()
	add_undo_redo(
		"添加图层",
		new_layer.bind(layer_id),
		remove_layer.bind(layer_id),
		true
	)

func menu_add_frame():
	var frame_id = get_new_frame_id()
	var last_frame_id = get_current_frame_id()
	add_undo_redo(
		"添加帧",
		new_frame.bind(frame_id),
		remove_frame.bind(frame_id, last_frame_id),
		true
	)

func __menu_add_frame_do(frame_id):
	new_frame(frame_id)
	update_current_frame(frame_id)

func __menu_add_frame_undo(frame_id, last_frame_id):
	remove_frame(frame_id)
	update_current_frame(last_frame_id)


func menu_insert_frame():
	var frame_id = get_current_frame_id()
	var new_frame_id = get_new_frame_id(frame_id)
	add_undo_redo(
		"添加新的帧到前面",
		__menu_add_frame_to_front_do.bind(frame_id, new_frame_id),
		__menu_add_frame_to_front_undo.bind(frame_id, new_frame_id),
		true
	)

func __menu_add_frame_to_front_do(frame_id, new_frame_id):
	new_frame(new_frame_id, frame_id)
	update_current_frame(new_frame_id)

func __menu_add_frame_to_front_undo(frame_id, new_frame_id):
	remove_frame(new_frame_id)
	update_current_frame(frame_id)


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

## 获取这个图层的顺序
func get_layer_point(layer_id) -> int:
	return _layer_ids.find(layer_id)

## 获取图层数量
func get_layer_count() -> int:
	return _layer_ids.size()

## 是否有这个图层
func has_layer(layer_id) -> bool:
	return _layer_ids.has(layer_id)

## 获取所有帧ID
func get_frame_ids() -> Array:
	return _frame_ids

## 获取动画帧数
func get_frame_count() -> int:
	return _frame_ids.size()

func has_frame(frame_id: float) -> bool:
	return _frame_ids.has(frame_id)

func get_new_layer_id():
	_auto_incr_layer_id += 1
	return _auto_incr_layer_id

## 新的图层
func new_layer(layer_id: float = DEFAULT_INT, insert_layer_front: float = DEFAULT_INT) -> float:
	if _layer_ids.has(layer_id):
		push_error("已添加过这个ID的图层")
		return layer_id
	
	if layer_id == DEFAULT_INT:
		if insert_layer_front == DEFAULT_INT:
			layer_id = get_new_layer_id()
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
		remove_select_layer(layer_id)
		return true
	return false

func get_new_frame_id(insert_frame_front = DEFAULT_INT):
	var frame_id
	if insert_frame_front == DEFAULT_INT:
		_auto_incr_frame_id += 1
		frame_id = _auto_incr_frame_id
	else:
		var map = {}
		for id in _frame_ids:
			map[id] = null
		frame_id = insert_frame_front
		while true:
			frame_id -= 0.001
			if not map.has(frame_id):
				break
	return frame_id


## 新的动画帧
##[br]
##[br][code]frame_id[/code]  这个帧的ID
##[br][code]insert_frame_front[/code]  插入到这个帧的前面
func new_frame(frame_id, insert_frame_front = DEFAULT_INT) -> float:
	if _frame_ids.has(frame_id):
		push_error("已添加过这个ID")
		return frame_id
	
	# 记录数据
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
		if idx == _current_frame_point:
			update_current_frame(_frame_ids[idx - 1])
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
	_update_thumbnails(layer_id, frame_id, texture)
	texture_changed.emit(layer_id, frame_id, texture)

func _update_thumbnails(layer_id: float, frame_id: float, texture: ImageTexture = null):
	if texture == null:
		texture = get_image_texture(layer_id, frame_id).duplicate(true)
	else:
		texture = texture.duplicate(true)
	texture.set_size_override( THUMBNAILS_SIZE )
	if not _id_to_thumbnails.has(layer_id):
		_id_to_thumbnails[layer_id] = {}
	_id_to_thumbnails[layer_id][frame_id] = texture

## 获取缩略图
func get_thumbnails(layer_id: float, frame_id: float) -> ImageTexture:
	if not _id_to_thumbnails.has(layer_id) or not _id_to_thumbnails[layer_id].has(frame_id):
		_update_thumbnails(layer_id, frame_id)
	return _id_to_thumbnails[layer_id][frame_id]

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
	update_current_frame_by_point(_frame_ids.find(frame_id))

## 更新当前帧
func update_current_frame_by_point(point: int):
	if point == -1:
		return
	var last_frame_idx = _current_frame_point
	_current_frame_point = point
	if last_frame_idx < _frame_ids.size():
		frame_changed.emit(_frame_ids[last_frame_idx], _frame_ids[_current_frame_point])
	else:
		frame_changed.emit(_frame_ids.front(), _frame_ids[_current_frame_point])

## 获取当前帧ID
func get_current_frame_id():
	return _frame_ids[_current_frame_point]

func get_frame_id(idx: int) -> float:
	return _frame_ids[idx]

## 获取当前帧的ID索引
func get_current_frame_point() -> int:
	return _current_frame_point

## 获取当前帧的这一层的图像数据
func get_image_data_by_current_frame(layer_id: float) -> Dictionary:
	return get_image_data(layer_id, get_current_frame_id())
