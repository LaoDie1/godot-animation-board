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
	var erase_size = ProjectData.get_config(PropertyName.PEN.LINE_WIDTH)
	var stroke_points = ProjectData.get_stroke_points(erase_size)
	
	var points = DrawDataUtil.get_line_points(last_point, current_point)
	var draw_data : Dictionary = {}
	var tmp_p : Vector2i
	var pen_color = ProjectData.get_config(PropertyName.PEN.COLOR)
	for point in points:
		# 笔触
		for offset_p in stroke_points:
			tmp_p = point + offset_p
			if not _drawn_points_color.has(tmp_p) and image_rect.has_point(tmp_p):
				_drawn_points_color[tmp_p] = pen_color
				draw_data[tmp_p] = pen_color
	if not draw_data.is_empty():
		drawn.emit(draw_data)


func _released():
	draw_finished.emit()
