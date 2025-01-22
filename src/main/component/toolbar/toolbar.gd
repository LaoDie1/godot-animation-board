#============================================================
#    Toolbar
#============================================================
# - author: zhangxuetu
# - datetime: 2024-03-24 17:16:38
# - version: 4.2.1
#============================================================
class_name ToolBar
extends BoxContainer


#============================================================
#  内置
#============================================================
func _init() -> void:
	ProjectData.listen_config(PropertyName.KEY.CURRENT_TOOL, func(last, curr):
		var tool_button = get_node(curr) as BaseButton
		if not tool_button.button_pressed:
			tool_button.button_pressed = true
	)


func _ready() -> void:
	# 工具栏
	var tool_button_group : ButtonGroup = ButtonGroup.new()
	for tool_button in get_children():
		if tool_button is BaseButton:
			tool_button.button_group = tool_button_group
	tool_button_group.pressed.connect(
		func(tool_button: BaseButton):
			var tool_name = tool_button.name
			ProjectData.active_tool(tool_name)
	, Object.CONNECT_DEFERRED)
	get_child(0).button_pressed = true
