extends CharacterBody2D

@export var speed: float = 100.0
@export var health: float = 12.0
@export var damage: float = 10.0

const GEM_SCENE = preload("res://experience_gem.tscn")
const SLOW_ZONE_SCENE = preload("res://slow_zone.tscn")
const BROWN_CUBE_SCENE = preload("res://brown_cube.tscn")

var player: CharacterBody2D = null
var yellow_circle_timer: float = 0.0
var brown_cube_timer: float = 0.0
var can_spawn_brown_cube: bool = false
var can_spawn_slow_zone: bool = false

func _ready() -> void:
	# Add dynamically to enemies group
	add_to_group("enemies")
	# Find the player in the world scene dynamically
	player = get_tree().get_first_node_in_group("player")
	# Only 5% of monsters spawn shit blocks
	can_spawn_brown_cube = randf() < 0.05
	# Only 5% of monsters spawn slow zones
	can_spawn_slow_zone = randf() < 0.05

func _physics_process(delta: float) -> void:
	# Spawning timers
	if can_spawn_slow_zone:
		yellow_circle_timer += delta
		if yellow_circle_timer >= 5.0:
			yellow_circle_timer = 0.0
			_spawn_yellow_circle()
		
	if can_spawn_brown_cube:
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
	_spawn_damage_number(amount)
	if health <= 0:
		_die()

func _spawn_damage_number(amount: float) -> void:
	var label = Label.new()
	label.text = str(int(round(amount)))
	
	var font = preload("res://fonts/Xolonium-Regular.ttf")
	label.add_theme_font_override("font", font)
	
	var base_size = 16
	var font_size = int(clamp(base_size + amount * 1.5, base_size, 72))
	label.add_theme_font_size_override("font_size", font_size)
	
	label.add_theme_color_override("font_color", Color(0.9, 0.1, 0.1))
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 4)
	
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	label.grow_vertical = Control.GROW_DIRECTION_BOTH
	
	get_tree().current_scene.add_child(label)
	
	var offset = Vector2(randf_range(-15.0, 15.0), randf_range(-25.0, -10.0))
	label.global_position = global_position + offset
	
	var tween = label.create_tween().set_parallel(true)
	var target_pos = label.global_position + Vector2(randf_range(-10.0, 10.0), -50.0)
	tween.tween_property(label, "global_position", target_pos, 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(label.queue_free)

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
