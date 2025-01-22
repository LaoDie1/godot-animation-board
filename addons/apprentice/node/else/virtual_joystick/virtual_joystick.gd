#============================================================
#    Virtual Joystick
#============================================================
# - author: zhangxuetu
# - datetime: 2023-05-31 11:04:36
# - version: 4.0
# - see: https://github.com/mcunha-br/virtual_joystick_godot4
#============================================================
## 虚拟摇杆
@tool
@icon("sprites/icon.png")
class_name VirtualJoystick
extends Control


##  摇杆线程。[code]direction[/code] 方向，[code]strength[/code] 力度
signal analogic_process(direction: Vector2, strength: float)
signal analogic_change(direction: Vector2, strength: float)
signal analogic_released


@export var border: Texture2D:
	set(value):
		border = value
		queue_redraw()
@export var stick: Texture2D:
	set(value):
		stick = value
		queue_redraw()
@export var stick_scale: float = 0.65:
	set(v):
		stick_scale = v
		queue_redraw()
@export_flags("Mobile:1", "Computy:2", "Web:4") var display_platform : int = 7:
	set(v):
		display_platform = v
		match OS.get_name():
			"Android", "iOS":
				visible = (display_platform & 1 == 1)
			"Windows", "UWP", "macOS", "Linux", "FreeBSD", "NetBSD", "OpenBSD", "BSD":
				visible = (display_platform & 2 == 2)
			"Web":
				visible = (display_platform & 4 == 4)


# 摇杆圈
var joystick := TextureRect.new()
# 控制按钮
var touch_circle := TouchScreenButton.new()

var _touch_pos : Vector2:
	set(v):
		_touch_pos = v
		_touch_max_radius = _touch_pos.length()
var _touch_max_radius : float
var _on_going_drag := false
var _direction : Vector2 = Vector2(0, 0) # 上次的方向
var _strength : float = 0.0 # 力度，离中心点和最大距离之间的比值


#============================================================
#  SetGet
#============================================================
func get_last_direction() -> Vector2:
	return _direction

func get_last_strength() -> float:
	return _strength


#============================================================
#  内置
#============================================================
func _enter_tree():
	if Engine.is_editor_hint():
		set_process(false)
		set_physics_process(false)
	self.display_platform = display_platform


func _ready() -> void:
	if Engine.is_editor_hint():
		set_process(false)
		set_physics_process(false)
	else:
		touch_circle.released.connect(func(): 
			_direction = Vector2(0, 0)
			self.analogic_released.emit()
		)
	self.display_platform = display_platform
	
	add_child(touch_circle)
	add_child(joystick)
	move_child(joystick, 0)
	joystick.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	joystick.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	joystick.size = self.size
	
	queue_redraw()


func _physics_process(delta):
	self.analogic_process.emit(_direction, _strength)


func _draw():
	joystick.texture = border \
		if is_instance_valid(border) \
		else preload("sprites/joystick.png")
	touch_circle.texture_normal = stick \
		if is_instance_valid(stick) \
		else preload("sprites/stick.png")
	touch_circle.modulate.a = 0.8
	touch_circle.scale = self.size / Vector2(touch_circle.texture_normal.get_size()) * stick_scale
	_reset_position()


func _gui_input(event):
	if event is InputEventScreenTouch:
		if _on_going_drag != event.is_pressed():
			_on_going_drag = event.is_pressed()
			if not _on_going_drag:
				self.analogic_released.emit()
				_direction = Vector2.ZERO
				_strength = 0.0
				_reset_position()
			else:
				self.analogic_change.emit(_direction, _strength)
	
	if event is InputEventScreenDrag:
		var diff : Vector2 = Vector2(event.position - size/2).limit_length(_touch_max_radius)
		var length : float = diff.length()
		_strength = length / _touch_max_radius
		_direction = diff.normalized()
		touch_circle.position = _touch_pos + diff
		self.analogic_change.emit(_direction, _strength)


func _reset_position():
	if touch_circle.texture_normal:
		joystick.position = (self.size - joystick.size) / 2
		_touch_pos = (self.size - touch_circle.texture_normal.get_size() * touch_circle.scale) / 2
		create_tween().tween_property(touch_circle, "position", _touch_pos, 0.08)
