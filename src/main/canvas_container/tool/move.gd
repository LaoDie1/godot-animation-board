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
signal move_position(last_point: Vector2, current_point: Vector2)
## 移动完成
signal move_finished()


func _pressed(button_index):
	ready_move.emit()


func _press_moving(last_point: Vector2, current_point: Vector2):
	move_position.emit(last_point, current_point)


func _released(button_index):
	move_finished.emit()
