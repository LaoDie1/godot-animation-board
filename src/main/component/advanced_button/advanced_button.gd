#============================================================
#    Advanced Button
#============================================================
# - author: zhangxuetu
# - datetime: 2024-03-24 20:42:04
# - version: 4.2.1
#============================================================
## 高级按钮
@tool
class_name AdvancedButton
extends Control


signal pressed()


static var ButtonColorHover : Color
static var ButtonPressedHover : Color
static var ButtonDefaultColor : Color


@export var texture : Texture2D:
	set(v):
		texture = v
		if not is_inside_tree():
			await ready
		texture_rect.texture = texture
@export var button_pressed : bool = false:
	set(v):
		if button_pressed != v:
			button_pressed = v
			if button_pressed:
				pressed.emit()
			queue_redraw()
@export var show_panel : Window:
	set(v):
		show_panel = v
		if not is_inside_tree():
			await ready
		popup_prompt_line.visible = (show_panel != null)


@onready var texture_rect: TextureRect = $TextureRect
@onready var popup_prompt_line: Line2D = %PopupPromptLine


var _pressing : bool = false:
	set(v):
		_pressing = v
		set_process(_pressing and show_panel != null)
		_press_time = 0
var _hover_state: bool = false:
	set(v):
		_hover_state = v
		queue_redraw()

var _press_time : float = 0


#============================================================
#  内置
#============================================================
func _init() -> void:
	mouse_entered.connect( set.bind("_hover_state", true) )
	mouse_exited.connect( set.bind("_hover_state", false) )
	ButtonColorHover = Color.POWDER_BLUE
	ButtonPressedHover = Color.from_string("00152e", Color.WHITE)
	ButtonDefaultColor = Color.from_string("b8d0ff", Color.WHITE)


func _ready() -> void:
	set_process(false)
	popup_prompt_line.visible = (show_panel != null)


func _process(delta: float) -> void:
	_press_time += delta
	if _press_time > 0.5:
		_press_time = 0
		if show_panel == null:
			set_process(false)
			return
		show_panel.popup()


func _draw() -> void:
	# 当前正在按下
	if _pressing:
		draw_rect( Rect2i(Vector2i(), size), Color(0.1, 0.1, 0.1, 0.8), true )
	else:
		if button_pressed:
			# 选中后
			draw_rect( Rect2i(Vector2i(), size), Color(0.05, 0.05, 0.05, 0.8), true)
		else:
			# 绘制默认状态颜色
			draw_rect( Rect2i(Vector2i(), size), Color(0.6, 0.6, 0.6, 0.1), true )
		
	if _hover_state:
		# 鼠标经过时
		if not (button_pressed or _pressing):
			# 没有按下按钮则进行绘制经过时的颜色
			draw_rect( Rect2i(Vector2i(), size), Color(0.6, 0.6, 0.6, 0.5), true)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_pressing = event.pressed
			if not event.pressed:
				button_pressed = not button_pressed
			queue_redraw()
