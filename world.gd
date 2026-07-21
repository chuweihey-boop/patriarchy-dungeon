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
var is_transitioning_round: bool = false
var round_transition_timer: float = 0.0

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
		if is_transitioning_round:
			round_transition_timer += delta
			if round_transition_timer >= 3.0:
				is_transitioning_round = false
				current_round += 1
				if current_round > 5:
					game_won = true
					round_time_remaining = 0.0
					_clear_world()
					hud.update_timer(0.0, 5)
					hud.show_wave_warning("VICTORY! ALL 5 ROUNDS SURVIVED!")
					$EnemySpawner.stop()
					return
				else:
					_clear_world()
					round_time_remaining = ROUND_DURATION
					wave_warning_shown = false
					hud.show_wave_warning("ROUND %d START!" % current_round)
					$EnemySpawner.start()
			return

		round_time_remaining -= delta
		if round_time_remaining <= 0.0:
			_start_round_transition()
			return
				
		# Check for last 1 minute wave warning
		if round_time_remaining <= 60.0 and not wave_warning_shown:
			wave_warning_shown = true
			hud.show_wave_warning("A BIG WAVE OF MONSTERS IS COMING!")
			
		hud.update_timer(round_time_remaining, current_round)

func _start_round_transition() -> void:
	is_transitioning_round = true
	round_transition_timer = 0.0
	$EnemySpawner.stop()
	
	var coins_collected = 0
	if is_instance_valid(player):
		if "absorb_pickups_on_round_end" in player and player.absorb_pickups_on_round_end:
			for gem in get_tree().get_nodes_in_group("experience_gems"):
				if is_instance_valid(gem) and not gem.is_queued_for_deletion():
					coins_collected += gem.xp_value
					if "is_being_collected" in gem:
						gem.is_being_collected = true
					if "magnet_speed" in gem:
						gem.magnet_speed = 850.0
			for heart in get_tree().get_nodes_in_group("heart_pickups"):
				if is_instance_valid(heart) and not heart.is_queued_for_deletion():
					if player.has_method("heal"):
						player.heal(heart.heal_amount)
					heart.queue_free()
		else:
			if "coin_recycle_pct" in player and player.coin_recycle_pct > 0.0:
				var leftover_coins = 0
				var all_gems = get_tree().get_nodes_in_group("experience_gems")
				for gem in all_gems:
					if is_instance_valid(gem) and not gem.is_queued_for_deletion():
						leftover_coins += gem.xp_value
				if leftover_coins > 0:
					var recycled = int(round(leftover_coins * (player.coin_recycle_pct / 100.0)))
					if recycled > 0:
						coins_collected = recycled
						player.coins += recycled
						player.coins_changed.emit(player.coins)
						for gem in all_gems:
							if is_instance_valid(gem) and "is_being_collected" in gem:
								gem.is_being_collected = true
								gem.magnet_speed = 750.0
								
	hud.show_wave_warning("%d COINS COLLECTED!" % coins_collected)
	
	# Show shop between rounds
	get_tree().paused = true
	var menu = UPGRADE_MENU_SCENE.instantiate()
	add_child(menu)

func _clear_world() -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(enemy):
			enemy.queue_free()
	for gem in get_tree().get_nodes_in_group("experience_gems"):
		if is_instance_valid(gem):
			gem.queue_free()
	for heart in get_tree().get_nodes_in_group("heart_pickups"):
		if is_instance_valid(heart):
			heart.queue_free()
	for child in get_children():
		if child is EffectSprite:
			child.queue_free()
	for node in get_tree().current_scene.get_children():
		if "SlowZone" in node.name or "BrownCube" in node.name:
			node.queue_free()

func _on_enemy_spawner_timeout() -> void:
	if not player or game_won:
		return
		
	# Gentle in Round 1 (1 monster), scaling slowly in later rounds
	var spawn_count = 1 + (current_round - 1) * 1
	var is_wave = round_time_remaining <= 60.0
	if is_wave:
		spawn_count = int(spawn_count * 1.5)
		$EnemySpawner.wait_time = max(0.4, (1.2 - (current_round - 1) * 0.15) * 0.5)
	else:
		$EnemySpawner.wait_time = max(0.5, 1.5 - (current_round - 1) * 0.15)
		
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





