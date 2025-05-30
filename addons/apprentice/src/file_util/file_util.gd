#============================================================
#    File Utils
#============================================================
# - datetime: 2022-08-23 18:26:26
#============================================================
##  文件工具类
class_name FileUtil


# 用于递归扫描文件
class _Scanner:
	enum {
		DIRECTORY,
		FILE,
	}
	
	static func method(path: String, list: Array, recursive:bool, type):
		var directory := DirAccess.open(path)
		if directory == null:
			printerr("err: ", path)
			return
		directory.list_dir_begin()
		# 遍历文件
		var dir_list := []
		var file_list := []
		var file := ""
		file = directory.get_next()
		while file != "":
			# 目录
			if directory.current_is_dir() and not file.begins_with("."):
				dir_list.append( path.path_join(file) )
			# 文件
			elif not directory.current_is_dir() and not file.begins_with("."):
				file_list.append( path.path_join(file) )
			
			file = directory.get_next()
		# 添加
		if type == DIRECTORY:
			list.append_array(dir_list)
		else:
			list.append_array(file_list)
		# 递归扫描
		if recursive:
			for dir in dir_list:
				method(dir, list, recursive, type)


const ASCII = &"ascii" ## ASCII码
const UTF_8 = &"utf-8"
const UTF_16 = &"utf-16"
const UTF_32 = &"utf-32"
const WCHAR = &"wchar_t" ## 宽字符


##  保存字符串文件 
##[br]
##[br][code]file_path[/code]  文件路径
##[br][code]text[/code]  文本内容
##[br][code]encode[/code]  将当前 utf-8 编码的字符串转为这个编码
##[br]
##[br][code]return[/code]  返回是否保存成功
static func write_as_string(
	file_path:String, 
	text: String, 
	encode : StringName = UTF_8
) -> bool:
	var file := FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		var en_text : String
		match encode:
			ASCII: en_text = text.to_utf8_buffer().get_string_from_ascii()
			UTF_8: en_text = text
			UTF_16: en_text = text.to_utf8_buffer().get_string_from_utf16()
			UTF_32: en_text = text.to_utf8_buffer().get_string_from_utf32()
			WCHAR: en_text = text.to_utf8_buffer().get_string_from_wchar()
			_:
				assert(false, "错误的编码类型")
		file.store_string(en_text)
		file.flush() # 防止程序退出时没有保存
		return true
	push_error("打开文件时现错误：", file.get_open_error(), error_string(file.get_open_error()))
	return false

static func load_image(file_path: String) -> Image:
	match file_path.get_extension().to_lower():
		"svg":
			var image : Image = Image.new()
			image.load_svg_from_string( read_as_string(file_path) )
			return image
		"ico", "icon":
			var bytes : PackedByteArray = read_as_bytes(file_path)
			return load_ico_from_buffer(bytes)
	return Image.load_from_file(file_path)

static func save_image(image: Image, path: String):
	match path.get_extension().to_lower():
		"png": image.save_png(path)
		"jpg", "jpeg": image.save_jpg(path)
		"webp": image.save_webp(path)
		"exr": image.save_exr(path)

static func load_image_by_buffer(body: PackedByteArray) -> Image:
	var file_type : String = FileTypeUtil.get_type(body)
	var error : int = OK
	if file_type:
		var image := Image.new()
		if file_type.contains("png"):
			error = image.load_png_from_buffer(body)
		elif file_type.contains("webp"):
			error = image.load_webp_from_buffer(body)
		elif file_type.contains("jpeg"):
			error = image.load_jpg_from_buffer(body)
		elif file_type.contains("bmp"):
			error = image.load_bmp_from_buffer(body)
		elif file_type.contains("ico"):
			return load_ico_from_buffer(body)
		else:
			push_error("其他图片类型:", file_type, " |  ", body.slice(0, 16).hex_encode().to_upper())
		return image
	else:
		error = FAILED
	if error != OK:
		push_error("读取图片数据失败：", error, "  ", error_string(error))
	return null

## 文件是否存在
static func file_exists(file_path: String) -> bool:
	if not OS.has_feature("editor") and (file_path.begins_with("res://") or file_path.begins_with("user://")):
		return ResourceLoader.exists(file_path)
	else:
		return FileAccess.file_exists(file_path)

