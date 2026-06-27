extends CanvasLayer

var stat_weights = {
	"max_health": 2.2,
	"regen_speed": 26.0,
	"speed_pct": 3.2,
	"damage_pct": 5.5,
	"near_field_damage_pct": 4.0,
	"ranged_damage_pct": 4.0,
	"fire_rate_pct": 5.5,
	"shield": 30.0
}

var test_items = [
	{
		"id": "iron_fist",
		"title": "🥊 Iron Knuckles",
		"desc": "+12% Near Field Damage",
		"stats": {"near_field_damage_pct": 12.0}
	},
	{
		"id": "sniper_lens",
		"title": "🔭 Sniper Scope",
		"desc": "+12% Ranged Attack Damage",
		"stats": {"ranged_damage_pct": 12.0}
	},
	{
		"id": "master_seal",
		"title": "☯️ Master Emblem",
		"desc": "+8% Near Field & +8% Ranged Damage",
		"stats": {"near_field_damage_pct": 8.0, "ranged_damage_pct": 8.0}
	},
	{
		"id": "vitality",
		"title": "❤️ Vitality Ring",
		"desc": "+15 Max HP",
		"stats": {"max_health": 15.0}
	},
	{
		"id": "troll_blood",
		"title": "🌿 Troll Blood",
		"desc": "+1 HP Regen/sec",
		"stats": {"regen_speed": 1.0}
	},
	{
		"id": "hermes",
		"title": "⚡ Hermes Boots",
		"desc": "+8% Move Speed",
		"stats": {"speed_pct": 8.0}
	},
	{
		"id": "whetstone",
		"title": "⚔️ Whetstone",
		"desc": "+10% Weapon Damage",
		"stats": {"damage_pct": 10.0}
	},
	{
		"id": "rapid_string",
		"title": "🏹 Rapid String",
		"desc": "+5% Attack Speed",
		"stats": {"fire_rate_pct": 5.0}
	},
	{
		"id": "ranger_kit",
		"title": "🪶 Ranger Kit",
		"desc": "+3% Attack Speed & +5% Damage",
		"stats": {"fire_rate_pct": 3.0, "damage_pct": 5.0}
	},
	{
		"id": "iron_plate",
		"title": "🛡️ Iron Plating",
		"desc": "+1 Shield, -3% Move Speed",
		"stats": {"shield": 1.0, "speed_pct": -3.0}
	},
	{
		"id": "berserk",
		"title": "🔥 Berserk Charm",
		"desc": "+18% Damage, -10 Max HP",
		"stats": {"damage_pct": 18.0, "max_health": -10.0}
	},
	{
		"id": "cheetah_energy",
		"title": "🏃 Cheetah Energy",
		"desc": "+15% Move Speed, -6% Weapon Damage",
		"stats": {"speed_pct": 15.0, "damage_pct": -6.0}
	},
	{
		"id": "leech_seed",
		"title": "🩸 Leech Seed",
		"desc": "+1.5 HP Regen/sec, -15 Max HP",
		"stats": {"regen_speed": 1.5, "max_health": -15.0}
	},
	{
		"id": "espresso_shot",
		"title": "☕ Espresso Shot",
		"desc": "+12% Attack Speed, -5% Move Speed",
		"stats": {"fire_rate_pct": 12.0, "speed_pct": -5.0}
	},
	{
		"id": "heavy_dumbbell",
		"title": "🏋️ Heavy Dumbbell",
		"desc": "+20 Max HP, -4% Move Speed",
		"stats": {"max_health": 20.0, "speed_pct": -4.0}
	},
	{
		"id": "glass_cannon",
		"title": "🎯 Glass Cannon",
		"desc": "+25% Ranged Attack Damage, -1 Shield",
		"stats": {"ranged_damage_pct": 25.0, "shield": -1.0}
	},
	{
		"id": "oni_mask",
		"title": "👹 Oni Mask",
		"desc": "+25% Near Field Damage, -0.8 HP Regen/sec",
		"stats": {"near_field_damage_pct": 25.0, "regen_speed": -0.8}
	}
]

