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