## 目录是否存在
static func dir_exists(dir_path: String) -> bool:
	return DirAccess.dir_exists_absolute(dir_path)


##  保存为CSV文件
##[br]
##[br][code]file_path[/code]  文件路径
##[br][code]list[/code]  每行的表格项
##[br][code]delim[/code]  分隔符。一般使用 [code],[/code] 作为分隔符
static func write_as_csv(file_path:String, list: Array[PackedStringArray], delim: String) -> bool:
	assert(len(delim) == 1, "分隔符长度必须为1！")
	var file := FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		for i in list:
			file.store_csv_line(i, delim)
		file.flush()
		return true
	return false


##  读取 CSV 文件
##[br]
##[br][code]file_path[/code]  文件路径
##[br][code]delim[/code]  分隔符
static func read_as_csv(file_path: String, delim: String = ",") -> Array[PackedStringArray]:
	var reader = FileAccess.open(file_path, FileAccess.READ)
	var list : Array[PackedStringArray] = []
	if reader:
		var line : PackedStringArray
		while true:
			line = reader.get_csv_line(",")
			list.append(line)
			if reader.eof_reached():
				break
	return list


## 以行读取字符内容 
static func read_as_lines(file_path: String) -> Array[String]:
	var reader = FileAccess.open(file_path, FileAccess.READ)
	var list : Array[String] = []
	if reader:
		while not reader.eof_reached():
			list.append(reader.get_line())
		list.append(reader.get_line())
	return list


##  读取字符串文件
##[br]
##[br]- [code]file_path[/code]  文件路径
##[br]- [code]skip_cr[/code]  跳过 [code]\r[/code] CR 字符。
##[codeblock]If skip_cr is true, carriage return characters (\r, CR) will be ignored when parsing the UTF-8, so that only line feed characters (\n, LF) represent a new line (Unix convention).[/codeblock]
##- [code]decode[/code]  将以这种编码格式读取字符串
static func read_as_string(
	file_path: String, 
	skip_cr: bool = false,
	decode: StringName = UTF_8,
) -> String:
	if file_exists(file_path):
		var file := FileAccess.open(file_path, FileAccess.READ)
		if file:
			match decode:
				ASCII: return file.get_file_as_bytes(file_path).get_string_from_ascii()
				UTF_8: return file.get_as_text(skip_cr)
				UTF_16: return file.get_file_as_bytes(file_path).get_string_from_utf16()
				UTF_32: return file.get_file_as_bytes(file_path).get_string_from_utf32()
				WCHAR: return file.get_file_as_bytes(file_path).get_string_from_wchar()
				_: assert(false, "错误的编码类型")
	else:
		printerr(file_path, "文件不存在")
	return ""


##  保存为变量数据
##[br]
##[br][code]file_path[/code]  文件路径
##[br][code]data[/code]  数据
##[br][code]full_objects[/code]  如果是 true，则允许编码对象（并且可能包含代码）。
static func write_as_var(file_path: String, data, full_objects: bool = false):
	var file := FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		file.store_var(data, full_objects)
		file.flush()
		return true
	return false


##  读取 var 数据
static func read_as_var(file_path: String, allow_objects: bool = false):
	if file_exists(file_path):
		var file := FileAccess.open(file_path, FileAccess.READ)
		if file:
			var data = file.get_var(allow_objects)
			file.flush()
			return data


## 保存为资源文件数据。这个文件的后缀名必须为 tres 或 res，否则会保存失败
static func write_as_res(file_path: String, data):
	var file := FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		var res = FileUtilRes.new()
		res.data = {
			"value": data
		}
		res.take_over_path(file_path)
		var r = ResourceSaver.save(res, file_path)
		if r == OK:
			return true
		print(r)
	return false


## 读取 res 文件数据
static func read_as_res(file_path: String):
	if file_exists(file_path):
		var res = ResourceLoader.load(file_path) as FileUtilRes
		return res.data.get("value")
	return null


## 写入为二进制文件
static func write_as_bytes(file_path: String, data) -> bool:
	var bytes = var_to_bytes_with_objects(data)
	var file := FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		file.store_buffer(bytes)
		file.flush()
		return true
	return false

