#============================================================
#    Eraser Setting
#============================================================
# - author: zhangxuetu
# - datetime: 2024-03-24 18:38:38
# - version: 4.2.1
#============================================================
extends MarginContainer


@onready var eraser_size: SpinBox = %EraserSize
@onready var eraser_shape: OptionButton = %EraserShape


#============================================================
#  内置
#============================================================
func _init() -> void:
	ProjectData.config_changed.connect(
		func(property, last, curr):
			match property:
				PropertyName.ERASER.SIZE:
					eraser_size.value = curr
	)


func _ready() -> void:
	eraser_shape.clear()
	for shape_name:String in PropertyName.SHAPE.keys():
		eraser_shape.add_item(shape_name.capitalize())
	ProjectData.set_config(PropertyName.ERASER.SHAPE, eraser_size.value)
	ProjectData.set_config(PropertyName.ERASER.SIZE, eraser_size.value)


#============================================================
#  连接信号
#============================================================
func _on_eraser_size_value_changed(value: float) -> void:
	ProjectData.set_config(PropertyName.ERASER.SIZE, eraser_size.value)


func _on_eraser_shape_item_selected(index: int) -> void:
	ProjectData.set_config(PropertyName.ERASER.SHAPE, index)
