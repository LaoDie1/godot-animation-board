#============================================================
#    Property Manager Set Range
#============================================================
# - author: zhangxuetu
# - datetime: 2025-01-22 16:17:23
# - version: 4.4.0.dev
#============================================================
class_name PropertyManagementPropertyRange


## 设置值的最小值和最大值
static func set_range(property_management:PropertyManagement, property, min_value:float, max_value: float):
	assert(min_value <= max_value, "最小值必须要小于最大值")
	property_management.property_changed.connect(
		func(prop, previous, current):
			if prop == property:
				if current < min_value:
					property_management.set_value(property, min_value)
				elif current > max_value:
					property_management.set_value(property, max_value)
	)


## 根据另一个属性设置当前属性的值范围
static func set_range_from_property(property_management:PropertyManagement, property, min_property = null, max_property = null):
	assert(typeof(min_property) != TYPE_NIL or typeof(max_property) != TYPE_NIL, "必须要设置一个属性")
	property_management.property_changed.connect(
		func(prop, previous, current):
			if prop == property:
				if min_property and current < property_management.get_as_float(min_property):
					property_management.set_value(property, property_management.get_as_float(min_property))
				elif max_property and current > property_management.get_as_float(max_property):
					property_management.set_value(property, property_management.get_as_float(max_property))
	)
	
	var current = property_management.get_value(property)
	if typeof(current) != TYPE_NIL:
		if min_property and current < property_management.get_as_float(min_property):
			property_management.set_value(property, property_management.get_as_float(min_property))
		elif max_property and current > property_management.get_as_float(max_property):
			property_management.set_value(property, property_management.get_as_float(max_property))
