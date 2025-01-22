#============================================================
#    Tool Base
#============================================================
# - author: zhangxuetu
# - datetime: 2024-03-22 17:50:31
# - version: 4.2.1
#============================================================
## 基础操作工具
##
##所有工具类的基础类。通过调用 [method active] 激活使用这个工具，会连接调用当前面板的操作信号。
##重写下面的连接信号进行处理
class_name ToolBase
extends Node


var input_board : InputBoard
var image_rect : Rect2i


#============================================================
#  自定义
#============================================================
func _pressed(button_index: int):
	pass

func _press_moving(last_point: Vector2, current_point: Vector2):
	pass

func _released(button_index):
	pass

func _rolling(direction: Vector2, factor: float):
	pass


func get_last_button_index() -> int:
	return input_board._last_button_index

func get_last_pressed_point() -> Vector2:
	return input_board.get_last_pressed_point()

func get_current_point() -> Vector2:
	return input_board.get_local_mouse_position()

## 激活工具
func active():
	input_board.pressed.connect(_pressed)
	input_board.press_moving.connect(_press_moving)
	input_board.released.connect(_released)
	input_board.rolling.connect(_rolling)

## 取消激活工具
func deactive():
	input_board.pressed.disconnect(_pressed)
	input_board.press_moving.disconnect(_press_moving)
	input_board.released.disconnect(_released)
	input_board.rolling.disconnect(_rolling)
