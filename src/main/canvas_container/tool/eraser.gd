#============================================================
#    Eraser
#============================================================
# - author: zhangxuetu
# - datetime: 2024-03-23 19:18:04
# - version: 4.2.1
#============================================================
## 橡皮擦工具
class_name Tool_Eraser
extends ToolBase


signal ready_erase()
signal erased(data: Dictionary)
signal erase_finished()


var _drawn_points_color : Dictionary = {}
var _shift_direction : Vector2 = Vector2.ZERO # 按住 shift 绘制的线的方向
var _last_shift_pos : Vector2 = Vector2()


#============================================================
#  内置
#============================================================
func _init() -> void:
	ProjectData.set_config(PropertyName.ERASER.SIZE, 1)



#============================================================
#  自定义
#============================================================
func _pressed(button_index):
	if get_last_button_index() != MOUSE_BUTTON_LEFT:
		return
	
	_shift_direction = Vector2()
	_last_shift_pos = Vector2()
	_drawn_points_color.clear()
	ready_erase.emit()


func _press_moving(last_point: Vector2, current_point: Vector2) -> void:
	if get_last_button_index() != MOUSE_BUTTON_LEFT:
		return
	
	if Input.is_key_pressed(KEY_SHIFT):
		# 如果按着 shift 键绘制直线
		if _shift_direction == Vector2.ZERO:
			var diff = current_point - get_last_pressed_point()
			if diff.length() < 6:
				return
			_shift_direction = diff.normalized()
			_last_shift_pos = get_last_pressed_point()
			return
		
		var diff = current_point - get_last_pressed_point()
		var d = diff.normalized().dot(_shift_direction)
		var total = diff.length()
		var offset = (_shift_direction * total).round()
		if d > 0:
			# 同方向
			current_point = get_last_pressed_point() + offset
		else:
			# 反方向
			current_point = get_last_pressed_point() - offset
		
		# 上次位置
		last_point = _last_shift_pos
		if int(total) % 4 == 0:
			_last_shift_pos = current_point
	
	var eraser_shape_type = ProjectData.get_config(PropertyName.ERASER.SHAPE)
	var eraser_size = ProjectData.get_config(PropertyName.ERASER.SIZE)
	var line_points = CanvasUtil.get_line_points(last_point, current_point)
	var draw_data = CanvasUtil.create_stroke_points(eraser_shape_type, eraser_size, image_rect, line_points, _drawn_points_color)
	for point in draw_data:
		draw_data[point] = Color(1, 1, 1, 0)
		_drawn_points_color[point] = null
	if not draw_data.is_empty():
		erased.emit(draw_data)


func _released(button_index):
	if get_last_button_index() != MOUSE_BUTTON_LEFT:
		return
	
	erase_finished.emit()
