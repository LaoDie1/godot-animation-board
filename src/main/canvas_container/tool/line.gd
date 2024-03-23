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


#func _press_move(last_point: Vector2i, current_point: Vector2i) -> void:
	#var erase_size = ProjectData.get_config(PropertyName.PEN.LINE_WIDTH)
	#var stroke_points = ProjectData.get_stroke_points(erase_size)
	#
	#var points = DrawDataUtil.get_line_points(last_point, current_point)
	#var draw_data : Dictionary = {}
	#var tmp_p : Vector2i
	#var color = ProjectData.get_config(PropertyName.PEN.COLOR)
	#for point in points:
		## 笔触
		#for offset_p in stroke_points:
			#tmp_p = point + offset_p
			#if not _drawn_points_color.has(tmp_p) and image_rect.has_point(tmp_p):
				#_drawn_points_color[tmp_p] = color
				#draw_data[tmp_p] = color
	#if not draw_data.is_empty():
		#drawn.emit(draw_data)


func _released():
	var erase_size = ProjectData.get_config(PropertyName.LINE.WIDTH)
	var stroke_points = ProjectData.get_stroke_points(erase_size)
	
	var points = DrawDataUtil.get_line_points(get_last_pressed_point(), get_current_point())
	var draw_data : Dictionary = {}
	var tmp_p : Vector2i
	var color = ProjectData.get_config(PropertyName.LINE.COLOR)
	for point in points:
		# 笔触
		for offset_p in stroke_points:
			tmp_p = point + offset_p
			if not _drawn_points_color.has(tmp_p) and image_rect.has_point(tmp_p):
				_drawn_points_color[tmp_p] = color
				draw_data[tmp_p] = color
	released.emit(draw_data)


