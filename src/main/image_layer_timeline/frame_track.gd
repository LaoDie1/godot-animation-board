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
## 偏移显示的图像
@export_range(0, 1, 1, "or_greater") var offset_frame : int = 0:
	set(v):
		if offset_frame != v:
			offset_frame = v
			queue_redraw()

# 图像大小
var _frame_image_size : int = 40
# 帧对应的缩略图
var _id_to_frame_images : Dictionary = {}


static var frame_board_color: Color = Color(1, 1, 1, 0.5)
static var select_frame_color: Color = Color(1, 1, 1, 0.1)
static var select_layer_color: Color = Color(1, 1, 1, 0.9)


#============================================================
#  内置
#============================================================
func _init() -> void:
	clip_contents = true


func _ready() -> void:
	ProjectData.newly_frame.connect(
		func(frame_id):
			queue_redraw()
	)
	ProjectData.frame_changed.connect(
		func(last_frame_id: int, frame_id: int):
			queue_redraw()
	)


func _draw() -> void:
	if layer_id == 0:
		return
	var count : int = ceili((size.x-_frame_image_size) / 24)
	var rect = Rect2i()
	rect.size = Vector2i(_frame_image_size, _frame_image_size)
	# 绘制缩略图
	var frame_id : int
	var frame_ids : Array = ProjectData.get_frame_ids()
	for idx in count:
		if idx + offset_frame >= frame_ids.size():
			break
		frame_id = frame_ids[idx + offset_frame]
		rect.position.x = (idx) * 24 * 2
		draw_texture_rect(
			ProjectData.get_thumbnails(layer_id, frame_id), 
			rect, false
		)
		draw_rect(rect, frame_board_color, false)
	
	# 选中的帧
	var offset_p = (ProjectData.get_current_frame() - 1) * Vector2(24 * 2, 0) + Vector2(1,1)
	draw_rect( Rect2(offset_p, Vector2(40, 40) - Vector2(1,1)), select_frame_color, true)
	if ProjectData.is_select_layer(layer_id):
		draw_rect( Rect2(offset_p, Vector2(40, 40) - Vector2(1,1)), select_layer_color, true)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var frame_id = int(get_local_mouse_position().x / (24 * 2)) + 1
			ProjectData.update_current_frame(frame_id)
			clicked_frame.emit(frame_id)
