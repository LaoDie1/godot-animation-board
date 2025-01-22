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
@onready var layer_buttons: LayerButtons = %ImageLayers
@onready var toolbar: ToolBar = %Toolbar
@onready var image_layer_timeline: ImageLayerTimeline = %ImageLayerTimeline
@onready var current_frame_label: Label = %CurrentFrameLabel
@onready var export_window: Window = %ExportWindow
@onready var export_panel: ExportPanel = %ExportPanel
@onready var new_project_window: Window = %NewProjectWindow
@onready var setting_tab_container: TabContainer = %SettingTabContainer


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
	ProjectData.newly_file.connect(
		func():
			# 创建图层
			var frame_id = ProjectData.create_new_frame_id()
			ProjectData.new_frame(frame_id)
			ProjectData.new_layer()
			# 选中图层1
			layer_buttons.select_layer(1)
			
			current_frame_label.text = " Frame ID: %s" % str(ProjectData.get_current_frame_id())
	)
	
	ProjectData.listen_config(PropertyName.KEY.CURRENT_TOOL, func(last, curr: String):
		var node = setting_tab_container.get_node_or_null(curr.capitalize())
		if node:
			setting_tab_container.current_tab = node.get_index()
	)


func _ready() -> void:
	ProjectData.set_config(PropertyName.KEY.IMAGE_RECT, Rect2i(0, 0, 64, 64))
	# 新建文件
	ProjectData.menu_new()
	# 使用钢笔工具
	ProjectData.active_tool(PropertyName.TOOL_NAME.PEN)
	
	_init_menu()
	
	#theme = preload("res://src/main/theme.tres")



#============================================================
#  菜单
#============================================================
func _init_menu():
	menu.init_menu({
		"File": [
			"Open", "New", "Save", "Save As", "-",
			"Export"
		],
		"Edit": ["Undo", "Redo"],
		"Layer": [
			"Add Layer", "-", 
			"Add Frame", "Insert Frame", "Previous Frame", "Next Frame", "-"
		],
	})
	
	menu.init_shortcut({
		"/File/Open": {"keycode": KEY_O, "ctrl": true},
		"/File/New": {"keycode": KEY_N, "ctrl": true},
		"/File/Save": {"keycode": KEY_S, "ctrl": true},
		"/File/Save As": {"keycode": KEY_S, "ctrl": true, "shift": true},
		"/File/Export": {"keycode": KEY_E, "ctrl": true},
		
		"/Edit/Undo": {"keycode": KEY_Z, "ctrl": true},
		"/Edit/Redo": {"keycode": KEY_Z, "ctrl": true, "shift": true},
		
		"/Layer/Add Frame": {"keycode": KEY_INSERT},
		"/Layer/Insert Frame": {"keycode": KEY_INSERT, "shift": true},
		"/Layer/Previous Frame": {"keycode": KEY_LEFT, "ctrl": true},
		"/Layer/Next Frame": {"keycode": KEY_RIGHT, "ctrl": true},
		
	})
	
	ProjectData.menu = menu
	menu.set_menu_disabled_by_path("/Edit/Undo", true)
	menu.set_menu_disabled_by_path("/Edit/Redo", true)



#============================================================
#  连接信号
#============================================================
func _on_simple_menu_menu_pressed(idx: int, menu_path: StringName) -> void:
	match menu_path:
		"/File/New": 
			new_project_window.popup_centered()
			
		#"/File/Save":
			#pass
			
		"/File/Export": 
			export_window.popup_centered()
			export_panel.update_content()
			
		"/Edit/Undo": ProjectData.menu_undo()
		"/Edit/Redo": ProjectData.menu_redo()
		"/Layer/Add Layer": ProjectData.menu_add_layer()
		"/Layer/Add Frame": ProjectData.menu_add_frame()
		"/Layer/Insert Frame": ProjectData.menu_insert_frame()
		"/Layer/Previous Frame": ProjectData.offset_current_frame(-1)
		"/Layer/Next Frame": ProjectData.offset_current_frame(1)
		_:
			printerr("没有实现功能：", menu_path)


func _on_image_layer_timeline_play_state_changed(state: Variant) -> void:
	match state:
		ImageLayerTimeline.PLAY_BACKWARD, \
		ImageLayerTimeline.PLAY_FORWARD:
			canvas_container.onionskin.visible = false
		
		ImageLayerTimeline.PAUSE:
			canvas_container.onionskin.visible = ProjectData.get_config(PropertyName.KEY.ONIONSKIN, false)


func _on_new_project_panel_created() -> void:
	ProjectData.menu_new()
	new_project_window.hide()
