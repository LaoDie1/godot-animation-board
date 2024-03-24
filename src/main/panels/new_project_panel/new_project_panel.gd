#============================================================
#    New Project Panel
#============================================================
# - author: zhangxuetu
# - datetime: 2024-03-25 00:55:19
# - version: 4.2.1
#============================================================
extends Control


signal created()
signal cancel()


@onready var canvas_width: SpinBox = %CanvasWidth
@onready var canvas_height: SpinBox = %CanvasHeight
@onready var create_button: Button = %CreateButton
@onready var cancel_button: Button = %CancelButton


#============================================================
#  内置
#============================================================
func _ready() -> void:
	create_button.focus_mode = Control.FOCUS_CLICK
	cancel_button.focus_mode = Control.FOCUS_CLICK


#============================================================
#  连接信号
#============================================================
func _on_create_button_pressed() -> void:
	var rect = Rect2i(0, 0, canvas_width.value, canvas_height.value)
	ProjectData.set_config(PropertyName.KEY.IMAGE_RECT, rect, false)
	created.emit()


func _on_cancel_button_pressed() -> void:
	cancel.emit()
