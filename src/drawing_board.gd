#============================================================
#    Draw Board
#============================================================
# - author: zhangxuetu
# - datetime: 2024-03-21 22:43:25
# - version: 4.2.1
#============================================================
class_name DrawBoard
extends Control


signal draw_finished()

const COLOR_LENGTH = 4


@export var pen_color : Color = Color.WHITE
## 笔触形状
@export_range(0,0) var pen_shape : int = 0 
## 笔触大小
@export_range(0, 1, 1, "or_greater") var stroke_size : int = 1: 
	set(v):
		v = max(1, v)
		if stroke_size != v:
			stroke_size = v
			# 笔触点
			_stroke_points.clear()
			var point : Vector2i = Vector2i()
			for x in range(-stroke_size, stroke_size+1):
				point.x = x
				for y in range(-stroke_size, stroke_size+1):
					point.y = y
					if point.length() < stroke_size:
						_stroke_points.append(point)


var _draw_before_colors : Dictionary = {}
var _drawn_colors : Dictionary = {}

var _stroke_points : Array[Vector2i] = [] # 绘制时的笔触大小
var _image_size : Vector2i
var _drawing : bool = false
var _image : Image
var _image_texture: ImageTexture
var _last_point : Vector2i


#============================================================
#  内置
#============================================================
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if _drawing:
			var point := Vector2i(get_local_mouse_position())
			set_colors(_last_point, point, pen_color)
			_last_point = point
	
	elif event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				_drawing = event.pressed
				_last_point = Vector2i(get_local_mouse_position())
				if event.pressed:
					_draw_before_colors.clear()
					_drawn_colors.clear()
				else:
					self.draw_finished.emit()


func _draw() -> void:
	draw_texture_rect(_image_texture, Rect2i(Vector2i(0,0), _image_size), false)
	draw_rect( Rect2i(Vector2i(), _image_size ), Color(1,1,1,0.1), false, 1.0)



#============================================================
#  自定义
#============================================================
func _get_line_points(begin: Vector2i, end: Vector2i) -> Array[Vector2i]:
	var points : Array[Vector2i] = []
	var direction : Vector2 = Vector2(begin).direction_to(Vector2(end))
	var length = (end - begin).length()
	var point = Vector2(begin)
	for i in length:
		point += direction
		points.push_back(Vector2i(point))
	return points


func new_image(image_size: Vector2i):
	_image_size = image_size
	custom_minimum_size = image_size
	_image = Image.create(_image_size.x, _image_size.y, true, Image.FORMAT_RGBA8)
	_image_texture = ImageTexture.create_from_image(_image)


func open_image(image: Image):
	new_image(image.get_size())
	_image = image
	_draw_before_colors = {}
	_drawn_colors = {}


func is_in_canvas(point: Vector2i) -> bool:
	return (point.x >= 0 and point.y >= 0 
		and point.x < _image.get_size().x and point.y < _image.get_size().y
	)


func set_colors(begin: Vector2i, end: Vector2i, color: Color):
	if is_in_canvas(begin) and is_in_canvas(end):
		var tmp_p : Vector2i
		for point in _get_line_points(begin, end):
			# 笔触
			for offset_p in _stroke_points:
				tmp_p = point + offset_p
				if  not _draw_before_colors.has(tmp_p) and is_in_canvas(tmp_p):
					_draw_before_colors[tmp_p] = _image.get_pixelv(tmp_p)
					_image.set_pixelv(tmp_p, pen_color)
					_drawn_colors[tmp_p] = pen_color
		_image_texture.update(_image)
		queue_redraw()

func set_color_by_data(data: Dictionary):
	var color : Color
	for point in data:
		color = data[point]
		_image.set_pixelv(point, color)
	_image_texture.update(_image)
	queue_redraw()

