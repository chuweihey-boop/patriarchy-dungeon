extends Node2D

const ENEMY_SCENE = preload("res://enemy.tscn")
const UPGRADE_MENU_SCENE = preload("res://upgrade_menu.tscn")

@onready var player = get_tree().get_first_node_in_group("player")
@onready var hud = $HUD

var time_elapsed: float = 0.0
var merge_timer: float = 0.0
const MERGE_INTERVAL: float = 1.0

func _ready() -> void:
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
		
	# Instantiate and display starting weapon selection menu
	var weapon_selection = preload("res://weapon_selection_menu.tscn").instantiate()
	add_child(weapon_selection)

func _process(delta: float) -> void:
	if not get_tree().paused:
		time_elapsed += delta
		hud.update_timer(time_elapsed)
		
		# Merge coins check
		merge_timer += delta
		if merge_timer >= MERGE_INTERVAL:
			merge_timer = 0.0
			_check_and_merge_coins()

func _on_enemy_spawner_timeout() -> void:
	if not player:
		return
		
	# Instantiate a new copy of the Enemy
	var new_enemy = ENEMY_SCENE.instantiate()
	
	# Use polar coordinates to pick a random direction vector
	var random_angle = randf_range(0.0, 2 * PI)
	var spawn_direction = Vector2(cos(random_angle), sin(random_angle))
	
	# Multiply direction by distance (~700-800 pixels is just off-screen)
	var spawn_distance = 750.0
	var spawn_offset = spawn_direction * spawn_distance
	
	# Position the enemy relative to where the player currently is
	new_enemy.global_position = player.global_position + spawn_offset
	
	# Inject the enemy into the active game loop
	add_child(new_enemy)

func _on_player_level_up(new_level: int) -> void:
	hud.update_level(new_level)
	
	# Pause the game tree
	get_tree().paused = true
	
	# Instantiate and display the upgrade menu
	var menu = UPGRADE_MENU_SCENE.instantiate()
	add_child(menu)

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


