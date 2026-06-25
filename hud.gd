extends CanvasLayer

@onready var health_bar: ProgressBar = $Control/HealthBar
@onready var xp_bar: ProgressBar = $Control/XPBar
@onready var level_label: Label = $Control/LevelLabel
@onready var timer_label: Label = $Control/TimerLabel
@onready var coin_label: Label = $Control/CoinContainer/Label

func _ready() -> void:
	# Initialize display
	level_label.text = "LEVEL 1"
	timer_label.text = "00:00"
	coin_label.text = "0"

func update_health(current: float, max_health: float) -> void:
	health_bar.max_value = max_health
	health_bar.value = current
	health_bar.get_node("Label").text = "HP: %d / %d" % [int(current), int(max_health)]

func update_xp(current: int, required: int) -> void:
	xp_bar.max_value = required
	xp_bar.value = current
	xp_bar.get_node("Label").text = "XP: %d / %d" % [current, required]

func update_level(level: int) -> void:
	level_label.text = "LEVEL %d" % level

func update_timer(time_elapsed: float) -> void:
	var minutes = int(time_elapsed) / 60
	var seconds = int(time_elapsed) % 60
	timer_label.text = "%02d:%02d" % [minutes, seconds]

func update_coins(current_coins: int) -> void:
	coin_label.text = str(current_coins)
