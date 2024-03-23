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
signal moved(last_point: Vector2i, current_point: Vector2i)


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
func _pressed():
	_drawn_points_color.clear()
	pressed.emit()


func _press_move(last_point: Vector2i, current_point: Vector2i):
	moved.emit(last_point, current_point)


func _released():
	var line_width = ProjectData.get_config(PropertyName.LINE.WIDTH)
	var points = DrawDataUtil.get_line_points(get_last_pressed_point(), get_current_point())
	var draw_data = DrawDataUtil.create_stroke_points(0, line_width, image_rect, points, _drawn_points_color)
	var line_color = ProjectData.get_config(PropertyName.LINE.COLOR)
	for point in draw_data:
		draw_data[point] = line_color
	released.emit(draw_data)


