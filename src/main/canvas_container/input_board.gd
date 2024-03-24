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
signal pressed(button_index: int)
## 点击移动
signal press_moving(last_point: Vector2, current_point: Vector2)
## 松开
signal released(button_index: int)
## 滚轮滚动。direction: 滚动方向。factor: 滚动的精度
signal rolling(direction, factor: float)


var _last_button_index : int = MOUSE_BUTTON_LEFT
var _pressed : bool = false # 是否正在按下
var _pressed_point : Vector2 # 按下时的鼠标位置
var _release_point : Vector2 # 松开时的位置
var _current_point : Vector2 # 当前鼠标的位置
var _last_point : Vector2 # 上次鼠标位置


#============================================================
#  内置
#============================================================
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if _pressed:
			_current_point = Vector2(get_local_mouse_position())
			if _last_point != _current_point:
				press_moving.emit(_last_point, _current_point)
				_last_point = _current_point
	
	elif event is InputEventMouseButton:
		match event.button_index:
			# 鼠标点击
			MOUSE_BUTTON_LEFT, \
			MOUSE_BUTTON_MIDDLE, \
			MOUSE_BUTTON_RIGHT:
				_last_button_index = event.button_index
				_pressed = event.pressed
				if event.pressed:
					_pressed_point = get_local_mouse_position()
					_last_point = _pressed_point
					pressed.emit(event.button_index)
				else:
					_release_point = get_local_mouse_position()
					released.emit(event.button_index)
			
			# 鼠标滚轮
			MOUSE_BUTTON_WHEEL_DOWN:  rolling.emit( Vector2.DOWN, event.factor )
			MOUSE_BUTTON_WHEEL_UP:    rolling.emit( Vector2.UP, event.factor )
			MOUSE_BUTTON_WHEEL_RIGHT: rolling.emit( Vector2.RIGHT, event.factor )
			MOUSE_BUTTON_WHEEL_LEFT:  rolling.emit( Vector2.LEFT, event.factor )
			


#============================================================
#  自定义
#============================================================
## 获取上次点击时的位置点
func get_last_pressed_point() -> Vector2:
	return _pressed_point

func get_last_pressed_pointi() -> Vector2i:
	return Vector2i(_pressed_point)


## 获取上次松开鼠标后的点
func get_last_release_point() -> Vector2:
	return _release_point

func get_last_release_pointi() -> Vector2i:
	return Vector2i(_release_point)

