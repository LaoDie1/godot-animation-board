#============================================================
#    Pen Setting
#============================================================
# - author: zhangxuetu
# - datetime: 2024-03-22 20:24:29
# - version: 4.2.1
#============================================================
extends ScrollContainer



func _on_pen_color_color_changed(color: Color) -> void:
	ProjectConfig.set_config(PropertyName.PEN.COLOR, color)

func _on_pen_line_width_value_changed(value: float) -> void:
	ProjectConfig.set_config(PropertyName.PEN.LINE_WIDTH, value)
