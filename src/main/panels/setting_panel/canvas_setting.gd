#============================================================
#    Canvas Setting
#============================================================
# - author: zhangxuetu
# - datetime: 2024-03-25 00:41:41
# - version: 4.2.1
#============================================================
extends MarginContainer


@onready var background_color_button: ColorPickerButton = %BackgroundColorButton


func _ready() -> void:
	ProjectData.set_config(PropertyName.KEY.CANVAS_BACKGROUND_COLOR, background_color_button.color)



func _on_background_color_button_color_changed(color: Color) -> void:
	ProjectData.set_config(PropertyName.KEY.CANVAS_BACKGROUND_COLOR, color)
