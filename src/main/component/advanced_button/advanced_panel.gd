#============================================================
#    Advanced Button Panel
#============================================================
# - author: zhangxuetu
# - datetime: 2024-03-24 21:48:01
# - version: 4.2.1
#============================================================
class_name AdvancedPanel
extends ReferenceRect


var _pressing = false
var _pressed_node_point := Vector2()
var _last_press_point := Vector2()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if _pressing:
			var diff = get_global_mouse_position() - _last_press_point
			global_position = _pressed_node_point + diff
			
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_pressing = event.pressed
			if event.pressed:
				_last_press_point = get_global_mouse_position()
				_pressed_node_point = global_position
			
