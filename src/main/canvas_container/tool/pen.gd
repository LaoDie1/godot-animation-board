#============================================================
#    Pen
#============================================================
# - author: zhangxuetu
# - datetime: 2024-03-22 17:53:38
# - version: 4.2.1
#============================================================
## 钢笔工具
class_name Tool_Pen
extends ToolBase


signal ready_draw()
signal drawn(data: Dictionary)
signal draw_finished()


var _drawn_points_color : Dictionary = {} # 已绘制到的点位颜色
var _shift_direction : Vector2 = Vector2.ZERO # 按住 shift 绘制的线的方向
var _last_shift_pos : Vector2 = Vector2()


#============================================================
#  内置
#============================================================
func _init() -> void:
	ProjectData.set_config(PropertyName.PEN.SIZE, 1)


#============================================================
#  自定义
#============================================================
func draw_colors(from: Vector2, to: Vector2):
	# 绘制
	var pen_shape_type = ProjectData.get_config(PropertyName.PEN.SHAPE)
	var pen_line_width = ProjectData.get_config(PropertyName.PEN.SIZE)
	var pen_color = ProjectData.get_config(PropertyName.PEN.COLOR)
	var draw_data = CanvasUtil.draw_colors(
		from, to, 
		image_rect, pen_shape_type, pen_line_width, pen_color, 
		_drawn_points_color
	)
	if not draw_data.is_empty():
		drawn.emit(draw_data)
		_drawn_points_color.merge(draw_data)


func _pressed(button_index):
	if get_last_button_index() != MOUSE_BUTTON_LEFT:
		return
	_shift_direction = Vector2()
	_last_shift_pos = Vector2()
	_drawn_points_color.clear()
	ready_draw.emit()
	draw_colors( get_last_pressed_point(), get_last_pressed_point() )


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
	
	# 绘制
	draw_colors(last_point, current_point)


func _released(button_index):
	if get_last_button_index() != MOUSE_BUTTON_LEFT:
		return
	
	draw_finished.emit()
