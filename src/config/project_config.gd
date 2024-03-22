#============================================================
#    Config Data
#============================================================
# - author: zhangxuetu
# - datetime: 2024-03-22 16:26:16
# - version: 4.2.1
#============================================================
extends Node


## 配置发生改变
signal config_changed(property:String, last_value, value)


var _data: Dictionary = {}


#============================================================
#  内置
#============================================================
func _init() -> void:
	init_value()


#============================================================
#  自定义
#============================================================
## 更新 PropertyName 子类的静态变量的值为自身的名称
static func init_value():
	var class_regex = RegEx.new()
	class_regex.compile("^class\\s+(?<class_name>\\w+)\\s*:")
	var var_regex = RegEx.new()
	var_regex.compile("\\s+static\\s+var\\s+(?<var_name>\\w+)")
	
	# 分析
	var script = (PropertyName as GDScript)
	var data : Dictionary = {}
	var last_class : String = ""
	var last_var_list : Array
	var lines = script.source_code.split("\n")
	var result : RegExMatch
	for line in lines:
		result = class_regex.search(line)
		if result:
			# 类名
			last_class = result.get_string("class_name")
			last_var_list =[]
			data[last_class] = last_var_list
		else:
			# 变量名
			if last_class != "":
				result = var_regex.search(line)
				if result:
					var var_name = result.get_string("var_name")
					last_var_list.append(var_name)
	
	# 设置值
	var const_map = script.get_script_constant_map()
	var object : Object
	for c_name:String in data:
		object = const_map[c_name].new()
		var property_list = data[c_name]
		for property:String in property_list:
			object[property] = "/" + c_name.to_lower() + "/" + property.to_lower()


func set_config(property: String, value):
	var last_value = _data.get(property)
	if typeof(last_value) != typeof(value) or last_value != value:
		_data[property] = value
		config_changed.emit(property, last_value, value)

func get_config(property, default = null):
	return _data.get(property, default)

