extends CanvasLayer

@onready var health_bar: ProgressBar = $Control/HealthBar
@onready var timer_label: Label = $Control/TimerLabel
@onready var coin_label: Label = $Control/CoinContainer/Label
@onready var wave_warning_label: Label = $Control/WaveWarningLabel

func _ready() -> void:
	# Add mobile virtual joystick
	var is_mobile = OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios") or DisplayServer.is_touchscreen_available()
	var joystick = preload("res://virtual_joystick.gd").new()
	$Control.add_child(joystick)
	
	if is_mobile:
		var dash_btn = Button.new()
		dash_btn.name = "DashButton"
		dash_btn.icon = preload("res://art/icons/32x32/boots_01a.png")
		dash_btn.text = "Dash"
		dash_btn.add_theme_font_override("font", preload("res://fonts/Xolonium-Regular.ttf"))
		dash_btn.anchor_left = 0.0
		dash_btn.anchor_right = 0.0
		dash_btn.anchor_top = 1.0
		dash_btn.anchor_bottom = 1.0
		dash_btn.offset_left = 130
		dash_btn.offset_right = 230
		dash_btn.offset_top = -100
		dash_btn.offset_bottom = -30
		dash_btn.pressed.connect(func():
			var p = get_tree().get_first_node_in_group("player")
			if is_instance_valid(p) and p.has_method("dash") and p.dash_cooldown <= 0.0:
				p.dash()
		)
		$Control.add_child(dash_btn)
		
		var ult_btn = Button.new()
		ult_btn.name = "UltButton"
		ult_btn.icon = preload("res://art/icons/32x32/skull_01a.png")
		ult_btn.text = "Emit"
		ult_btn.add_theme_font_override("font", preload("res://fonts/Xolonium-Regular.ttf"))
		ult_btn.anchor_left = 1.0
		ult_btn.anchor_right = 1.0
		ult_btn.anchor_top = 1.0
		ult_btn.anchor_bottom = 1.0
		ult_btn.offset_left = -230
		ult_btn.offset_right = -130
		ult_btn.offset_top = -100
		ult_btn.offset_bottom = -30
		ult_btn.pressed.connect(func():
			var p = get_tree().get_first_node_in_group("player")
			if is_instance_valid(p) and p.has_method("use_ultimate") and p.ultimate_cooldown <= 0.0:
				p.use_ultimate()
		)
		$Control.add_child(ult_btn)
	
	var debug_btn = Button.new()
	debug_btn.name = "DebugButton"
	debug_btn.text = "Debug Mode"
	debug_btn.process_mode = Node.PROCESS_MODE_ALWAYS
	debug_btn.anchor_left = 1.0
	debug_btn.anchor_right = 1.0
	debug_btn.offset_left = -120
	debug_btn.offset_right = -10
	debug_btn.offset_top = 90
	debug_btn.offset_bottom = 120
	debug_btn.pressed.connect(_on_debug_btn_pressed)
	$Control.add_child(debug_btn)
	
	# Initialize display
	timer_label.text = "ROUND 1/5   03:00"
	coin_label.text = "0"

func update_health(current: float, max_health: float) -> void:
	health_bar.max_value = max_health
	health_bar.value = current
	health_bar.get_node("Label").text = "%d/%d" % [int(current), int(max_health)]

func _on_debug_btn_pressed() -> void:
	var existing = get_tree().current_scene.get_node_or_null("DebugMenu")
	if existing:
		get_tree().paused = false
		existing.queue_free()
	else:
		get_tree().paused = true
		var debug_menu = preload("res://debug_menu.gd").new()
		debug_menu.name = "DebugMenu"
		get_tree().current_scene.add_child(debug_menu)


func update_timer(time_remaining: float, current_round: int = 1) -> void:
	var minutes = int(time_remaining) / 60
	var seconds = int(time_remaining) % 60
	timer_label.text = "ROUND %d/5   %02d:%02d" % [current_round, minutes, seconds]

func update_coins(current_coins: int) -> void:
	coin_label.text = str(current_coins)

func show_wave_warning(message: String = "MONSTER WAVE COMING!") -> void:
	wave_warning_label.text = message
	wave_warning_label.modulate.a = 1.0
	var tween = create_tween()
	tween.tween_property(wave_warning_label, "modulate:a", 0.0, 3.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
