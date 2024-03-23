#============================================================
#    Image Layer
#============================================================
# - author: zhangxuetu
# - datetime: 2024-03-22 13:55:08
# - version: 4.2.1
#============================================================
## 图层
class_name ImageLayer
extends Control


signal image_changed()


var _draw_colors : Dictionary = {}
var _rect : Rect2i = Rect2i()
var _image : Image
var _image_texture : ImageTexture


#============================================================
#  内置
#============================================================
func _init() -> void:
	ProjectData.config_changed.connect(
		func(property, last_value, value):
			if property == PropertyName.IMAGE.SIZE:
				self._rect.size = value
				self.size = value
	)

func _ready() -> void:
	var image_size : Vector2i = ProjectData.get_config(PropertyName.IMAGE.SIZE)
	_rect.size = image_size
	custom_minimum_size = image_size


func _draw() -> void:
	draw_texture(_image_texture, Vector2(0,0))
	if self.size != Vector2(_rect.size):
		self.size = Vector2(_rect.size)


#============================================================
#  自定义
#============================================================
## 加载数据
func load_data(data: Dictionary):
	var texture = data[PropertyName.KEY.TEXTURE]
	_image_texture = texture
	_image = _image_texture.get_image()
	queue_redraw()


## 获取数据
func get_data():
	return {
		"_rect": _rect,
		"_image_texture": _image_texture,
		"_draw_colors": _draw_colors,
	}

## 获取图像数据
func get_image_texture() -> ImageTexture:
	return _image_texture

## 设置颜色偏移
func set_offset_colors(offset: Vector2i):
	if offset == Vector2i.ZERO:
		return
	
	# 原始数据偏移
	var data = {}
	for p in _draw_colors:
		data[p + offset] = _draw_colors[p]
	_draw_colors = data
	
	# 图像颜色
	var new_image = Image.create(_rect.size.x, _rect.size.y, true, Image.FORMAT_RGBA8)
	var point : Vector2i
	for x in _image.get_size().x:
		for y in _image.get_size().y:
			point = Vector2i(x, y)
			if _draw_colors.has(point):
				new_image.set_pixelv(point, _draw_colors[point])
	
	# 更新
	_image = new_image
	_image_texture.update(_image)
	image_changed.emit()
	queue_redraw()


## 根据数据设置颜色
func set_color_by_data(data: Dictionary, offset: Vector2i = Vector2i.ZERO):
	if data.is_empty():
		return
	
	# 更新图像数据
	if offset == Vector2i.ZERO:
		_draw_colors.merge(data, true)
		for point in data:
			if _rect.has_point(point):
				_image.set_pixelv(point, data[point])
	else:
		var visited : Dictionary = {}
		var tmp_point : Vector2i
		for point in data:
			tmp_point = point + offset
			if not visited.has(tmp_point) and _rect.has_point(tmp_point):
				_image.set_pixelv(tmp_point, data[point])
				visited[tmp_point] = null
			_draw_colors[tmp_point] = data[point]
	
	# 更新
	_image_texture.update(_image)
	image_changed.emit()
	queue_redraw()

