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


var _last_layer_id : int 
var _last_frame_id : int 
var _image : Image
var _image_texture : ImageTexture


#============================================================
#  内置
#============================================================
func _init() -> void:
	ProjectData.config_changed.connect(
		func(property, last_value, value):
			if property == PropertyName.IMAGE.RECT:
				self.size = value.size
	)

func _ready() -> void:
	self.size = ProjectData.get_config(PropertyName.IMAGE.RECT).size


func _draw() -> void:
	draw_texture(_image_texture, Vector2(0,0))


#============================================================
#  自定义
#============================================================
## 加载数据
func load_data(layer_id: int, frame_id: int):
	_last_layer_id = layer_id
	_last_frame_id = frame_id
	var data = ProjectData.get_image_data(layer_id, frame_id)
	var texture = data[PropertyName.KEY.TEXTURE]
	_image_texture = texture
	_image = _image_texture.get_image()
	queue_redraw()


## 获取图像数据
func get_image_texture() -> ImageTexture:
	return _image_texture

## 设置颜色偏移
func set_offset_colors(offset: Vector2i):
	if offset == Vector2i.ZERO:
		return
	
	# 颜色数据偏移
	var image_colors : Dictionary = ProjectData.get_image_colors(_last_layer_id, _last_frame_id)
	var data = {}
	for p in image_colors:
		data[p + offset] = image_colors[p]
	image_colors = data
	ProjectData.update_image_colors(_last_layer_id, _last_frame_id, image_colors)
	
	# 图像颜色
	var image_rect = ProjectData.get_config(PropertyName.IMAGE.RECT)
	var new_image = Image.create(image_rect.size.x, image_rect.size.y, true, Image.FORMAT_RGBA8)
	var point : Vector2i
	for x in _image.get_size().x:
		for y in _image.get_size().y:
			point = Vector2i(x, y)
			if image_colors.has(point):
				new_image.set_pixelv(point, image_colors[point])
	
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
	var image_colors : Dictionary = ProjectData.get_image_colors(_last_layer_id, _last_frame_id)
	var image_rect : Rect2i = ProjectData.get_config(PropertyName.IMAGE.RECT)
	if offset == Vector2i.ZERO:
		image_colors.merge(data, true)
		for point in data:
			if image_rect.has_point(point):
				_image.set_pixelv(point, data[point])
	else:
		var visited : Dictionary = {}
		var tmp_point : Vector2i
		for point in data:
			tmp_point = point + offset
			if not visited.has(tmp_point) and image_rect.has_point(tmp_point):
				_image.set_pixelv(tmp_point, data[point])
				visited[tmp_point] = null
			image_colors[tmp_point] = data[point]
	
	# 更新
	_image_texture.update(_image)
	image_changed.emit()
	queue_redraw()

