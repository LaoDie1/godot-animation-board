#============================================================
#    Property Name
#============================================================
# - author: zhangxuetu
# - datetime: 2024-03-22 21:19:14
# - version: 4.2.1
#============================================================
## 属性路径名（在 ProjectData 中进行了属性名的初始化）
class_name PropertyName


class KEY:
	static var LAYER_ID
	static var FRAME_ID
	static var TEXTURE
	static var COLORS


class TOOL:
	static var CURRENT # 当前工具

# 钢笔工具
class PEN:
	static var COLOR
	static var LINE_WIDTH

# 橡皮擦
class ERASER:
	static var SIZE

# 图片
class IMAGE:
	static var RECT

