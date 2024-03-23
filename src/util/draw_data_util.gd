#============================================================
#    Draw Data Util
#============================================================
# - author: zhangxuetu
# - datetime: 2024-03-22 17:54:40
# - version: 4.2.1
#============================================================
class_name DrawDataUtil


static func get_max_vectori(a: Vector2i, b: Vector2i) -> Vector2i:
	return Vector2i( maxi(a.x, b.x), maxi(a.y, b.y) )

static func get_min_vectori(a: Vector2i, b: Vector2i) -> Vector2i:
	return Vector2i( mini(a.x, b.x), mini(a.y, b.y) )


static func get_line_points(begin: Vector2i, end: Vector2i) -> Array[Vector2i]:
	var points : Array[Vector2i] = []
	var direction : Vector2 = Vector2(begin).direction_to(Vector2(end))
	var length : int = (end - begin).length()
	var point : Vector2 = Vector2(begin)
	for i in length:
		point += direction
		points.push_back(Vector2i(point))
	return points

static func create_stroke_points(type, width: int, image_rect: Rect2i, points: Array, exclude : Dictionary = {}) -> Dictionary:
	var stroke_points = ProjectData.get_stroke_points(width)
	var draw_data : Dictionary = {}
	var tmp_p : Vector2i
	for point in points:
		# 笔触
		for offset_p in stroke_points:
			tmp_p = point + offset_p
			if not exclude.has(tmp_p) and image_rect.has_point(tmp_p):
				draw_data[tmp_p] = null
	return draw_data
