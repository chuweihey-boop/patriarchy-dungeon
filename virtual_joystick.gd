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
	var is_mobile = OS.has_feature("mobile")
	if OS.has_feature("web") and ClassDB.class_exists("JavaScriptBridge"):
		var is_web_mobile = JavaScriptBridge.eval("(/Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent)) || (navigator.maxTouchPoints > 0)")
		if is_web_mobile:
			is_mobile = true
			
	if not is_mobile and not DisplayServer.is_touchscreen_available():
		visible = false
		
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
		
	if event is InputEventScreenTouch:
		if event.pressed and touch_index == -1:
			# Touch down anywhere on the left 65% of the screen
			if event.position.x < get_viewport_rect().size.x * 0.65:
				touch_index = event.index
				base_pos = event.position
				handle_pos = base_pos
				is_active = true
				queue_redraw()
				get_viewport().set_input_as_handled()
		elif not event.pressed and event.index == touch_index:
			_reset_joystick()
			get_viewport().set_input_as_handled()
			
	elif event is InputEventScreenDrag and event.index == touch_index:
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
	Input.action_release("ui_left")
	Input.action_release("ui_right")
	Input.action_release("ui_up")
	Input.action_release("ui_down")
	queue_redraw()

func _draw() -> void:
	if not is_active:
		return
	# Draw outer base ring
	draw_circle(base_pos, max_radius, base_color)
	draw_arc(base_pos, max_radius, 0, TAU, 36, Color(0.7, 0.85, 1.0, 0.6), 3.5)
	# Draw inner thumbstick handle
	draw_circle(handle_pos, max_radius * 0.42, handle_color)
	draw_arc(handle_pos, max_radius * 0.42, 0, TAU, 28, Color.WHITE, 2.0)
