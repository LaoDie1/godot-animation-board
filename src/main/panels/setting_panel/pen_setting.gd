#============================================================
#    Pen Setting
#============================================================
# - author: zhangxuetu
# - datetime: 2024-03-22 20:24:29
# - version: 4.2.1
#============================================================
extends MarginContainer


@onready var pen_color: ColorPickerButton = %PenColor
@onready var pen_line_width: SpinBox = %PenLineWidth
@onready var pen_shape: OptionButton = %PenShape


#============================================================
#  内置
#============================================================
func _ready() -> void:
	pen_line_width.get_line_edit().focus_mode = Control.FOCUS_CLICK
	pen_shape.clear()
	for shape_name:String in PropertyName.SHAPE.keys():
		pen_shape.add_item(shape_name.capitalize())
	ProjectData.set_config(PropertyName.PEN.COLOR, pen_color.color)
	ProjectData.set_config(PropertyName.PEN.LINE_WIDTH, pen_line_width.value)


#============================================================
#  连接信号
#============================================================
func _on_pen_color_color_changed(color: Color) -> void:
	ProjectData.set_config(PropertyName.PEN.COLOR, color)

func _on_pen_line_width_value_changed(value: float) -> void:
	ProjectData.set_config(PropertyName.PEN.LINE_WIDTH, value)

func _on_pen_shape_item_selected(index: int) -> void:
	ProjectData.set_config(PropertyName.PEN.SHAPE, index)

