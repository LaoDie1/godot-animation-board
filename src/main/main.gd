#============================================================
#    Main
#============================================================
# - author: zhangxuetu
# - datetime: 2024-03-21 23:38:22
# - version: 4.2.1
#============================================================
class_name AnimationBoardMain
extends Control


@onready var menu: SimpleMenu = %SimpleMenu
@onready var canvas_container: CanvasContainer = %CanvasContainer
@onready var layer_buttons: LayerButtons = %LayerButtons
@onready var tool_button_container: BoxContainer = %tool_button_container
@onready var image_layer_timeline: ImageLayerTimeline = %ImageLayerTimeline
@onready var current_frame_label: Label = %CurrentFrameLabel


#============================================================
#  内置
#============================================================
func _init() -> void:
	# 切换帧
	ProjectData.frame_changed.connect(
		func(last_frame_id, frame_id):
			current_frame_label.text = " Frame ID: %s" % str(frame_id)
			
			# 加载当前帧和层的数据
			for layer_id in ProjectData.get_layer_ids():
				var data : Dictionary = ProjectData.get_image_data(layer_id, frame_id)
				var image_layer : ImageLayer = canvas_container.get_image_layer(layer_id)
				image_layer.load_data(layer_id, frame_id)
			
	)
	# 新文件
	ProjectData.new_file.connect(
		func():
			# 创建图层
			var frame_id = ProjectData.create_new_frame_id()
			ProjectData.new_frame(frame_id)
			ProjectData.new_layer()
			# 选中图层1
			layer_buttons.select_layer(1)
			
			current_frame_label.text = " Frame ID: %s" % str(ProjectData.get_current_frame_id())
	)


func _ready() -> void:
	#theme = preload("res://src/main/theme.tres")
	
	_init_menu()
	
	ProjectData.set_config(PropertyName.IMAGE.RECT, Rect2i(0, 0, 500, 500))
	
	# 工具栏
	var tool_button_group : ButtonGroup = ButtonGroup.new()
	for tool_button:BaseButton in tool_button_container.get_children():
		tool_button.button_group = tool_button_group
	tool_button_group.pressed.connect(
		func(tool_button: BaseButton):
			var tool_name = tool_button.name
			ProjectData.set_config(PropertyName.TOOL.CURRENT, tool_name)
	)
	tool_button_container.get_child(0).button_pressed = true
	
	# 新建文件
	ProjectData.menu_new()



#============================================================
#  菜单
#============================================================
func _init_menu():
	menu.init_menu({
		"File": [
			"Open", "New", "Save", "Save As", "-",
			{"Export": [ "PNG", "JPG"]},
		],
		"Edit": ["Undo", "Redo"],
		"Layer": [
			"Add Layer", "-", 
			"Add Frame", "Insert Frame",
		],
	})
	
	menu.init_shortcut({
		"/File/Open": {"keycode": KEY_O, "ctrl": true},
		"/File/New": {"keycode": KEY_N, "ctrl": true},
		"/File/Save": {"keycode": KEY_S, "ctrl": true},
		"/File/Save As": {"keycode": KEY_S, "ctrl": true, "shift": true},
		
		"/Edit/Undo": {"keycode": KEY_Z, "ctrl": true},
		"/Edit/Redo": {"keycode": KEY_Z, "ctrl": true, "shift": true},
		
		"/Layer/Add Frame": {"keycode": KEY_INSERT},
		"/Layer/Insert Frame": {"keycode": KEY_INSERT, "shift": true},
		
	})
	
	ProjectData.menu = menu
	menu.set_menu_disabled_by_path("/Edit/Undo", true)
	menu.set_menu_disabled_by_path("/Edit/Redo", true)



#============================================================
#  连接信号
#============================================================
func _on_simple_menu_menu_pressed(idx: int, menu_path: StringName) -> void:
	match menu_path:
		#"/File/Save":
			#pass
		"/File/New": ProjectData.menu_new()
		"/Edit/Undo": ProjectData.menu_undo()
		"/Edit/Redo": ProjectData.menu_redo()
		"/Layer/Add Layer": ProjectData.menu_add_layer()
		"/Layer/Add Frame": ProjectData.menu_add_frame()
		"/Layer/Insert Frame": ProjectData.menu_insert_frame()
			
		_:
			printerr("没有实现功能：", menu_path)


func _on_image_layer_timeline_play_state_changed(state: Variant) -> void:
	match state:
		ImageLayerTimeline.PLAY_BACKWARD, \
		ImageLayerTimeline.PLAY_FORWARD:
			canvas_container.onionskin.visible = false
		
		ImageLayerTimeline.PAUSE:
			canvas_container.onionskin.visible = ProjectData.get_config(PropertyName.TOOL.ONIONSKIN, false)
