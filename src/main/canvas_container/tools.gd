#============================================================
#    Tools
#============================================================
# - author: zhangxuetu
# - datetime: 2024-03-22 23:23:27
# - version: 4.2.1
#============================================================
class_name Tools
extends Node


var _current_tool : ToolBase # 当前使用的工具


#============================================================
#  内置
#============================================================
func _init() -> void:
	ProjectData.listen_config(PropertyName.KEY.CURRENT_TOOL, func(last, tool_name: String):
		# 切换使用的工具
		var tool : ToolBase = get_tool(tool_name)
		if tool == _current_tool:
			return
		if _current_tool != null:
			_current_tool.deactive()
		_current_tool = tool
		_current_tool.active()
	)


#============================================================
#  自定义
#============================================================
func set_input_board(input_board):
	for tool:ToolBase in get_children():
		tool.input_board = input_board

func get_tool(tool_name: String) -> ToolBase:
	return get_node(tool_name)
