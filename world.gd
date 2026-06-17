extends Node2D

const ENEMY_SCENE = preload("res://enemy.tscn")
const UPGRADE_MENU_SCENE = preload("res://upgrade_menu.tscn")

@onready var player = get_tree().get_first_node_in_group("player")
@onready var hud = $HUD

var time_elapsed: float = 0.0

func _ready() -> void:
	if player:
		# Connect player signals to HUD
		player.health_changed.connect(hud.update_health)
		player.experience_changed.connect(hud.update_xp)
		player.level_up.connect(_on_player_level_up)
		
		# Set initial HUD state
		hud.update_health(player.health, player.max_health)
		hud.update_xp(player.experience, player.experience_required)
		hud.update_level(player.level)
		
	# Instantiate and display starting weapon selection menu
	var weapon_selection = preload("res://weapon_selection_menu.tscn").instantiate()
	add_child(weapon_selection)

func _process(delta: float) -> void:
	if not get_tree().paused:
		time_elapsed += delta
		hud.update_timer(time_elapsed)

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

