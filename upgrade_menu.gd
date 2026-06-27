extends CanvasLayer

var stat_weights = {
	"max_health": 1.0,
	"regen_speed": 12.0,
	"speed_pct": 1.5,
	"damage_pct": 2.0,
	"near_field_damage_pct": 1.5,
	"ranged_damage_pct": 1.5,
	"fire_rate_pct": 2.0,
	"shield": 15.0
}

var test_items = [
	{
		"id": "iron_fist",
		"title": "🥊 Iron Knuckles",
		"desc": "+25% Near Field Damage",
		"stats": {"near_field_damage_pct": 25.0}
	},
	{
		"id": "sniper_lens",
		"title": "🔭 Sniper Scope",
		"desc": "+25% Ranged Attack Damage",
		"stats": {"ranged_damage_pct": 25.0}
	},
	{
		"id": "master_seal",
		"title": "☯️ Master Emblem",
		"desc": "+15% Near Field & +15% Ranged Damage",
		"stats": {"near_field_damage_pct": 15.0, "ranged_damage_pct": 15.0}
	},
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
	if "price" in item:
		return item["price"]
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
	margin.add_theme_constant_override("margin_top", 40)
	margin.add_theme_constant_override("margin_bottom", 40)
	root.add_child(margin)
	
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 40)
	margin.add_child(hbox)
	
	var player = get_tree().get_first_node_in_group("player")
	var current_coins = player.coins if is_instance_valid(player) else 0
	var current_weapons = player.get_weapons() if is_instance_valid(player) and player.has_method("get_weapons") else []
	
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
	title.text = "🛒 LEVEL UP SHOP"
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
	
	# Build shop pool
	var pool = test_items.duplicate()
	
	# Offer new weapons if quotas < 4
	if current_weapons.size() < 4:
		var owned_types = []
		for w in current_weapons:
			owned_types.append(w.weapon_type)
		var names = ["🥚 Egg Basket", "葱 Negi", "🔪 Fish Knife", "🗡️ Wooden Sword"]
		for tid in [0, 1, 2, 3]:
			if not tid in owned_types:
				pool.append({
					"id": "add_w_%d" % tid,
					"action_type": "add_weapon",
					"weapon_type": tid,
					"title": "➕ Equip %s" % names[tid],
					"desc": "Add new weapon (Slot %d/4)" % (current_weapons.size() + 1),
					"price": 35
				})
				
	# Offer weapon upgrades for owned weapons
	for w in current_weapons:
		var w_name = w.get_weapon_name() if w.has_method("get_weapon_name") else "Weapon"
		pool.append({
			"id": "up_w_%d" % w.get_instance_id(),
			"action_type": "upgrade_weapon",
			"target_weapon": w,
			"title": "⬆️ Upgrade %s" % w_name,
			"desc": "+12% Damage, +8% Attack Speed (to Lv.%d)" % (w.level + 1),
			"price": 35 * w.level
		})
	
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
	right_vbox.add_theme_constant_override("separation", 15)
	right_panel.add_child(right_vbox)
	
	var stat_title = Label.new()
	stat_title.text = "📊 CHARACTER & BUILD"
	stat_title.add_theme_font_override("font", preload("res://fonts/Xolonium-Regular.ttf"))
	stat_title.add_theme_font_size_override("font_size", 24)
	stat_title.add_theme_color_override("font_color", Color(1.0, 0.9, 0.95))
	right_vbox.add_child(stat_title)
	
	var stats_list = VBoxContainer.new()
	stats_list.add_theme_constant_override("separation", 8)
	right_vbox.add_child(stats_list)
	
	if is_instance_valid(player):
		_add_stat_row(stats_list, "❤️ Max HP", str(int(player.max_health)))
		_add_stat_row(stats_list, "🌿 HP Regen", "%.1f / sec" % player.regen_speed)
		_add_stat_row(stats_list, "🛡️ Shield", str(player.shield))
		_add_stat_row(stats_list, "⚡ Move Speed", str(int(player.default_speed)))
		
		var near_pct = int(player.near_field_damage_modifier * 100.0)
		var range_pct = int(player.ranged_damage_modifier * 100.0)
		_add_stat_row(stats_list, "🥊 Near Field Dmg", "%d%%" % near_pct)
		_add_stat_row(stats_list, "🔭 Ranged Dmg", "%d%%" % range_pct)
		
		var w_title = Label.new()
		w_title.text = "\n🗡️ WEAPON QUOTAS (%d / 4)" % current_weapons.size()
		w_title.add_theme_font_override("font", preload("res://fonts/Xolonium-Regular.ttf"))
		w_title.add_theme_font_size_override("font_size", 20)
		w_title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
		stats_list.add_child(w_title)
		
		for i in range(4):
			var slot_str = "Slot %d: [Empty]" % (i + 1)
			if i < current_weapons.size():
				var w = current_weapons[i]
				var wn = w.get_weapon_name() if w.has_method("get_weapon_name") else "Weapon"
				slot_str = "%s (Lv.%d)" % [wn, w.level]
			var sl = Label.new()
			sl.text = slot_str
			sl.add_theme_font_override("font", preload("res://fonts/Xolonium-Regular.ttf"))
			sl.add_theme_font_size_override("font_size", 16)
			sl.add_theme_color_override("font_color", Color(0.8, 0.95, 1.0) if i < current_weapons.size() else Color(0.5, 0.5, 0.6))
			stats_list.add_child(sl)

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
	style.content_margin_top = 20
	style.content_margin_bottom = 20
	panel.add_theme_stylebox_override("panel", style)

func _buy_item(item: Dictionary, price: int) -> void:
	var player = get_tree().get_first_node_in_group("player")
	if not is_instance_valid(player):
		_close_menu()
		return
		
	player.coins -= price
	player.coins_changed.emit(player.coins)
	
	var action = item.get("action_type", "stat")
	if action == "add_weapon":
		var new_w = preload("res://weapon.tscn").instantiate()
		new_w.weapon_type = item["weapon_type"]
		player.add_child(new_w)
		if player.has_method("reposition_weapons"):
			player.reposition_weapons()
	elif action == "upgrade_weapon":
		var w = item["target_weapon"]
		if is_instance_valid(w):
			w.level += 1
			w.damage_multiplier *= 1.12
			w.fire_rate *= 1.08
			w.update_timer()
	else:
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
				"near_field_damage_pct":
					player.near_field_damage_modifier += val / 100.0
				"ranged_damage_pct":
					player.ranged_damage_modifier += val / 100.0
				"damage_pct":
					for w in player.get_weapons() if player.has_method("get_weapons") else []:
						w.damage_multiplier *= (1.0 + val / 100.0)
				"fire_rate_pct":
					for w in player.get_weapons() if player.has_method("get_weapons") else []:
						w.fire_rate *= (1.0 + val / 100.0)
						w.update_timer()
					
	_close_menu()

func _close_menu() -> void:
	get_tree().paused = false
	queue_free()
