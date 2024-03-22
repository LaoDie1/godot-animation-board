@tool
extends EditorScript


func _run() -> void:
	_init_value(PropertyName)


static func _init_value(script: GDScript):
	var class_regex = RegEx.new()
	class_regex.compile("class\\s+(?<class_name>\\w+)\\s*:")
	var var_regex = RegEx.new()
	var_regex.compile("\\s+static\\s+var\\s+(?<var_name>\\w+)")
	
	# 分析
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
	var object = script.new()
	for c_name in data:
		var property_list = data[c_name]
		for property in property_list:
			object.set(property, "/" + c_name + "/" + property)
	

