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


#============================================================
#  内置
#============================================================
func _init() -> void:
	ProjectData.set_config(PropertyName.ERASER.SIZE, 1)



#============================================================
#  自定义
#============================================================
func _pressed():
	_drawn_points_color.clear()
	ready_erase.emit()


func _press_move(last_point: Vector2i, current_point: Vector2i) -> void:
	var erase_size = ProjectData.get_config(PropertyName.ERASER.SIZE)
	var stroke_points = ProjectData.get_stroke_points(erase_size)
	
	var points = DrawDataUtil.get_line_points(last_point, current_point)
	var draw_data : Dictionary = {}
	var tmp_p : Vector2i
	for point in points:
		# 笔触
		for offset_p in stroke_points:
			tmp_p = point + offset_p
			if not _drawn_points_color.has(tmp_p) and image_rect.has_point(tmp_p):
				_drawn_points_color[tmp_p] = Color(1,1,1,0)
				draw_data[tmp_p] = Color(1,1,1,0)
		if not draw_data.is_empty():
			erased.emit(draw_data)


func _release():
	erase_finished.emit()
