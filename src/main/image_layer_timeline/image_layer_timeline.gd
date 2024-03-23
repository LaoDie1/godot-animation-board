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

enum {
	PLAY_FORWARD = -1, ## 向前播放
	PAUSE = 0, ## 暂停
	PLAY_BACKWARD = 1, ## 向后播放
}

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
@onready var buttons_container: HBoxContainer = %ButtonsContainer

var _coords_to_images : Dictionary = {}
var _layer_id_to_frame_track : Dictionary = {}
var _play_status : int = PAUSE:
	set(v):
		_play_status = clampi(v, PLAY_FORWARD, PLAY_BACKWARD)
		set_process(_play_status != PAUSE)
var _play_time : float = 0.0


#============================================================
#  内置
#============================================================
func _init() -> void:
	ProjectData.new_file.connect(
		func():
			offset_frame = 0
			for frame_id in _layer_id_to_frame_track:
				_layer_id_to_frame_track[frame_id].queue_free()
			_layer_id_to_frame_track.clear()
			create_layer(1)
	)
	ProjectData.newly_layer.connect(create_layer)
	ProjectData.texture_changed.connect(
		func(layer_id, frame_id, texture):
			var frame_track = get_frame_track(layer_id)
			frame_track.queue_redraw()
	)
	ProjectData.removed_layer.connect(
		func(layer_id):
			var frame_track_item : Control = _layer_id_to_frame_track[layer_id]
			frame_track_item.get_parent().remove_child(frame_track_item)
			update_delete_status()
	)
	ProjectData.removed_frame.connect(
		func(frame_id):
			for layer_id in ProjectData.get_layer_ids():
				var frame_track_item : Control = _layer_id_to_frame_track[layer_id]
				var frame_track : FrameTrack = frame_track_item.get_node("FrameTrack")
				frame_track.queue_redraw()
	)
	ProjectData.select_layers_changed.connect(
		func():
			for layer_id in ProjectData.get_layer_ids():
				get_frame_track(layer_id).queue_redraw()
	)


func _ready() -> void:
	for button in buttons_container.get_children():
		if button is BaseButton:
			button.focus_mode = Control.FOCUS_NONE
	set_process(false)


func _process(delta: float) -> void:
	_play_time -= delta
	if _play_time <= 0: # 到达间隔时间
		_play_time = 0.25
		var point = ProjectData.get_current_frame_point()
		point += _play_status
		if _play_status == PLAY_BACKWARD and point >= ProjectData.get_frame_count():
			point = 0
		elif _play_status == PLAY_FORWARD and point < 0:
			point = ProjectData.get_frame_count() - 1
		ProjectData.update_current_frame_by_point(point)


#============================================================
#  自定义
#============================================================
func get_frame_track(layer_id: float) -> FrameTrack:
	var frame_item : Node = _layer_id_to_frame_track[layer_id]
	var frame_track : FrameTrack = frame_item.get_node("FrameTrack")
	return frame_track

func update_delete_status():
	if ProjectData.get_layer_count() > 1:
		for item in _layer_id_to_frame_track.values():
			item.get_node("Delete").disabled = false
	else:
		for item in _layer_id_to_frame_track.values():
			item.get_node("Delete").disabled = true

## 创建层级
func create_layer(layer_id: float):
	# 帧轨道
	var item : Control
	if not _layer_id_to_frame_track.has(layer_id):
		item = frame_track_item_template.duplicate()
		_layer_id_to_frame_track[layer_id] = item
	else:
		item = _layer_id_to_frame_track[layer_id]
	if not item.is_inside_tree():
		frame_track_container.add_child(item)
	var order = ProjectData.get_layer_point(layer_id)
	if order > -1:
		order = ProjectData.get_layer_count() - order - 1
		frame_track_container.move_child(item, order)
	
	# 层级名称
	var label = item.get_node("Label")
	label.text = "Layer %d" % layer_id
	
	# 删除按钮
	var btn_delete = item.get_node("Delete") as Button
	btn_delete.pressed.connect(ProjectData.remove_layer.bind(layer_id))
	update_delete_status()
	
	# 轨道帧
	var frame_track : FrameTrack = get_frame_track(layer_id)
	frame_track.layer_id = layer_id
	if not frame_track.clicked_frame.is_connected(_clicked_frame):
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
	ProjectData.menu_add_layer()

func _on_new_frame_pressed() -> void:
	ProjectData.menu_add_frame()

func _on_onionskin_toggled(toggled_on: bool) -> void:
	ProjectData.set_config(PropertyName.TOOL.ONIONSKIN, toggled_on)

func _on_insert_frame_pressed() -> void:
	ProjectData.menu_insert_frame()


func _on_play_pressed() -> void:
	if ProjectData.get_frame_count() > 1:
		if _play_status == PAUSE:
			_play_status = PLAY_BACKWARD
		else:
			_play_status = PAUSE


func _on_stop_pressed() -> void:
	pass # Replace with function body.
