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
signal clicked_frame(frame_id: float)


# 每个帧的占用宽度
const SPACE_WIDTH = 48


## 当前的层级ID
@export var layer_id : float = 0
## 偏移显示的图像
@export_range(0, 1, 1, "or_greater") var offset_frame : int = 0:
	set(v):
		if offset_frame != v:
			offset_frame = v
			queue_redraw()

# 图像大小
var _frame_image_size : int = 40


static var frame_board_color: Color = Color(1, 1, 1, 0.5)
static var select_frame_color: Color = Color(1, 1, 1, 0.1)
static var select_layer_color: Color = Color(1, 1, 1, 0.9)


#============================================================
#  内置
#============================================================
func _init() -> void:
	clip_contents = true
	ProjectData.newly_frame.connect(
		func(frame_id: float):
			queue_redraw()
	)
	ProjectData.frame_changed.connect(
		func(last_frame_id: float, frame_id: float):
			queue_redraw()
	)


func _draw() -> void:
	if layer_id == 0:
		return
	
	# 绘制缩略图
	var count : int = ceili((size.x-_frame_image_size) / 24)
	var rect = Rect2i()
	rect.size = Vector2i(_frame_image_size, _frame_image_size)
	var frame_id 
	var frame_ids : Array = ProjectData.get_frame_ids()
	for idx in count:
		if idx + offset_frame < frame_ids.size():
			frame_id = frame_ids[idx + offset_frame]
			rect.position.x = (idx) * SPACE_WIDTH
			draw_texture_rect(
				ProjectData.get_thumbnails(layer_id, frame_id),
				rect, false
			)
			draw_rect(rect, frame_board_color, false)
		else:
			break
	
	# 绘制帧边框
	var offset_p = Vector2()
	offset_p.x = ProjectData.get_current_frame_point() * SPACE_WIDTH + 1
	draw_rect( Rect2(offset_p, Vector2(40, 40) - Vector2(1,1)), select_frame_color, true)
	
	# 高亮编辑的层
	if ProjectData.is_select_layer(layer_id):
		draw_rect( Rect2(offset_p, Vector2(40, 40) - Vector2(1,1)), select_layer_color, true)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var idx = int(get_local_mouse_position().x / SPACE_WIDTH) + offset_frame
			if idx < ProjectData.get_frame_id_count():
				var frame_id = ProjectData.get_frame_ids()[idx]
				# 更新当前的帧位置
				ProjectData.update_current_frame(frame_id)
				clicked_frame.emit(frame_id)

