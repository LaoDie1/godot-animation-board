#============================================================
#    Property Name
#============================================================
# - author: zhangxuetu
# - datetime: 2024-03-22 21:19:14
# - version: 4.2.1
#============================================================
## 属性路径名（在 ProjectData 中进行了属性名的初始化）
class_name PropertyName


# 配置数据相关。Dictionary 中的数据的键
class KEY:
	static var LAYER_ID
	static var FRAME_ID
	static var TEXTURE
	static var COLORS


# 工具数据
class TOOL:
	static var CURRENT # 当前工具
	static var ONIONSKIN # 洋葱皮是否启用
	
	static var PEN # 工具名称
	

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

class LINE:
	static var WIDTH # 线宽
	static var COLOR
