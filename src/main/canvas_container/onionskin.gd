#============================================================
#    Onionskin
#============================================================
# - author: zhangxuetu
# - datetime: 2024-03-23 22:19:31
# - version: 4.2.1
#============================================================
## 洋葱皮
class_name Onionskin
extends Control


@export_range(1, 10, 1) var frame_range : int = 2:
	set(v):
		frame_range = v
		queue_redraw()


#============================================================
#  内置
#============================================================
func _init() -> void:
	ProjectData.new_file.connect(
		func():
			queue_redraw()
	)
	ProjectData.frame_changed.connect(
		func(last_frame_id, frame_id):
			queue_redraw()
	)
	ProjectData.listen_config(PropertyName.TOOL.ONIONSKIN, func(last, current):
		self.visible = current
	)


func _ready() -> void:
	self.frame_range = frame_range
	self.visible = ProjectData.get_config(PropertyName.TOOL.ONIONSKIN, false)


func _draw() -> void:
	if not visible:
		return
	var current_frame_point = ProjectData.get_current_frame_point()
	var frame_point : int
	var frame_id
	var alpha : float
	for idx in range(-frame_range, frame_range + 1):
		frame_point = current_frame_point + idx
		if idx != 0 and frame_point >= 0 and frame_point < ProjectData.get_frame_count():
			alpha = (frame_range - abs(idx)) / float(frame_range) * 0.6
			frame_id = ProjectData.get_frame_id(frame_point)
			for layer_id in ProjectData.get_layer_ids():
				var texture = ProjectData.get_image_texture(layer_id, frame_id)
				if idx < 0:
					draw_texture(texture, Vector2(), Color(1,0,0,alpha))
				else:
					draw_texture(texture, Vector2(), Color(0,1,0,alpha))


