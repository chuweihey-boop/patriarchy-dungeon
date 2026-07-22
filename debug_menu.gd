extends CanvasLayer

const UPGRADE_MENU_SCENE = preload("res://upgrade_menu.tscn")

var weapons = ["Egg Basket", "Negi", "Fish Knife", "Wooden Sword"]
var weapon_checkboxes = []

var enemy_num_edit: LineEdit
var enemy_dmg_edit: LineEdit
var enemy_hp_edit: LineEdit

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS # Keep processing when tree is paused

	var panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(450, 450)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_right", 5)
	scroll.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(vbox)
	add_child(panel)
	
	var close_btn = Button.new()
	close_btn.text = "Close Debug Menu"
	close_btn.pressed.connect(func():
		get_tree().paused = false
		queue_free()
	)
	vbox.add_child(close_btn)
	
	var shop_btn = Button.new()
	shop_btn.text = "1. Enter Shop"
	shop_btn.pressed.connect(_on_shop_pressed)
	vbox.add_child(shop_btn)
	
	vbox.add_child(HSeparator.new())
	
	var wlbl = Label.new()
	wlbl.text = "2. Weapons:"
	vbox.add_child(wlbl)
	
	var hbox_btns = HBoxContainer.new()
	var check_all = Button.new()
	check_all.text = "Check All"
	check_all.pressed.connect(func(): _set_all_weapons(true))
	var uncheck_all = Button.new()
	uncheck_all.text = "Uncheck All"
	uncheck_all.pressed.connect(func(): _set_all_weapons(false))
	hbox_btns.add_child(check_all)
	hbox_btns.add_child(uncheck_all)
	vbox.add_child(hbox_btns)
	
	var player = get_tree().get_first_node_in_group("player")
	var active_weapons = []
	if player:
		for child in player.get_children():
			if "weapon_type" in child:
				active_weapons.append(child.weapon_type)
	
	for i in range(weapons.size()):
		var cb = CheckBox.new()
		cb.text = weapons[i]
		cb.button_pressed = active_weapons.has(i)
		cb.toggled.connect(func(toggled_on): _on_weapon_toggled(toggled_on, i))
		weapon_checkboxes.append(cb)
		vbox.add_child(cb)
		
	vbox.add_child(HSeparator.new())
	
	var elbl = Label.new()
	elbl.text = "3. Enemy Multipliers (Base 100):"
	vbox.add_child(elbl)
	
	var grid = GridContainer.new()
	grid.columns = 2
	vbox.add_child(grid)
	
	var world = get_tree().current_scene
	var num_mult = world.debug_enemy_num_mult if ("debug_enemy_num_mult" in world) else 1.0
	var dmg_mult = world.debug_enemy_dmg_mult if ("debug_enemy_dmg_mult" in world) else 1.0
	var hp_mult = world.debug_enemy_hp_mult if ("debug_enemy_hp_mult" in world) else 1.0
	
	var lbl_num = Label.new()
	lbl_num.text = "Number:"
	enemy_num_edit = LineEdit.new()
	enemy_num_edit.text = str(int(num_mult * 100))
	enemy_num_edit.text_changed.connect(func(text):
		if text.is_valid_float() and "debug_enemy_num_mult" in world:
			world.debug_enemy_num_mult = text.to_float() / 100.0
	)
	grid.add_child(lbl_num)
	grid.add_child(enemy_num_edit)
	
	var lbl_dmg = Label.new()
	lbl_dmg.text = "Damage:"
	enemy_dmg_edit = LineEdit.new()
	enemy_dmg_edit.text = str(int(dmg_mult * 100))
	enemy_dmg_edit.text_changed.connect(func(text):
		if text.is_valid_float() and "debug_enemy_dmg_mult" in world:
			world.debug_enemy_dmg_mult = text.to_float() / 100.0
	)
	grid.add_child(lbl_dmg)
	grid.add_child(enemy_dmg_edit)
	
	var lbl_hp = Label.new()
	lbl_hp.text = "HP:"
	enemy_hp_edit = LineEdit.new()
	enemy_hp_edit.text = str(int(hp_mult * 100))
	enemy_hp_edit.text_changed.connect(func(text):
		if text.is_valid_float() and "debug_enemy_hp_mult" in world:
			world.debug_enemy_hp_mult = text.to_float() / 100.0
	)
	grid.add_child(lbl_hp)
	grid.add_child(enemy_hp_edit)

	vbox.add_child(HSeparator.new())
	
	var plbl = Label.new()
	plbl.text = "4. Player Stats:"
	vbox.add_child(plbl)
	
	var pgrid = GridContainer.new()
	pgrid.columns = 2
	vbox.add_child(pgrid)
	
	if player:
		_add_player_stat_edit(pgrid, player, "HP (Current)", "health", func(val):
			player.health = min(val, player.max_health)
			player.health_changed.emit(player.health, player.max_health)
		)
		_add_player_stat_edit(pgrid, player, "Max HP", "max_health", func(val):
			player.max_health = val
			if player.health > player.max_health:
				player.health = player.max_health
			player.health_changed.emit(player.health, player.max_health)
		)
		_add_player_stat_edit(pgrid, player, "Coins", "coins", func(val):
			player.coins = int(val)
			player.coins_changed.emit(player.coins)
		)
		_add_player_stat_edit(pgrid, player, "Speed (Base)", "default_speed", func(val):
			player.default_speed = val
			player.speed = val
		)
		_add_player_stat_edit(pgrid, player, "Melee Dmg Mod", "near_field_damage_modifier", func(val):
			player.near_field_damage_modifier = val
		)
		_add_player_stat_edit(pgrid, player, "Ranged Dmg Mod", "ranged_damage_modifier", func(val):
			player.ranged_damage_modifier = val
		)
		_add_player_stat_edit(pgrid, player, "Atk Freq Mod", "attack_frequency_modifier", func(val):
			player.attack_frequency_modifier = val
			for c in player.get_children():
				if c.has_method("update_timer"):
					c.update_timer()
		)

