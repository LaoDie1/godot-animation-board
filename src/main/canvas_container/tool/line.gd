#============================================================
#    Line
#============================================================
# - author: zhangxuetu
# - datetime: 2024-03-24 00:31:13
# - version: 4.2.1
#============================================================
class_name Tool_Line
extends ToolBase


signal pressed()
signal released(drawn_points_color: Dictionary)
signal moved(last_point: Vector2, current_point: Vector2)


var _drawn_points_color : Dictionary = {} # 已绘制到的点位颜色


#============================================================
#  内置
#============================================================
func _init() -> void:
	ProjectData.set_config(PropertyName.LINE.WIDTH, 3)
	ProjectData.set_config(PropertyName.LINE.COLOR, Color.WHITE)


#============================================================
#  自定义
#============================================================
func _pressed(button_index):
	if get_last_button_index() != MOUSE_BUTTON_LEFT:
		return
	
	_drawn_points_color.clear()
	pressed.emit()


func _press_moving(last_point: Vector2, current_point: Vector2):
	if get_last_button_index() != MOUSE_BUTTON_LEFT:
		return
	
	moved.emit(last_point, current_point)


func _released(button_index):
	if get_last_button_index() != MOUSE_BUTTON_LEFT:
		return
	
	var line_width = ProjectData.get_config(PropertyName.LINE.WIDTH)
	var points = CanvasUtil.get_line_points(get_last_pressed_point(), get_current_point())
	var draw_data = CanvasUtil.create_stroke_points(PropertyName.SHAPE.CIRCLE, line_width, image_rect, points, _drawn_points_color)
	var line_color = ProjectData.get_config(PropertyName.LINE.COLOR)
	for point in draw_data:
		draw_data[point] = line_color
	released.emit(draw_data)
