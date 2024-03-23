#============================================================
#    Image Layer Timeline
#============================================================
# - author: zhangxuetu
# - datetime: 2024-03-22 23:38:26
# - version: 4.2.1
#============================================================
## 图层时间线控制
##
##处理帧轨道
class_name ImageLayerTimeline
extends Control


## 时间线上显示的帧进行偏移偏移
@export var offset_frame: int :
	set(v):
		offset_frame = v
		if not is_inside_tree():
			await ready
		# 帧偏移
		var frame_track:FrameTrack
		for layer_id in _layer_id_to_frame_track:
			frame_track = get_frame_track(layer_id)
			frame_track.offset_frame = offset_frame


@onready var frame_track_item_template: HBoxContainer = %FrameTrackItemTemplate
@onready var frame_track_container: VBoxContainer = %FrameTrackContainer

var _coords_to_images : Dictionary = {}
var _layer_id_to_frame_track : Dictionary = {}


#============================================================
#  内置
#============================================================
func _init() -> void:
	ProjectData.newly_layer.connect(create_layer)
	ProjectData.texture_changed.connect(
		func(layer_id, frame_id, texture):
			var frame_track = get_frame_track(layer_id)
			frame_track.queue_redraw()
	)


#============================================================
#  自定义
#============================================================
func get_frame_track(layer_id: float) -> FrameTrack:
	var frame_item : Node = _layer_id_to_frame_track[layer_id]
	var frame_track : FrameTrack = frame_item.get_node("FrameTrack")
	return frame_track

## 创建层级
func create_layer(layer_id: float):
	# 帧轨道
	var item = frame_track_item_template.duplicate()
	frame_track_container.add_child(item)
	frame_track_container.move_child(item, 0)
	_layer_id_to_frame_track[layer_id] = item
	# 层级名称
	var label = item.get_node("Label")
	label.text = "Layer %d" % layer_id
	# 轨道帧
	var frame_track : FrameTrack = get_frame_track(layer_id)
	frame_track.layer_id = layer_id
	frame_track.clicked_frame.connect(_clicked_frame.bind(layer_id))



#============================================================
#  连接信号
#============================================================
func _clicked_frame(frame_id: float, layer_id: float):
	# 超出范围
	if frame_id > ProjectData.get_max_frame_id():
		return
	# 选中层
	if not Input.is_key_pressed(KEY_SHIFT):
		ProjectData.clear_select_layer()
	ProjectData.add_select_layer(layer_id)

func _on_new_layer_pressed() -> void:
	ProjectData.new_layer()

func _on_new_frame_pressed() -> void:
	ProjectData.new_frame()

func _on_play_pressed() -> void:
	pass # Replace with function body.

func _on_stop_pressed() -> void:
	pass # Replace with function body.


