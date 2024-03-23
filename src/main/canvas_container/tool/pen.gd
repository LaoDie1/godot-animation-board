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


#============================================================
#  内置
#============================================================
func _init() -> void:
	ProjectData.set_config(PropertyName.PEN.LINE_WIDTH, 1)


#============================================================
#  自定义
#============================================================
func _pressed():
	_drawn_points_color.clear()
	ready_draw.emit()


func _press_move(last_point: Vector2i, current_point: Vector2i) -> void:
	var pen_line_width = ProjectData.get_config(PropertyName.PEN.LINE_WIDTH)
	var pen_color = ProjectData.get_config(PropertyName.PEN.COLOR)
	var points = DrawDataUtil.get_line_points(last_point, current_point)
	var draw_data = DrawDataUtil.create_stroke_points(0, pen_line_width, image_rect, points, _drawn_points_color)
	for point in draw_data:
		draw_data[point] = pen_color
		_drawn_points_color[point] = null
	if not draw_data.is_empty():
		drawn.emit(draw_data)


func _released():
	draw_finished.emit()