var offered_items: Array = []
var current_refresh_cost: int = 5

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
		
	_generate_shop_items()
	_rebuild_ui()

func _generate_shop_items() -> void:
	var player = get_tree().get_first_node_in_group("player")
	var current_weapons = player.get_weapons() if is_instance_valid(player) and player.has_method("get_weapons") else []
	
	var pool = test_items.duplicate()
	if current_weapons.size() < 4:
		var owned_types = []
		for w in current_weapons:
			owned_types.append(w.weapon_type)
		var names = ["🥚 Egg Basket", "葱 Negi", "🔪 Fish Knife", "🗡️ Wooden Sword"]
		for tid in [0, 1, 2, 3]:
			if not tid in owned_types:
				pool.append({
					"id": "add_w_" + str(tid),
					"action_type": "add_weapon",
					"weapon_type": tid,
					"title": "➕ Equip " + names[tid],
					"desc": "Add new weapon (Slot " + str(current_weapons.size() + 1) + "/4)",
					"price": 50
				})
				
	for w in current_weapons:
		var w_name = w.get_weapon_name() if w.has_method("get_weapon_name") else "Weapon"
		pool.append({
			"id": "up_w_" + str(w.get_instance_id()),
			"action_type": "upgrade_weapon",
			"target_weapon": w,
			"title": "⬆️ Upgrade " + w_name,
			"desc": "+8% Damage, +4% Attack Speed (to Lv." + str(w.level + 1) + ")",
			"price": 45 * w.level
		})
	
	pool.shuffle()
	offered_items = pool.slice(0, min(3, pool.size()))

