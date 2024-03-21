#============================================================
#    Main
#============================================================
# - author: zhangxuetu
# - datetime: 2024-03-21 23:38:22
# - version: 4.2.1
#============================================================
extends Control


var _undo_redo : UndoRedo = UndoRedo.new()


@onready var menu: SimpleMenu = %SimpleMenu
@onready var drawing_board: DrawBoard = %DrawingBoard


#============================================================
#  内置
#============================================================
func _ready() -> void:
	drawing_board.new_image(Vector2i(500, 500))
	
	menu.init_menu({
		"File": [
			"Open", "New", "Save", "Save As", "-",
			{"Export": [ "PNG", "JPG", "GIF"]},
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


func _on_drawing_board_draw_finished() -> void:
	var draw_before_colors : Dictionary = drawing_board._draw_before_colors.duplicate(true)
	var drawn_colors : Dictionary = drawing_board._drawn_colors.duplicate(true)
	_add_undo_redo("绘制", 
		drawing_board.set_color_by_data.bind(drawn_colors),
		drawing_board.set_color_by_data.bind(draw_before_colors),
		false
	)


