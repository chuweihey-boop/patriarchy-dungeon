extends Node2D

const ENEMY_SCENE = preload("res://enemy.tscn")
const UPGRADE_MENU_SCENE = preload("res://upgrade_menu.tscn")

@onready var player = get_tree().get_first_node_in_group("player")
@onready var hud = $HUD

var current_round: int = 1
const ROUND_DURATION: float = 180.0 # 3 minutes per round
var round_time_remaining: float = ROUND_DURATION
var wave_warning_shown: bool = false
var game_won: bool = false

var merge_timer: float = 0.0
const MERGE_INTERVAL: float = 1.0

func _ready() -> void:
	$EnemySpawner.wait_time = 1.0
	if player:
		# Connect player signals to HUD
		player.health_changed.connect(hud.update_health)
		player.experience_changed.connect(hud.update_xp)
		player.level_up.connect(_on_player_level_up)
		player.coins_changed.connect(hud.update_coins)
		
		# Set initial HUD state
		hud.update_health(player.health, player.max_health)
		hud.update_xp(player.experience, player.experience_required)
		hud.update_level(player.level)
		hud.update_coins(player.coins)
		hud.update_timer(round_time_remaining, current_round)
		hud.show_wave_warning("ROUND 1 START!")
		
	# Instantiate and display starting weapon selection menu
	var weapon_selection = preload("res://weapon_selection_menu.tscn").instantiate()
	add_child(weapon_selection)

func _process(delta: float) -> void:
	if not get_tree().paused and not game_won:
		round_time_remaining -= delta
		if round_time_remaining <= 0.0:
			current_round += 1
			if current_round > 5:
				game_won = true
				round_time_remaining = 0.0
				hud.update_timer(0.0, 5)
				hud.show_wave_warning("VICTORY! ALL 5 ROUNDS SURVIVED!")
				$EnemySpawner.stop()
				return
			else:
				_clear_world()
				round_time_remaining = ROUND_DURATION
				wave_warning_shown = false
				hud.show_wave_warning("ROUND %d START!" % current_round)
				
		# Check for last 1 minute wave warning
		if round_time_remaining <= 60.0 and not wave_warning_shown:
			wave_warning_shown = true
			hud.show_wave_warning("A BIG WAVE OF MONSTERS IS COMING!")
			
		hud.update_timer(round_time_remaining, current_round)
		
		# Merge coins check
		merge_timer += delta
		if merge_timer >= MERGE_INTERVAL:
			merge_timer = 0.0
			_check_and_merge_coins()

func _clear_world() -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(enemy):
			enemy.queue_free()
	for child in get_children():
		if child is EffectSprite:
			child.queue_free()
	for node in get_tree().current_scene.get_children():
		if "SlowZone" in node.name or "BrownCube" in node.name:
			node.queue_free()

func _on_enemy_spawner_timeout() -> void:
	if not player or game_won:
		return
		
	# Determine spawn count and speed (2x during last 1 minute wave)
	var spawn_count = 1 + current_round # R1: 2, R2: 3, R3: 4, R4: 5, R5: 6
	var is_wave = round_time_remaining <= 60.0
	if is_wave:
		spawn_count *= 2
		$EnemySpawner.wait_time = max(0.15, (1.0 - (current_round - 1) * 0.15) * 0.5)
	else:
		$EnemySpawner.wait_time = max(0.25, 1.0 - (current_round - 1) * 0.15)
		
	for i in range(spawn_count):
		var random_angle = randf_range(0.0, 2 * PI)
		var spawn_direction = Vector2(cos(random_angle), sin(random_angle))
		var spawn_distance = randf_range(700.0, 850.0)
		var spawn_offset = spawn_direction * spawn_distance
		var spawn_pos = player.global_position + spawn_offset
		
		var enemy_hp = 12.0 * (1.0 + (current_round - 1) * 0.5)
		var enemy_dmg = 10.0 * (1.0 + (current_round - 1) * 0.3)
		
		_spawn_alert_and_enemy(spawn_pos, enemy_hp, enemy_dmg)

