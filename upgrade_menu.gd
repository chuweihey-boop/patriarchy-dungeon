extends CanvasLayer

@onready var buttons_container: VBoxContainer = $Control/Panel/VBoxContainer
@onready var title_label: Label = $Control/Panel/TitleLabel

# List of all possible upgrades
var upgrade_pool = [
	{"id": "speed", "title": "⚡ Speed Boost", "desc": "Increase movement speed by 15%"},
	{"id": "health", "title": "❤️ Vitality", "desc": "Heal to full and increase Max HP by 20"},
	{"id": "fire_rate", "title": "🏹 Rapid Fire", "desc": "Increase weapon fire rate by 20%"},
	{"id": "damage", "title": "⚔️ Might", "desc": "Increase weapon damage by 25%"}
]

func _ready() -> void:
	# Stop everything else while upgrading
	process_mode = PROCESS_MODE_ALWAYS
	
	# Select 3 random upgrades from the pool
	var selected_upgrades = []
	var pool_copy = upgrade_pool.duplicate()
	
	# Shuffle pool_copy
	pool_copy.shuffle()
	
	for i in range(min(3, pool_copy.size())):
		selected_upgrades.append(pool_copy[i])
		
	# Populate buttons
	# Clear placeholder buttons first
	for child in buttons_container.get_children():
		if child is Button:
			child.queue_free()
			
	for upgrade in selected_upgrades:
		var btn = Button.new()
		btn.text = "%s\n%s" % [upgrade["title"], upgrade["desc"]]
		btn.custom_minimum_size = Vector2(320, 70)
		
		# Apply some style overrides for a premium feel
		btn.add_theme_font_override("font", preload("res://fonts/Xolonium-Regular.ttf"))
		btn.add_theme_font_size_override("font_size", 14)
		
		# Connect press signal
		btn.pressed.connect(func(): _on_upgrade_chosen(upgrade["id"]))
		buttons_container.add_child(btn)
		
	# Focus the first button to allow keyboard/controller navigation
	if buttons_container.get_child_count() > 0:
		buttons_container.get_child(0).grab_focus()

func _on_upgrade_chosen(upgrade_id: String) -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player:
		match upgrade_id:
			"speed":
				player.speed *= 1.15
			"health":
				player.max_health += 20.0
				player.health = player.max_health
				player.health_changed.emit(player.health, player.max_health)
			"fire_rate":
				var weapon = player.get_node_or_null("Weapon")
				if weapon:
					weapon.fire_rate *= 1.20
					weapon.update_timer()
			"damage":
				var weapon = player.get_node_or_null("Weapon")
				if weapon:
					weapon.damage_multiplier *= 1.25
						
	# Resume game and destroy menu
	get_tree().paused = false
	queue_free()
