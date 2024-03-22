#============================================================
#    Move
#============================================================
# - author: zhangxuetu
# - datetime: 2024-03-22 18:09:00
# - version: 4.2.1
#============================================================
## 移动工具
class_name Tool_Move
extends ToolBase


signal ready_move()
## 移动画布的位置
signal move_position(last_point: Vector2i, current_point: Vector2i)
## 移动完成
signal move_finished()


func _pressed():
	ready_move.emit()


func _press_move(last_point: Vector2i, current_point: Vector2i):
	move_position.emit(last_point, current_point)


func _release():
	move_finished.emit()

