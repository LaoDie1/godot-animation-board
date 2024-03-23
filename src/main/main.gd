#============================================================
#    Main
#============================================================
# - author: zhangxuetu
# - datetime: 2024-03-21 23:38:22
# - version: 4.2.1
#============================================================
class_name DrawBoardMain
extends Control


@onready var menu: SimpleMenu = %SimpleMenu
@onready var draw_container: DrawContainer = %DrawContainer
@onready var layer_buttons: LayerButtons = %LayerButtons
@onready var tool_button_container: BoxContainer = %tool_button_container
@onready var image_layer_timeline: ImageLayerTimeline = %ImageLayerTimeline


var _undo_redo : UndoRedo = UndoRedo.new()


#============================================================
#  内置
#============================================================
func _init() -> void:
	ProjectData.set_config(PropertyName.IMAGE.SIZE, Vector2i(500, 500))
	# 切换帧
	ProjectData.frame_changed.connect(
		func(last_frame_id, frame_id):
			# 更新上一次的帧和层数据
			for layer_id in ProjectData.get_layer_ids():
				var image_layer : ImageLayer = draw_container.get_image_layer(layer_id)
				var texture = image_layer.get_image_texture()
				ProjectData.update_texture(layer_id, last_frame_id, texture)
			
			# 加载当前帧和层的数据
			for layer_id in ProjectData.get_layer_ids():
				var data : Dictionary = ProjectData.get_image_data(layer_id, frame_id)
				var image_layer : ImageLayer = draw_container.get_image_layer(layer_id)
				image_layer.load_data(data)
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
			draw_container.active_tool(tool_name)
	)
	tool_button_container.get_child(0).button_pressed = true
	
	# 创建图层
	ProjectData.new_frame()
	ProjectData.new_layer()
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
	})
	menu.init_shortcut({
		"/File/Open": {"keycode": KEY_O, "ctrl": true},
		"/File/New": {"keycode": KEY_N, "ctrl": true},
		"/File/Save": {"keycode": KEY_S, "ctrl": true},
		"/File/Save As": {"keycode": KEY_S, "ctrl": true, "shift": true},
		"/Edit/Undo": {"keycode": KEY_Z, "ctrl": true},
		"/Edit/Redo": {"keycode": KEY_Z, "ctrl": true, "shift": true},
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
		
		_:
			printerr("没有实现功能：", menu_path)


func _on_layer_buttons_selected_layers() -> void:
	ProjectData.clear_select_layer()
	ProjectData.add_select_layers(layer_buttons.get_selected_layer_ids())


func _on_image_layer_timeline_layer_frame_changed(last_layer_id: int, last_frame_id: int, layer_id: int, frame_id: int) -> void:
	ProjectData.update_current_frame(frame_id)
