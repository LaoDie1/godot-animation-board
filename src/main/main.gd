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


var _undo_redo : UndoRedo = UndoRedo.new()


#============================================================
#  内置
#============================================================
func _init() -> void:
	ProjectData.set_config(PropertyName.IMAGE.RECT, Rect2i(0, 0, 500, 500))
	# 切换帧
	ProjectData.frame_changed.connect(
		func(last_frame_id, frame_id):
			# 更新上一次的帧和层数据
			for layer_id in ProjectData.get_layer_ids():
				var image_layer : ImageLayer = canvas_container.get_image_layer(layer_id)
				var texture = image_layer.get_image_texture()
				ProjectData.update_texture(layer_id, last_frame_id, texture)
			
			# 加载当前帧和层的数据
			for layer_id in ProjectData.get_layer_ids():
				var data : Dictionary = ProjectData.get_image_data(layer_id, frame_id)
				var image_layer : ImageLayer = canvas_container.get_image_layer(layer_id)
				image_layer.load_data(layer_id, frame_id)
	)
	


func _ready() -> void:
	_init_menu()
	
	# 工具栏
	var tool_button_group : ButtonGroup = ButtonGroup.new()
	for tool_button:BaseButton in tool_button_container.get_children():
		tool_button.button_group = tool_button_group
	tool_button_group.pressed.connect(
		func(tool_button: BaseButton):
			var tool_name = tool_button.name
			canvas_container.active_tool(tool_name)
	)
	tool_button_container.get_child(0).button_pressed = true
	
	# 创建图层
	ProjectData.new_frame()
	ProjectData.new_layer()
	# 选中图层1
	layer_buttons.select_layer(1)



#============================================================
#  自定义
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
			"Add Frame", "Add Frame To Front",
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
		"/Layer/Add Frame To Front": {"keycode": KEY_INSERT, "shift": true},
		
	})
	menu.set_menu_disabled_by_path("/Edit/Undo", true)
	menu.set_menu_disabled_by_path("/Edit/Redo", true)


func _add_undo_redo(action_name: String, do_method: Callable, undo_method: Callable, execute_do: bool = true):
	_undo_redo.create_action(action_name)
	_undo_redo.add_do_method(do_method)
	_undo_redo.add_undo_method(undo_method)
	_undo_redo.commit_action(execute_do)
	menu.set_menu_disabled_by_path("/Edit/Undo", false)






#============================================================
#  连接信号
#============================================================
func _on_simple_menu_menu_pressed(idx: int, menu_path: StringName) -> void:
	match menu_path:
		#"/File/Save":
			#pass
		#
		"/Edit/Undo":
			_undo_redo.undo()
			menu.set_menu_disabled_by_path("/Edit/Undo", not _undo_redo.has_undo())
			menu.set_menu_disabled_by_path("/Edit/Redo", not _undo_redo.has_redo())
			
		"/Edit/Redo":
			_undo_redo.redo()
			menu.set_menu_disabled_by_path("/Edit/Undo", not _undo_redo.has_undo())
			menu.set_menu_disabled_by_path("/Edit/Redo", not _undo_redo.has_redo())
		
		"/Layer/Add Layer":
			ProjectData.new_layer()
			
		"/Layer/Add Frame":
			ProjectData.new_frame()
		
		"/Layer/Add Frame To Front":
			var current_frame_id = ProjectData.get_current_frame_id()
			ProjectData.new_frame(ProjectData.DEFAULT_INT, current_frame_id)
			ProjectData.update_current_frame(current_frame_id)
		
		_:
			printerr("没有实现功能：", menu_path)

