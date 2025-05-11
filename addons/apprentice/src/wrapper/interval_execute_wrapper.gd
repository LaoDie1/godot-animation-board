#============================================================
#    Interval Execute Wrapper
#============================================================
# - author: zhangxuetu
# - datetime: 2025-01-29 22:17:17
# - version: 4.4.0.beta1
#============================================================
## 间隔时间执行包装器
##
##防止执行过快，设置一个间隔时间，然后调用执行方法。注意执行的 Id 对应数据只会执行最后一次调用的数据，其他数据则不作效
class_name IntervalExecuteWrapper


var _interval: int = 0.2
var _method: Callable
var _id_to_data_dict: Dictionary = {}


func _init(method:Callable, interval: float = 0.2):
	_interval = interval
	_method = method


func execute(data, id = null) -> void:
	if _id_to_data_dict.has(id):
		_id_to_data_dict[id] = data
	else:
		_id_to_data_dict[id] = data
		await Engine.get_main_loop().create_timer(_interval).timeout
		_method.call(_id_to_data_dict[id])
		_id_to_data_dict.erase(id)
