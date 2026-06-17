extends CanvasLayer

@onready var close_button: Button = $Panel/CloseButton
@onready var hp_val: Label = $Panel/StatsContainer/HBoxHP/Value
@onready var damage_val: Label = $Panel/StatsContainer/HBoxDamage/Value
@onready var speed_val: Label = $Panel/StatsContainer/HBoxSpeed/Value
@onready var freq_val: Label = $Panel/StatsContainer/HBoxFreq/Value
@onready var range_val: Label = $Panel/StatsContainer/HBoxRange/Value
@onready var regen_val: Label = $Panel/StatsContainer/HBoxRegen/Value
@onready var shield_val: Label = $Panel/StatsContainer/HBoxShield/Value

func _ready() -> void:
	# Pause the game
	get_tree().paused = true
	
	# Connect close button
	close_button.pressed.connect(close_menu)
	
	# Fetch player stats
	var player = get_tree().get_first_node_in_group("player")
	if player:
		# HP (Current / Max as integers)
		hp_val.text = "%d / %d" % [player.health, player.max_health]
		
		# Attack Damage % (modifier)
		var weapon = player.get_node_or_null("Weapon")
		var damage_pct = int(round(weapon.damage_multiplier * 100)) if weapon else 100
		damage_val.text = "%d%%" % damage_pct
		
		# Speed % compared to default_speed (300.0)
		var speed_pct = int(round((player.speed / player.default_speed) * 100))
		speed_val.text = "%d%%" % speed_pct
		
		# Attack Frequency % (modifier)
		var freq_pct = int(round(player.attack_frequency_modifier * 100))
		freq_val.text = "%d%%" % freq_pct
		
		# Attack Range % (modifier)
		var range_pct = int(round(player.attack_range_modifier * 100))
		range_val.text = "%d%%" % range_pct
		
		# Regen HP/s (Float with 1 decimal digit)
		regen_val.text = "%.1f HP/s" % player.regen_speed
		
		# Shield (Integer)
		shield_val.text = "%d" % player.shield
	else:
		print("Warning: Player not found for stats display!")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.is_echo():
		if event.keycode == KEY_I:
			# Get viewport accept/consume input
			get_viewport().set_input_as_handled()
			close_menu()

func close_menu() -> void:
	# Unpause the game and close
	get_tree().paused = false
	queue_free()
