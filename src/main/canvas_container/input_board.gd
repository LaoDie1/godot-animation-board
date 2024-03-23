#============================================================
#    Input Board
#============================================================
# - author: zhangxuetu
# - datetime: 2024-03-22 17:34:38
# - version: 4.2.1
#============================================================
## 接收输入操作的面板
class_name InputBoard
extends Control


## 点击
signal pressed()
## 点击移动
signal press_move(last_point: Vector2i, current_point: Vector2i)
## 松开
signal release()


var _pressed : bool = false # 是否正在按下
var _pressed_point : Vector2i # 按下时的鼠标位置
var _release_point : Vector2i # 松开时的位置
var _current_point : Vector2i # 当前鼠标的位置
var _last_point : Vector2i # 上次鼠标位置


#============================================================
#  内置
#============================================================
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if _pressed:
			_current_point = Vector2i(get_local_mouse_position())
			press_move.emit(_last_point, _current_point)
			_last_point = _current_point
	
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_pressed = event.pressed
			if event.pressed:
				_pressed_point = Vector2i(get_local_mouse_position())
				_last_point = _pressed_point
				pressed.emit()
			else:
				_release_point = Vector2i(get_local_mouse_position())
				release.emit()


#============================================================
#  自定义
#============================================================
## 获取上次点击时的位置点
func get_last_pressed_point() -> Vector2i:
	return _pressed_point

## 获取上次松开鼠标后的点
func get_last_release_point() -> Vector2i:
	return _release_point