func _add_player_stat_edit(parent: Control, player: Node, label_text: String, prop_name: String, callback: Callable) -> void:
	var lbl = Label.new()
	lbl.text = label_text + ":"
	var edit = LineEdit.new()
	var val = player.get(prop_name)
	edit.text = str(IntOrFloat(val)) if val != null else "0"
	
	edit.text_changed.connect(func(text):
		if text.is_valid_float():
			callback.call(text.to_float())
	)
	
	parent.add_child(lbl)
	parent.add_child(edit)

func IntOrFloat(val):
	if typeof(val) == TYPE_FLOAT:
		return val
	return int(val)

func _set_all_weapons(state: bool) -> void:
	for i in range(weapon_checkboxes.size()):
		weapon_checkboxes[i].button_pressed = state

func _on_weapon_toggled(toggled_on: bool, index: int) -> void:
	var player = get_tree().get_first_node_in_group("player")
	if not player: return
	
	if toggled_on:
		var has_it = false
		for c in player.get_children():
			if "weapon_type" in c and c.weapon_type == index:
				has_it = true
				break
		if not has_it:
			var w_scene = preload("res://weapon.tscn")
			var inst = w_scene.instantiate()
			inst.name = "Weapon" + str(index)
			inst.weapon_type = index
			player.add_child(inst)
	else:
		for c in player.get_children():
			if "weapon_type" in c and c.weapon_type == index:
				c.queue_free()

func _on_shop_pressed() -> void:
	var menu = UPGRADE_MENU_SCENE.instantiate()
	get_tree().current_scene.add_child(menu)
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.is_echo():
		if event.keycode == KEY_ESCAPE:
			get_viewport().set_input_as_handled()
			get_tree().paused = false
			queue_free()
