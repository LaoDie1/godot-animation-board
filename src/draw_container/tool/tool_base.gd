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
func get_last_pressed_point() -> Vector2i:
	return input_board.get_last_pressed_point()


## 激活工具
func active():
	input_board.pressed.connect(_pressed)
	input_board.press_move.connect(_press_move)
	input_board.release.connect(_release)


## 取消激活工具
func deactive():
	input_board.pressed.disconnect(_pressed)
	input_board.press_move.disconnect(_press_move)
	input_board.release.disconnect(_release)



#============================================================
#  连接信号
#============================================================
func _pressed():
	pass


func _press_move(last_point: Vector2i, current_point: Vector2i):
	pass


func _release():
	pass
