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
	var points = DrawDataUtil.get_line_points(last_point, current_point)
	var draw_data = DrawDataUtil.create_stroke_points(0, erase_size, image_rect, points, _drawn_points_color)
	for point in draw_data:
		draw_data[point] = Color(1, 1, 1, 0)
		_drawn_points_color[point] = null
	if not draw_data.is_empty():
		erased.emit(draw_data)


func _released():
	erase_finished.emit()
