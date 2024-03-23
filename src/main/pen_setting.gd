#============================================================
#    Pen Setting
#============================================================
# - author: zhangxuetu
# - datetime: 2024-03-22 20:24:29
# - version: 4.2.1
#============================================================
extends ScrollContainer

@onready var pen_color: ColorPickerButton = %PenColor
@onready var pen_line_width: SpinBox = %PenLineWidth


#============================================================
#  内置
#============================================================
func _ready() -> void:
	ProjectData.set_config(PropertyName.PEN.COLOR, pen_color.color)
	ProjectData.set_config(PropertyName.PEN.LINE_WIDTH, pen_line_width.value)



#============================================================
#  连接信号
#============================================================
func _on_pen_color_color_changed(color: Color) -> void:
	ProjectData.set_config(PropertyName.PEN.COLOR, color)

func _on_pen_line_width_value_changed(value: float) -> void:
	ProjectData.set_config(PropertyName.PEN.LINE_WIDTH, value)
