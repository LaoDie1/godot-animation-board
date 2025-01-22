#============================================================
#    Property Name
#============================================================
# - author: zhangxuetu
# - datetime: 2024-03-22 21:19:14
# - version: 4.2.1
#============================================================
## 属性路径名（在 ProjectData 中进行了属性名的初始化）
class_name PropertyName


static var SHAPE_CIRCLE = "shape_circle"
static var SHAPE_RECTANGLE = "shape_rectangle"

enum SHAPE {
	CIRCLE,
	RECTANGLE,
}


# 配置数据相关。Dictionary 中的数据的键
class KEY:
	# Dictionary 键
	static var LAYER_ID
	static var FRAME_ID
	static var TEXTURE
	static var COLORS
	
	# 配置数据
	static var IMAGE_RECT # 图片矩形
	static var CURRENT_TOOL # 当前使用的工具
	static var ONIONSKIN # 洋葱皮是否启用
	static var CANVAS_ZOOM # 画布缩放
	static var CANVAS_BACKGROUND_COLOR # 画板背景颜色


# 工具名称
class TOOL_NAME:
	static var PEN
	static var ERASER # 橡皮擦
	static var MOVE
	static var LINE # 线段


# 钢笔工具
class PEN:
	static var COLOR
	static var SIZE
	static var SHAPE

# 橡皮擦
class ERASER:
	static var SIZE
	static var SHAPE


# 线段工具
class LINE:
	static var WIDTH # 线宽
	static var COLOR
