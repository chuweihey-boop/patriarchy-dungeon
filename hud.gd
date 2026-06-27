extends CanvasLayer

@onready var health_bar: ProgressBar = $Control/HealthBar
@onready var xp_bar: ProgressBar = $Control/XPBar
@onready var level_label: Label = $Control/LevelLabel
@onready var timer_label: Label = $Control/TimerLabel
@onready var coin_label: Label = $Control/CoinContainer/Label
@onready var wave_warning_label: Label = $Control/WaveWarningLabel

func _ready() -> void:
	# Add mobile virtual joystick
	var joystick = preload("res://virtual_joystick.gd").new()
	add_child(joystick)
	
	# Initialize display
	level_label.text = "LEVEL 1"
	timer_label.text = "ROUND 1/5   03:00"
	coin_label.text = "0"

func update_health(current: float, max_health: float) -> void:
	health_bar.max_value = max_health
	health_bar.value = current
	health_bar.get_node("Label").text = "%d/%d" % [int(current), int(max_health)]

func update_xp(current: int, required: int) -> void:
	xp_bar.max_value = required
	xp_bar.value = current

func update_level(level: int) -> void:
	level_label.text = "LEVEL %d" % level

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