## 读取字节数据
static func read_as_bytes(file_path: String) -> PackedByteArray:
	if file_exists(file_path):
		var file = FileAccess.open(file_path, FileAccess.READ)
		if file:
			return file.get_file_as_bytes(file_path)
	return PackedByteArray()

## 读取字节数据，并转为原来的数据
static func read_as_bytes_to_var(file_path: String):
	var bytes = read_as_bytes(file_path)
	if not bytes.is_empty():
		return bytes_to_var_with_objects(bytes)
	return null


## 转为 JSON 写入文件
static func write_as_json(file_path: String, data):
	var d = JSON.stringify(data)
	write_as_string(file_path, d)


##  读取 JSON 文件并解析数据
##[br]
##[br][code]file_path[/code]  文件路径
##[br][code]skip_cr[/code]  跳过 \r CR 字符
static func read_as_json(
	file_path: String, 
	skip_cr: bool = false
) -> Variant:
	var json = read_as_string(file_path, skip_cr)
	if json != null:
		return JSON.parse_string(json)
	return null


## 写入字符串变量数据
static func write_as_str_var(file_path: String, data):
	var d = var_to_str(data)
	write_as_string(file_path, d)


##  读取字符串类型的变量数据
static func read_as_str_var(file_path: String):
	var text = read_as_string(file_path)
	if text != null:
		return str_to_var(text)
	return null


##  扫描目录
static func scan_directory(dir: String, recursive:= false) -> Array[String]:
	assert(DirAccess.dir_exists_absolute(dir), "没有这个路径")
	var list : Array[String] = []
	_Scanner.method(dir, list, recursive, _Scanner.DIRECTORY)
	return list


##  扫描文件
##[br]
##[br][b]注意：[/b]Android 不可用，禁止扫描目录文件
static func scan_file(dir: String, recursive:= false) -> Array[String]:
	assert(DirAccess.dir_exists_absolute(dir), "没有这个路径")
	var list : Array[String] = []
	_Scanner.method(dir, list, recursive, _Scanner.FILE)
	return list


## 获取对象文件路径，如果返回为空，则没有
static func get_object_file(object: Object) -> String:
	if object:
		if object is Resource:
			return object.resource_path
		else:
			var script = object.get_script() as Script
			if script:
				return script.resource_path
	return ""


## 获取实际路径
static func get_real_path(path: String) -> String:
	if OS.has_feature("editor"):
		# 编辑器中运行
		return ProjectSettings.globalize_path(path)
	else:
		# 导出后运行
		if path.begins_with("res://"):
			var relative_path : String = path.substr("res://".length())
			return OS.get_executable_path().get_base_dir().path_join(relative_path)
		elif path.begins_with("user://"):
			var relative_path : String = path.substr("user://".length())
			return OS.get_user_data_dir().path_join(relative_path)
		elif path.is_relative_path():
			return OS.get_executable_path().get_base_dir().path_join(path)
		return path


##  保存点为场景文件
##[br]
##[br][code]node[/code]  节点
##[br][code]path[/code]  保存到的路径
##[br][code]save_flags[/code]  保存掩码，详见：[enum ResourceSaver.SaverFlags]
static func save_scene(node: Node, path: String, save_flags: int = ResourceSaver.FLAG_NONE):
	var scene = PackedScene.new()
	scene.pack(node)
	return ResourceSaver.save(scene, path, save_flags)

## 保存资源。path 为空时自动以 Resource.resource_path 作为路径
static func save_resource(resource: Resource, path: String = "", flags: int = 0):
	if path != "":
		resource.take_over_path(path)
	return ResourceSaver.save(resource, path, flags)


## 如果目录不存在，则进行创建
##[br]
##[br][code]return[/code] 如果不存在则进行创建并返回 [code]true[/code]，否则返回 [code]false[/code]
static func make_dir_if_not_exists(dir_path: String) -> bool:
	if not DirAccess.dir_exists_absolute(dir_path):
		DirAccess.make_dir_recursive_absolute(dir_path)
		return true
	return false


## 获取项目路径
static func get_project_real_path() -> String:
	if OS.has_feature("editor"):
		return ProjectSettings.globalize_path("res://")
	else:
		return OS.get_executable_path().get_base_dir()


