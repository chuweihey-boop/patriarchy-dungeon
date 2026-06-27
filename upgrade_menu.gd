extends CanvasLayer

var stat_weights = {
	"max_health": 1.0,
	"regen_speed": 12.0,
	"speed_pct": 1.5,
	"damage_pct": 2.0,
	"fire_rate_pct": 2.0,
	"shield": 15.0
}

var test_items = [
	{
		"id": "vitality",
		"title": "❤️ Vitality Ring",
		"desc": "+25 Max HP",
		"stats": {"max_health": 25.0}
	},
	{
		"id": "troll_blood",
		"title": "🌿 Troll Blood",
		"desc": "+2 HP Regen/sec",
		"stats": {"regen_speed": 2.0}
	},
	{
		"id": "hermes",
		"title": "⚡ Hermes Boots",
		"desc": "+15% Move Speed",
		"stats": {"speed_pct": 15.0}
	},
	{
		"id": "whetstone",
		"title": "⚔️ Whetstone",
		"desc": "+20% Weapon Damage",
		"stats": {"damage_pct": 20.0}
	},
	{
		"id": "rapid_string",
		"title": "🏹 Rapid String",
		"desc": "+20% Attack Speed",
		"stats": {"fire_rate_pct": 20.0}
	},
	{
		"id": "iron_plate",
		"title": "🛡️ Iron Plating",
		"desc": "+2 Shield, -5% Move Speed",
		"stats": {"shield": 2.0, "speed_pct": -5.0}
	},
	{
		"id": "berserk",
		"title": "🔥 Berserk Charm",
		"desc": "+30% Damage, -10 Max HP",
		"stats": {"damage_pct": 30.0, "max_health": -10.0}
	}
]

func calculate_price(item: Dictionary) -> int:
	var total = 0.0
	var stats = item.get("stats", {})
	for stat_name in stats:
		var val = stats[stat_name]
		var weight = stat_weights.get(stat_name, 1.0)
		total += val * weight
	return max(5, int(round(total)))

func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	
	for child in get_children():
		child.queue_free()
		
	var root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	
	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.05, 0.05, 0.08, 0.85)
	root.add_child(bg)
	
	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 60)
	margin.add_theme_constant_override("margin_right", 60)
	margin.add_theme_constant_override("margin_top", 50)
	margin.add_theme_constant_override("margin_bottom", 50)
	root.add_child(margin)
	
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 40)
	margin.add_child(hbox)
	
	var player = get_tree().get_first_node_in_group("player")
	var current_coins = player.coins if is_instance_valid(player) else 0
	
	# --- LEFT SIDE: UPGRADE SELECTION ---
	var left_panel = PanelContainer.new()
	left_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_panel.size_flags_stretch_ratio = 1.3
	_apply_panel_style(left_panel, Color(0.1, 0.12, 0.2))
	hbox.add_child(left_panel)
	
	var left_vbox = VBoxContainer.new()
	left_vbox.add_theme_constant_override("separation", 20)
	left_panel.add_child(left_vbox)
	
	var header_hbox = HBoxContainer.new()
	left_vbox.add_child(header_hbox)
	
	var title = Label.new()
	title.text = "🛒 LEVEL UP SELECTION"
	title.add_theme_font_override("font", preload("res://fonts/Xolonium-Regular.ttf"))
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.9, 0.9, 1.0))
	header_hbox.add_child(title)
	
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_hbox.add_child(spacer)
	
	var coins_label = Label.new()
	coins_label.text = "💰 Coins: %d" % current_coins
	coins_label.add_theme_font_override("font", preload("res://fonts/Xolonium-Regular.ttf"))
	coins_label.add_theme_font_size_override("font_size", 22)
	coins_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	header_hbox.add_child(coins_label)
	
	var pool = test_items.duplicate()
	pool.shuffle()
	var offered = pool.slice(0, min(3, pool.size()))
	
	var cards_vbox = VBoxContainer.new()
	cards_vbox.add_theme_constant_override("separation", 15)
	cards_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cards_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	left_vbox.add_child(cards_vbox)
	
	for item in offered:
		var price = calculate_price(item)
		var can_afford = current_coins >= price
		
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(0, 80)
		var price_str = "💰 %d Coins" % price if can_afford else "❌ %d Coins (Too Expensive)" % price
		btn.text = "%s  [%s]\n%s" % [item["title"], price_str, item["desc"]]
		btn.add_theme_font_override("font", preload("res://fonts/Xolonium-Regular.ttf"))
		btn.add_theme_font_size_override("font_size", 16)
		btn.disabled = not can_afford
		
		if can_afford:
			btn.add_theme_color_override("font_color", Color(0.9, 1.0, 0.9))
			btn.pressed.connect(func(): _buy_item(item, price))
		else:
			btn.add_theme_color_override("font_disabled_color", Color(0.6, 0.4, 0.4))
			
		cards_vbox.add_child(btn)
		if can_afford and not cards_vbox.get_child(0).has_focus():
			btn.grab_focus()
			
	var skip_btn = Button.new()
	skip_btn.text = "⏭️ Skip & Gain +10 Coins"
	skip_btn.custom_minimum_size = Vector2(0, 50)
	skip_btn.add_theme_font_override("font", preload("res://fonts/Xolonium-Regular.ttf"))
	skip_btn.add_theme_font_size_override("font_size", 16)
	skip_btn.pressed.connect(func():
		if is_instance_valid(player):
			player.coins += 10
			player.coins_changed.emit(player.coins)
		_close_menu()
	)
	left_vbox.add_child(skip_btn)
	
	# --- RIGHT SIDE: CHARACTER STATS ---
	var right_panel = PanelContainer.new()
	right_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_panel.size_flags_stretch_ratio = 0.9
	_apply_panel_style(right_panel, Color(0.15, 0.1, 0.18))
	hbox.add_child(right_panel)
	
	var right_vbox = VBoxContainer.new()
	right_vbox.add_theme_constant_override("separation", 20)
	right_panel.add_child(right_vbox)
	
	var stat_title = Label.new()
	stat_title.text = "📊 CHARACTER STATS"
	stat_title.add_theme_font_override("font", preload("res://fonts/Xolonium-Regular.ttf"))
	stat_title.add_theme_font_size_override("font_size", 24)
	stat_title.add_theme_color_override("font_color", Color(1.0, 0.9, 0.95))
	right_vbox.add_child(stat_title)
	
	var stats_list = VBoxContainer.new()
	stats_list.add_theme_constant_override("separation", 12)
	right_vbox.add_child(stats_list)
	
	if is_instance_valid(player):
		var weapon = player.get_node_or_null("Weapon")
		var dmg_mult = weapon.damage_multiplier * 100.0 if weapon else 100.0
		var fire_mult = weapon.fire_rate if weapon else 1.0
		
		_add_stat_row(stats_list, "❤️ Max HP", str(int(player.max_health)))
		_add_stat_row(stats_list, "🌿 HP Regen", "%.1f / sec" % player.regen_speed)
		_add_stat_row(stats_list, "🛡️ Shield", str(player.shield))
		_add_stat_row(stats_list, "⚡ Move Speed", str(int(player.default_speed)))
		_add_stat_row(stats_list, "⚔️ Damage Mult", "%d%%" % int(dmg_mult))
		_add_stat_row(stats_list, "🏹 Attack Speed", "%.1f shots/s" % fire_mult)

