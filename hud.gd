extends CanvasLayer

@onready var health_bar: ProgressBar = $Control/HealthBar
@onready var timer_label: Label = $Control/TimerLabel
@onready var coin_label: Label = $Control/CoinContainer/Label
@onready var wave_warning_label: Label = $Control/WaveWarningLabel

func _ready() -> void:
	# Add mobile virtual joystick
	var joystick = preload("res://virtual_joystick.gd").new()
	$Control.add_child(joystick)
	
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
