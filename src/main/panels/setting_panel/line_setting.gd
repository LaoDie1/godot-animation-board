#============================================================
#    Line Setting
#============================================================
# - author: zhangxuetu
# - datetime: 2024-03-26 00:04:22
# - version: 4.2.1
#============================================================
extends MarginContainer


@onready var line_color: ColorPickerButton = %LineColor
@onready var line_width: SpinBox = %LineWidth


#============================================================
#  内置
#============================================================
func _ready() -> void:
	ProjectData.set_config(PropertyName.LINE.COLOR, line_color.color)
	ProjectData.set_config(PropertyName.LINE.WIDTH, line_width.value)


#============================================================
#  连接信号
#============================================================
func _on_color_color_changed(color: Color) -> void:
	ProjectData.set_config(PropertyName.LINE.COLOR, color)


func _on_width_value_changed(value: float) -> void:
	ProjectData.set_config(PropertyName.LINE.WIDTH, value)
