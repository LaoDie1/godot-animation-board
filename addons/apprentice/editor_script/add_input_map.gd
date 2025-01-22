#============================================================
#    Add Input Map
#============================================================
# - author: zhangxuetu
# - datetime: 2025-01-22 14:41:29
# - version: 4.4.0.dev
#============================================================
@tool
extends EditorScript


func _run() -> void:
	# 暂时无效
	
	var map = {
		"jump": "J",
		"move_left": "A",
		"move_right": "D",
		"move_up": "W",
		"move_down": "S",
	}
	
	for name in map:
		if not InputMap.has_action(name):
			InputMap.add_action(name)
		var items = map[name]
		if items is Array:
			for item in items:
				add_item(name, item)
		else:
			add_item(name, items)
	print("完成")


func add_item(name, item) -> void:
	var event = InputEventKey.new()
	if item is String:
		event.keycode = OS.find_keycode_from_string(item)
	elif item is int:
		event.keycode = item
	else:
		return
	if event.keycode != 0:
		InputMap.action_add_event(name, event)