## 文件分组匹配
##[br]
##[br][code]path[/code]  扫描的文件路径
##[br][code]pattern[/code]  文件分组正则匹配方式。比如要对相同前缀的 PNG 文件名进行分组。只要括号内的值都相同，则代表是同一组文件
##[codeblock]
##FileUtil.groups(file_path, "^([A-Za-z]+)_?([A-Za-z]+)?.*?\\.png$")
##[/codeblock]
##[b]以括号内的字符串进行分组[/b]
static func files_group(path: String, pattern: String):
	if not DirAccess.dir_exists_absolute(path):
		printerr("没有这个文件路径")
		return
	
	var regex = RegEx.new()
	regex.compile(pattern)
	
	var dir = DirAccess.open(path)
	if dir:
		var group_count = regex.get_group_count()
		var map = {}
		for file in dir.get_files():
			var result = regex.search(file)
			if result != null:
				# 匹配
				var list = []
				var s = ""
				for i in range(1, group_count + 1):
					s = result.get_string(i)
					if s != "":
						list.append(s)
				# 记录
				if not map.has(list):
					map[list] = []
				map[list].append(file)
		
		return map
		
	else:
		printerr(DirAccess.get_open_error())


## 移动文件到
static func move_file(from: String, to: String) -> Error:
	return rename(from, to)

static func rename(from: String, to: String) -> Error:
	if from == to:
		return ERR_FILE_BAD_PATH
	return DirAccess.rename_absolute(from, to)

## 获取文件修改时间时间戳
static func get_modified_time(path: String) -> int:
	return FileAccess.get_modified_time(path)

## 获取修改时间字符串
static func get_modified_time_string(file_path: String) -> String:
	return Time.get_datetime_string_from_unix_time(FileAccess.get_modified_time(file_path), true)

## 获取文件大小
static func get_file_length(path: String) -> int:
	var file = FileAccess.open(path, FileAccess.READ)
	if file:
		return file.get_length()
	return 0


## 移除文件（移除到回收站）
static func remove(path: String) -> Error:
	if path.begins_with("res://") or path.begins_with("user://"):
		path = get_real_path(path)
	return OS.move_to_trash(path)

## 彻底删除文件
static func delete(dir_or_file: String) -> void:
	if FileAccess.file_exists(dir_or_file):
		DirAccess.remove_absolute(dir_or_file)
	elif DirAccess.dir_exists_absolute(dir_or_file):
		# 删除文件
		for file in DirAccess.get_files_at(dir_or_file):
			DirAccess.remove_absolute(dir_or_file.path_join(file))
		# 删除目录
		for dir in DirAccess.get_directories_at(dir_or_file):
			delete(dir_or_file.path_join(dir))
			DirAccess.remove_absolute(dir_or_file.path_join(dir))

## 复制目录和文件
static func copy_directory_and_file(path: String, new_path: String):
	# 如果复制的是目录
	if DirAccess.dir_exists_absolute(path):
		make_dir_if_not_exists(new_path)
		for dir in DirAccess.get_directories_at(path):
			copy_directory_and_file(path.path_join(dir), new_path.path_join(dir))
		for file in DirAccess.get_files_at(path):
			DirAccess.copy_absolute(path.path_join(file), new_path.path_join(file))
	else:
		# 复制的文件
		DirAccess.copy_absolute(path, new_path)

## 复制目录
static func copy_directory(path: String, new_path: String):
	make_dir_if_not_exists(new_path)
	if DirAccess.dir_exists_absolute(path):
		for dir in DirAccess.get_directories_at(path):
			make_dir_if_not_exists(new_path.path_join(dir))
			copy_directory(path.path_join(dir), new_path.path_join(dir))

## 复制文件
static func copy_file(path: String, new_path: String):
	if DirAccess.dir_exists_absolute(path):
		DirAccess.copy_absolute(path, new_path)
	else:
		# 这种方式可以复制 res:// 中的文件到外部
		var bytes : PackedByteArray = FileAccess.get_file_as_bytes(path)
		var file : FileAccess = FileAccess.open(new_path, FileAccess.WRITE)
		file.store_buffer(bytes)
		file.flush()


const BYTE_QUANTITIES: Array[int] = [
	1e3, # KB
	1e6, # MB
	1e9, # GB
]

enum SizeFlag {
	KB,
	MB,
	GB
}

