#============================================================
#    Image Layer
#============================================================
# - author: zhangxuetu
# - datetime: 2024-03-22 13:55:08
# - version: 4.2.1
#============================================================
## 图层
##
## 使用 Texture 进行绘制的原因是颜色多了不会卡顿
class_name ImageLayer
extends Control


var _last_layer_id
var _last_frame_id
var _image : Image
var _image_texture : ImageTexture


#============================================================
#  内置
#============================================================
func _init() -> void:
	ProjectData.config_changed.connect(
		func(property, last_value, value):
			if property == PropertyName.KEY.IMAGE_RECT:
				self.size = value.size
	)
	focus_mode = Control.FOCUS_CLICK


func _ready() -> void:
	self.size = ProjectData.get_config(PropertyName.KEY.IMAGE_RECT).size


func _draw() -> void:
	draw_texture(_image_texture, Vector2(0,0))


#============================================================
#  自定义
#============================================================
## 加载数据
func load_data(layer_id: float, frame_id: float):
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
	var image_rect = ProjectData.get_config(PropertyName.KEY.IMAGE_RECT)
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
	ProjectData.update_texture( _last_layer_id, _last_frame_id, _image_texture )
	queue_redraw()


## 根据数据绘制颜色。数据格式为: data[Vector2i()] = Color()
func draw_color_by_data(data: Dictionary, offset: Vector2i = Vector2i.ZERO):
	if data.is_empty():
		return
	
	# 更新图像数据
	ProjectData.add_image_colors(_last_layer_id, _last_frame_id, data, offset)
	queue_redraw()


## 根据 Texture2D 绘制颜色
func draw_color_by_texture(texture: Texture2D, offset: Vector2i = Vector2i.ZERO):
	ProjectData.add_image_texture(_last_layer_id, _last_frame_id, texture, offset)
	queue_redraw()