func _spawn_alert_and_enemy(spawn_pos: Vector2, hp: float, dmg: float) -> void:
	var effect = Sprite2D.new()
	effect.set_script(preload("res://effect_sprite.gd"))
	add_child(effect)
	effect.global_position = spawn_pos
	effect.scale = Vector2(2.5, 2.5)
	effect.setup(preload("res://art/effects/alert/spritesheet.png"), "res://art/effects/alert/spritesheet.txt", 20.0, false)
	
	effect.animation_finished.connect(func():
		if not is_instance_valid(player) or game_won:
			return
		var new_enemy = ENEMY_SCENE.instantiate()
		new_enemy.health = hp
		new_enemy.damage = dmg
		new_enemy.global_position = spawn_pos
		add_child(new_enemy)
	)

func _on_player_level_up(new_level: int) -> void:
	hud.update_level(new_level)
	get_tree().paused = true
	
	var effect = Sprite2D.new()
	effect.set_script(preload("res://effect_sprite.gd"))
	effect.process_mode = PROCESS_MODE_ALWAYS
	add_child(effect)
	effect.global_position = player.global_position + Vector2(0, -80)
	effect.scale = Vector2(2.0, 2.0)
	effect.z_index = 50
	effect.setup(preload("res://art/effects/levelup/symbol_level_up_text_001_large_blue/spritesheet.png"), "res://art/effects/levelup/symbol_level_up_text_001_large_blue/spritesheet.txt", 25.0, false)
	
	effect.animation_finished.connect(func():
		var menu = UPGRADE_MENU_SCENE.instantiate()
		add_child(menu)
	)

const STATS_MENU_SCENE = preload("res://stats_menu.tscn")
var stats_menu_instance = null

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.is_echo():
		if event.keycode == KEY_I:
			if is_instance_valid(stats_menu_instance):
				stats_menu_instance.close_menu()
			elif not get_tree().paused:
				get_viewport().set_input_as_handled()
				stats_menu_instance = STATS_MENU_SCENE.instantiate()
				add_child(stats_menu_instance)


func _check_and_merge_coins() -> void:
	var all_gems = get_tree().get_nodes_in_group("experience_gems")
	var small_gems = []
	for gem in all_gems:
		if is_instance_valid(gem) and gem.xp_value == 1 and not gem.is_being_collected:
			small_gems.append(gem)
			
	# If small coins count is <= 15, we don't merge them.
	if small_gems.size() <= 15:
		return
		
	var merged_this_tick = false
	var deleted_gems = {}
	
	for i in range(small_gems.size()):
		var base_gem = small_gems[i]
		if base_gem in deleted_gems or not is_instance_valid(base_gem):
			continue
			
		# Find distances to other valid small gems
		var neighbors = []
		for j in range(small_gems.size()):
			if i == j:
				continue
			var other_gem = small_gems[j]
			if other_gem in deleted_gems or not is_instance_valid(other_gem):
				continue
			var dist = base_gem.global_position.distance_to(other_gem.global_position)
			neighbors.append({"gem": other_gem, "dist": dist})
			
		# Sort by distance ascending
		neighbors.sort_custom(func(a, b): return a.dist < b.dist)
		
		# If we have at least 4 valid neighbors, check the 4th closest neighbor
		if neighbors.size() >= 4:
			var furthest_neighbor_dist = neighbors[3].dist
			if furthest_neighbor_dist < 300.0:
				var group = [base_gem]
				for k in range(4):
					group.append(neighbors[k].gem)
					
				# Calculate average position
				var avg_pos = Vector2.ZERO
				for g in group:
					avg_pos += g.global_position
				avg_pos /= 5.0
				
				# Spawn big coin
				_spawn_big_coin(avg_pos)
				
				# Mark all as deleted and free them
				for g in group:
					deleted_gems[g] = true
					g.queue_free()
					
				merged_this_tick = true
				
	if merged_this_tick:
		print("Merged groups of 5 small coins into big coins.")


func _spawn_big_coin(pos: Vector2) -> void:
	var gem_scene = preload("res://experience_gem.tscn")
	var big_gem = gem_scene.instantiate()
	big_gem.xp_value = 5
	big_gem.global_position = pos
	add_child(big_gem)


