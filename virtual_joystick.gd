extends Control
class_name VirtualJoystick

@export var max_radius: float = 85.0
@export var base_color: Color = Color(0.15, 0.2, 0.35, 0.5)
@export var handle_color: Color = Color(0.6, 0.85, 1.0, 0.85)

var touch_index: int = -1
var handle_pos: Vector2 = Vector2.ZERO
var base_pos: Vector2 = Vector2.ZERO
var is_active: bool = false

func _ready() -> void:
	base_pos = Vector2(160, 560)
	handle_pos = base_pos
	size = Vector2(1280, 720)
	custom_minimum_size = Vector2(1280, 720)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _input(event: InputEvent) -> void:
	if not visible:
		return
		
	var is_press = false
	var is_release = false
	var pos = Vector2.ZERO
	var is_valid_touch = false
	
	if event is InputEventScreenTouch:
		is_press = event.pressed
		is_release = not event.pressed
		pos = event.position
		is_valid_touch = (touch_index == -1 or event.index == touch_index)
		if is_press and touch_index == -1: touch_index = event.index
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		is_press = event.pressed
		is_release = not event.pressed
		pos = event.position
		is_valid_touch = (touch_index == -1 or touch_index == 0)
		if is_press and touch_index == -1: touch_index = 0
		
	if is_valid_touch:
		if is_press:
			if pos.x < get_viewport_rect().size.x * 0.65:
				base_pos = pos
				handle_pos = base_pos
				is_active = true
				queue_redraw()
				get_viewport().set_input_as_handled()
		elif is_release:
			_reset_joystick()
			get_viewport().set_input_as_handled()
			
	var is_drag = (event is InputEventScreenDrag and event.index == touch_index)
	var is_mouse_drag = (event is InputEventMouseMotion and touch_index == 0 and (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0)
	if is_drag or is_mouse_drag:
		var diff = event.position - base_pos
		if diff.length() > max_radius:
			diff = diff.normalized() * max_radius
		handle_pos = base_pos + diff
		_update_input_actions(diff / max_radius)
		queue_redraw()
		get_viewport().set_input_as_handled()

func _update_input_actions(vec: Vector2) -> void:
	# Deadzone threshold
	var deadzone = 0.08
	
	# Horizontal
	if vec.x > deadzone:
		Input.action_press("ui_right", vec.x)
		Input.action_release("ui_left")
	elif vec.x < -deadzone:
		Input.action_press("ui_left", -vec.x)
		Input.action_release("ui_right")
	else:
		Input.action_release("ui_left")
		Input.action_release("ui_right")
		
	# Vertical
	if vec.y > deadzone:
		Input.action_press("ui_down", vec.y)
		Input.action_release("ui_up")
	elif vec.y < -deadzone:
		Input.action_press("ui_up", -vec.y)
		Input.action_release("ui_down")
	else:
		Input.action_release("ui_up")
		Input.action_release("ui_down")

func _reset_joystick() -> void:
	touch_index = -1
	is_active = false
	base_pos = Vector2(160, 560)
	handle_pos = base_pos
	Input.action_release("ui_left")
	Input.action_release("ui_right")
	Input.action_release("ui_up")
	Input.action_release("ui_down")
	queue_redraw()

func _draw() -> void:
	draw_circle(base_pos, max_radius, base_color)
	draw_arc(base_pos, max_radius, 0, TAU, 36, Color(0.7, 0.85, 1.0, 0.6), 3.5)
	draw_circle(handle_pos, max_radius * 0.42, handle_color)
	draw_arc(handle_pos, max_radius * 0.42, 0, TAU, 28, Color.WHITE, 2.0)
