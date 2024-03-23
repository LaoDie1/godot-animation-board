#============================================================
#    Frame Track
#============================================================
# - author: zhangxuetu
# - datetime: 2024-03-23 08:26:08
# - version: 4.2.1
#============================================================
## 帧轨道
class_name FrameTrack
extends Control


## 点击帧
signal clicked_frame(frame_id: int)


## 当前的层级ID
@export var layer_id : int = 0
## 每帧图像显示的大小
@export var frame_image_size : float = 20.0:
	set(v):
		if frame_image_size != v:
			frame_image_size = v
			for texture:ImageTexture in _id_to_frame_images.values():
				texture.set_size_override(Vector2i(frame_image_size, frame_image_size))
			queue_redraw()
## 时间刻度
@export var timescale : int = 24:
	set(v):
		if timescale != v:
			timescale = v
			queue_redraw()
## 偏移显示的图像
@export_range(0, 1, 1, "or_greater") var offset_frame : int = 0:
	set(v):
		if offset_frame != v:
			offset_frame = v
			queue_redraw()
## 偏移显示的图像
@export_range(0, 1, 1, "or_greater") var select_frame : int = 1:
	set(v):
		if select_frame != v:
			select_frame = v
			queue_redraw()


## 帧对应的缩略图
var _id_to_frame_images : Dictionary = {}


#============================================================
#  内置
#============================================================
func _init() -> void:
	clip_contents = true


func _draw() -> void:
	if layer_id == 0:
		return
	var count : int = ceili((size.x-frame_image_size) / 24)
	var rect = Rect2i()
	rect.size = Vector2i(frame_image_size, frame_image_size)
	var frame_id : int
	var texture : ImageTexture
	var frame_ids : Array = ProjectData.get_frame_ids()
	for idx in count:
		if idx + offset_frame >= frame_ids.size():
			break
		frame_id = frame_ids[idx + offset_frame]
		texture = ProjectData.get_thumbnails(layer_id, frame_id)
		rect.position.x = (idx - 1) * 24 * 2
		draw_texture_rect(texture, rect, false)
	# 选中的帧
	var offset_p = (select_frame - 1) * Vector2(24 * 2, 0) + Vector2(1,1)
	draw_rect( Rect2(offset_p, Vector2(40, 40) - Vector2(1,1)), Color.BLUE, false)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var frame_id = int(get_local_mouse_position().x / (24 * 2)) + 1
			clicked_frame.emit(frame_id)



#============================================================
#  自定义
#============================================================
func add_frame(frame_id: int, texture: ImageTexture):
	queue_redraw()