func _add_stat_row(container: VBoxContainer, label_text: String, val_text: String) -> void:
	var row = HBoxContainer.new()
	var l = Label.new()
	l.text = label_text
	l.add_theme_font_override("font", preload("res://fonts/Xolonium-Regular.ttf"))
	l.add_theme_font_size_override("font_size", 18)
	row.add_child(l)
	
	var sp = Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(sp)
	
	var v = Label.new()
	v.text = val_text
	v.add_theme_font_override("font", preload("res://fonts/Xolonium-Regular.ttf"))
	v.add_theme_font_size_override("font_size", 18)
	v.add_theme_color_override("font_color", Color(0.4, 0.9, 1.0))
	row.add_child(v)
	container.add_child(row)

func _apply_panel_style(panel: PanelContainer, bg_color: Color) -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	style.border_color = Color(0.4, 0.5, 0.8, 0.7)
	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_right = 16
	style.corner_radius_bottom_left = 16
	style.content_margin_left = 25
	style.content_margin_right = 25
	style.content_margin_top = 25
	style.content_margin_bottom = 25
	panel.add_theme_stylebox_override("panel", style)

func _buy_item(item: Dictionary, price: int) -> void:
	var player = get_tree().get_first_node_in_group("player")
	if not is_instance_valid(player):
		_close_menu()
		return
		
	player.coins -= price
	player.coins_changed.emit(player.coins)
	
	var stats = item.get("stats", {})
	for stat_name in stats:
		var val = stats[stat_name]
		match stat_name:
			"max_health":
				player.max_health += val
				player.health = min(player.max_health, player.health + max(0.0, val))
				player.health_changed.emit(player.health, player.max_health)
			"regen_speed":
				player.regen_speed += val
			"speed_pct":
				player.default_speed *= (1.0 + val / 100.0)
				if player.has_method("_update_speed"):
					player._update_speed()
			"shield":
				player.shield += int(val)
			"damage_pct":
				var weapon = player.get_node_or_null("Weapon")
				if weapon:
					weapon.damage_multiplier *= (1.0 + val / 100.0)
			"fire_rate_pct":
				var weapon = player.get_node_or_null("Weapon")
				if weapon:
					weapon.fire_rate *= (1.0 + val / 100.0)
					weapon.update_timer()
					
	_close_menu()

func _close_menu() -> void:
	get_tree().paused = false
	queue_free()