## 获取文件大小
static func get_file_size(path: String, size_flag: int) -> float:
	var length = get_file_length(path)
	return (length / BYTE_QUANTITIES[size_flag])

## 查找程序路径
static func find_program_path_list(program_name: String) -> PackedStringArray:
	var output = []
	OS.execute("CMD", ["/C", "where", program_name], output)
	var list = str(output[0]).replace("\\", "/").split("\r\n")
	if list[list.size() - 1] == "":
		list.remove_at(list.size() - 1)
	return list

## 查找程序路径
static func find_program_path(program_name: String) -> String:
	var list = find_program_path_list(program_name)
	if list.is_empty():
		return ""
	return list[0]

static var _load_cache : Dictionary = {}
## 加载文件。加载完之后不需要重复 load
static func load_file(path: String) -> Variant:
	if _load_cache.has(path):
		return _load_cache[path]
	else:
		_load_cache[path] = load(path)
		return _load_cache[path]

static var _cache_file_md5 : Dictionary = {}
## 获取文件的 md5 数据。会自动缓存数据，不会重复获取，这对于一些比较大的文件会有用。
static func get_file_md5(file_path: String, simple: bool = true) -> String:
	if not _cache_file_md5.has(file_path):
		var md5 : String = ( file_path.md5_text() if simple else FileAccess.get_md5(file_path) )
		if not md5.is_empty():
			_cache_file_md5[file_path] = md5
	return _cache_file_md5.get(file_path, "")


const ICO_HEADER_SIZE = 6
const ICO_ENTRY_SIZE = 16
## 转换 ico 数据为图像
static func load_ico_from_buffer(ico_bytes: PackedByteArray) -> Image:
	# 数据指针
	var point : int = 0
	# 开始读取数据
	var header : PackedByteArray = ico_bytes.slice(point, point + ICO_HEADER_SIZE)
	point += ICO_HEADER_SIZE
	var image_count : int = _get_16(header, 4)
	var entries : Array[PackedByteArray] = []
	var entry: PackedByteArray
	for i in range(image_count):
		entry = ico_bytes.slice(point, point + ICO_ENTRY_SIZE)
		point += ICO_ENTRY_SIZE
		entries.append(entry)
	# 使用第一个图像
	entry = entries[0]
	var width : int = entry[0]
	var height : int = entry[1]
	var image_data : PackedByteArray = ico_bytes.slice(point)
	return _decode_ico_image(width, height, image_data)

static func _decode_ico_image(width: int, height: int, image_data: PackedByteArray) -> Image:
	# ICO 通常有一个 AND 和一个 XOR 掩码，我们这里只处理 XOR 掩码
	var pixels := PackedByteArray()
	for y in range(height):
		for x in range(width):
			var index = (x + y * width + 10) * 4
			if index + 3 < image_data.size():
				var b = image_data[index]
				var g = image_data[index + 1]
				var r = image_data[index + 2]
				var a = image_data[index + 3]
				pixels.push_back(r)
				pixels.push_back(g)
				pixels.push_back(b)
				pixels.push_back(a)
			else:
				print("Index out of bounds: ", index)
	# 创建图像
	var format := Image.FORMAT_RGBA8
	var image := Image.create_empty(width, height, false, format)
	image.set_data(width, height, false, format, pixels)
	image.flip_y()
	return image

# 辅助方法解析 16 位整数 
static func _get_16(data: PackedByteArray, offset: int) -> int: 
	return data[offset] | (data[offset + 1] << 8) 


## 获取当前项目的启动路径
static func get_executable_path() -> String:
	return OS.get_executable_path()


## Shell 打开文件
static func shell_open(path: String) -> void:
	if path.begins_with("res://") or path.begins_with("user://"):
		path = get_real_path(path)
	if file_exists(path):
		if OS.get_name() == "Windows":
			# 路径不替换为 \ 会执行失败
			var command : String = 'explorer.exe /select,"%s"' % path.replace("/", "\\")
			OS.execute_with_pipe("CMD.exe", ["/C", command])
			return
	OS.shell_open(path)


## 执行文件
static func execute(file_path: String, paras: PackedStringArray = []):
	var path: String = get_real_path(file_path)
	OS.execute_with_pipe(path, paras)
