extends CharacterBody2D

@export var speed: float = 100.0
@export var health: float = 3.0
@export var damage: float = 1.0

const GEM_SCENE = preload("res://experience_gem.tscn")
const SLOW_ZONE_SCENE = preload("res://slow_zone.tscn")
const BROWN_CUBE_SCENE = preload("res://brown_cube.tscn")

var player: CharacterBody2D = null
var yellow_circle_timer: float = 0.0
var brown_cube_timer: float = 0.0

func _ready() -> void:
	# Add dynamically to enemies group
	add_to_group("enemies")
	# Find the player in the world scene dynamically
	player = get_tree().get_first_node_in_group("player")

func _physics_process(delta: float) -> void:
	# Spawning timers
	yellow_circle_timer += delta
	if yellow_circle_timer >= 5.0:
		yellow_circle_timer = 0.0
		_spawn_yellow_circle()
		
	brown_cube_timer += delta
	if brown_cube_timer >= 10.0:
		brown_cube_timer = 0.0
		_spawn_brown_cube()

	if player:
		# 1. Get the direction vector pointing toward the player
		var direction = global_position.direction_to(player.global_position)
		
		# 2. Set velocity toward player and move
		velocity = direction * speed
		move_and_slide()

func take_damage(amount: float) -> void:
	health -= amount
	if health <= 0:
		_die()

func _die() -> void:
	var gem = GEM_SCENE.instantiate()
	gem.global_position = global_position
	get_tree().current_scene.call_deferred("add_child", gem)
	queue_free()

func _spawn_yellow_circle() -> void:
	var zone = SLOW_ZONE_SCENE.instantiate()
	zone.global_position = global_position
	get_tree().current_scene.add_child(zone)

func _spawn_brown_cube() -> void:
	var cube = BROWN_CUBE_SCENE.instantiate()
	cube.global_position = global_position
	get_tree().current_scene.add_child(cube)