func _rebuild_ui() -> void:
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
	coins_label.text = "💰 Coins: " + str(current_coins)
	coins_label.add_theme_font_override("font", preload("res://fonts/Xolonium-Regular.ttf"))
	coins_label.add_theme_font_size_override("font_size", 22)
	coins_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	header_hbox.add_child(coins_label)
	
	var cards_vbox = VBoxContainer.new()
	cards_vbox.add_theme_constant_override("separation", 15)
	cards_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cards_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	left_vbox.add_child(cards_vbox)
	
	for item in offered_items:
		var price = calculate_price(item)
		var can_afford = current_coins >= price
		
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(0, 80)
		var price_str = ("💰 " + str(price) + " Coins") if can_afford else ("❌ " + str(price) + " Coins (Too Expensive)")
		btn.text = item["title"] + "  [" + price_str + "]\n" + item["desc"]
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
			
	if offered_items.is_empty():
		var empty_lbl = Label.new()
		empty_lbl.text = "All offered items purchased! Refresh for free!"
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_lbl.add_theme_font_override("font", preload("res://fonts/Xolonium-Regular.ttf"))
		empty_lbl.add_theme_font_size_override("font_size", 16)
		empty_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
		cards_vbox.add_child(empty_lbl)
			
	var action_hbox = HBoxContainer.new()
	action_hbox.add_theme_constant_override("separation", 15)
	left_vbox.add_child(action_hbox)
	
	var effective_cost = 0 if offered_items.is_empty() else current_refresh_cost
	var can_reroll = current_coins >= effective_cost
	var refresh_btn = Button.new()
	refresh_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	refresh_btn.custom_minimum_size = Vector2(0, 50)
	var cost_str = ("💰 " + str(effective_cost) + " Coins") if effective_cost > 0 else "FREE!"
	refresh_btn.text = ("🔄 Refresh (" + cost_str + ")") if can_reroll else ("❌ Refresh (" + cost_str + ")")
	refresh_btn.disabled = not can_reroll
	refresh_btn.add_theme_font_override("font", preload("res://fonts/Xolonium-Regular.ttf"))
	refresh_btn.add_theme_font_size_override("font_size", 16)
	if can_reroll:
		refresh_btn.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0))
		refresh_btn.pressed.connect(func():
			if is_instance_valid(player) and player.coins >= effective_cost:
				player.coins -= effective_cost
				player.coins_changed.emit(player.coins)
				if effective_cost > 0:
					current_refresh_cost += 5
				_generate_shop_items()
				_rebuild_ui()
		)
	action_hbox.add_child(refresh_btn)
	
	var done_btn = Button.new()
	done_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	done_btn.custom_minimum_size = Vector2(0, 50)
	done_btn.text = "✅ Done / Continue Game"
	done_btn.add_theme_font_override("font", preload("res://fonts/Xolonium-Regular.ttf"))
	done_btn.add_theme_font_size_override("font_size", 16)
	done_btn.add_theme_color_override("font_color", Color(0.4, 1.0, 0.5))
	done_btn.pressed.connect(_close_menu)
	action_hbox.add_child(done_btn)
	
	# --- RIGHT SIDE: CHARACTER STATS & BUILD ---
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
		_add_stat_row(stats_list, "🌿 HP Regen", str(snapped(player.regen_speed, 0.1)) + " / sec")
		_add_stat_row(stats_list, "🛡️ Shield", str(player.shield))
		_add_stat_row(stats_list, "⚡ Move Speed", str(int(player.default_speed)))
		
		var near_pct = int(player.near_field_damage_modifier * 100.0)
		var range_pct = int(player.ranged_damage_modifier * 100.0)
		_add_stat_row(stats_list, "🥊 Near Field Dmg", str(near_pct) + "%")
		_add_stat_row(stats_list, "🔭 Ranged Dmg", str(range_pct) + "%")
		
		var w_title = Label.new()
		w_title.text = "\n🗡️ WEAPON QUOTAS (" + str(current_weapons.size()) + " / 4)"
		w_title.add_theme_font_override("font", preload("res://fonts/Xolonium-Regular.ttf"))
		w_title.add_theme_font_size_override("font_size", 20)
		w_title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
		stats_list.add_child(w_title)
		
		for i in range(4):
			var slot_row = HBoxContainer.new()
			stats_list.add_child(slot_row)
			
			if i < current_weapons.size():
				var w = current_weapons[i]
				var wn = w.get_weapon_name() if w.has_method("get_weapon_name") else "Weapon"
				var resell_price = int(25 * w.level)
				
				var wl = Label.new()
				wl.text = wn + " (Lv." + str(w.level) + ")"
				wl.add_theme_font_override("font", preload("res://fonts/Xolonium-Regular.ttf"))
				wl.add_theme_font_size_override("font_size", 16)
				wl.add_theme_color_override("font_color", Color(0.8, 0.95, 1.0))
				slot_row.add_child(wl)
				
				var sp2 = Control.new()
				sp2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				slot_row.add_child(sp2)
				
				var sell_btn = Button.new()
				sell_btn.text = "💰 Sell (+" + str(resell_price) + ")"
				sell_btn.add_theme_font_override("font", preload("res://fonts/Xolonium-Regular.ttf"))
				sell_btn.add_theme_font_size_override("font_size", 14)
				sell_btn.add_theme_color_override("font_color", Color(1.0, 0.7, 0.3))
				sell_btn.pressed.connect(func(): _sell_weapon(w, resell_price))
				slot_row.add_child(sell_btn)
			else:
				var el = Label.new()
				el.text = "Slot " + str(i + 1) + ": [Empty]"
				el.add_theme_font_override("font", preload("res://fonts/Xolonium-Regular.ttf"))
				el.add_theme_font_size_override("font_size", 16)
				el.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
				slot_row.add_child(el)

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
			w.damage_multiplier *= 1.08
			w.fire_rate *= 1.04
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
					
	offered_items.erase(item)
	_rebuild_ui()

func _sell_weapon(weapon: Node2D, resell_price: int) -> void:
	var player = get_tree().get_first_node_in_group("player")
	if is_instance_valid(player) and is_instance_valid(weapon):
		player.coins += resell_price
		player.coins_changed.emit(player.coins)
		weapon.queue_free()
		if player.has_method("reposition_weapons"):
			player.reposition_weapons()
		_rebuild_ui()

func _close_menu() -> void:
	get_tree().paused = false
	queue_free()
