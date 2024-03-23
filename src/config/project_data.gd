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

const DEFAULT_LAYER = 1
const DEFAULT_FRAME = 1


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


func set_config(property: String, value):
	var last_value = _config_data.get(property)
	if typeof(last_value) != typeof(value) or last_value != value:
		_config_data[property] = value
		config_changed.emit(property, last_value, value)

func get_config(property, default = null):
	if _config_data.has(property):
		return _config_data[property]
	else:
		_config_data[property] = default
		return default



#============================================================
#  项目数据
#============================================================
signal newly_layer(layer_id: int)
signal newly_frame(frame_id: int)
signal frame_changed(last_frame_id: int, frame_id: int)
signal texture_changed(layer_id: int, frame_id: int)


var _current_frame : int = 0
var _auto_incr_layer_id : int = 0
var _auto_incr_frame_id : int = 0
var _frame_ids : Dictionary = {} # 帧ID列表
var _layer_frame_to_image_data : Dictionary = {} # 层级对应的帧的图像数据
var _selected_layer_ids : Dictionary = {} # 选中的层级
var _id_to_thumbnails : Dictionary = {} # id对应的缩略图


## 添加图像数据
func add_image_data(layer_id: int, frame_id: int, data: Dictionary):
	_layer_frame_to_image_data[layer_id][frame_id] = data

## 获取图像数据
func get_image_data(layer_id: int, frame_id: int) -> Dictionary:
	return _layer_frame_to_image_data[layer_id][frame_id]

## 获取图像贴图
func get_image_texture(layer_id: int, frame_id: int) -> ImageTexture:
	var data : Dictionary = get_image_data(layer_id, frame_id)
	return data[PropertyName.KEY.TEXTURE]

func get_max_layer_id() -> int:
	return _auto_incr_layer_id

func get_max_frame_id() -> int:
	return _auto_incr_frame_id

## 获取所有图层ID
func get_layer_ids() -> Array:
	return _layer_frame_to_image_data.keys()

## 获取所有帧ID
func get_frame_ids() -> Array:
	return _frame_ids.keys()

func has_frame(frame_id: int) -> bool:
	return _frame_ids.has(frame_id)

## 新的图层
func new_layer() -> int:
	_auto_incr_layer_id += 1
	# 对应层级数据
	_layer_frame_to_image_data[_auto_incr_layer_id] = {}
	for frame_id in get_frame_ids():
		new_texture(_auto_incr_layer_id, frame_id)
	# 发出信号
	newly_layer.emit(_auto_incr_layer_id)
	return _auto_incr_layer_id

## 新的动画帧
func new_frame() -> int:
	_auto_incr_frame_id += 1
	if _auto_incr_frame_id == 1:
		_current_frame = 1
	_frame_ids[_auto_incr_frame_id] = null
	# 所有层增加新的帧图像
	for layer_id in get_layer_ids():
		new_texture(layer_id, _auto_incr_frame_id)
	# 发出信号
	newly_frame.emit(_auto_incr_frame_id)
	return _auto_incr_frame_id

## 添加新的图片
func new_texture(layer_id: int, frame_id: int, texture: ImageTexture = null):
	var image_size : Vector2i = get_config(PropertyName.IMAGE.SIZE)
	if texture == null:
		var image = Image.create(image_size.x, image_size.y, true, Image.FORMAT_RGBA8)
		texture = ImageTexture.create_from_image(image)
	var data : Dictionary = {
		PropertyName.KEY.LAYER_ID: layer_id,
		PropertyName.KEY.FRAME_ID: frame_id,
		PropertyName.KEY.TEXTURE: texture,
	}
	_layer_frame_to_image_data[layer_id][frame_id] = data
	add_image_data(layer_id, frame_id, data)

## 更新贴图数据
func update_texture(layer_id: int, frame_id: int, texture: ImageTexture):
	var data = get_image_data(layer_id, frame_id)
	data[PropertyName.KEY.TEXTURE] = texture
	var id = "%d,%d" % [layer_id, frame_id]
	_id_to_thumbnails.erase(id)
	texture_changed.emit(layer_id, frame_id, texture)

## 添加可绘制到的层
func add_select_layer(layer_id: int):
	_selected_layer_ids[layer_id] = null

## 添加可绘制到的层
func add_select_layers(layer_ids: Array):
	for id in layer_ids:
		_selected_layer_ids[id] = null

## 清除可绘制到的层
func clear_select_layer():
	_selected_layer_ids.clear()

## 获取选中的层
func get_select_layer_ids() -> Array:
	return _selected_layer_ids.keys()

## 更新当前帧
func update_current_frame(frame_id: int):
	var last = _current_frame
	_current_frame = frame_id
	frame_changed.emit(last, frame_id)

func get_current_frame() -> int:
	return _current_frame

func get_image_data_by_current_frame(layer_id: int) -> Dictionary:
	return get_image_data(layer_id, _current_frame)

## 获取缩略图
func get_thumbnails(layer_id: int, frame_id: int) -> ImageTexture:
	var size = Vector2i(40, 40)
	var id = "%d,%d" % [layer_id, frame_id]
	#var id = "%d,%d,%s" % [layer_id, frame_id, size]
	if not _id_to_thumbnails.has(id):
		var texture := get_image_texture(layer_id, frame_id).duplicate(true) as ImageTexture
		texture.set_size_override( size )
		_id_to_thumbnails[ id ] = texture
	return _id_to_thumbnails[id]

