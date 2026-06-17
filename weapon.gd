extends Node2D

enum WeaponType { KNIFE, WAND }

@export var bullet_scene: PackedScene = preload("res://bullet.tscn")
@export var weapon_type: WeaponType = WeaponType.WAND
@export var damage_multiplier: float = 1.0

var fire_rate: float = 1.0 # Shots per second
var shoot_range: float = 600.0

@onready var timer: Timer = $Timer
@onready var player = get_parent()

func _ready() -> void:
	initialize_weapon_stats()
	timer.timeout.connect(_on_timer_timeout)
	timer.start()

func initialize_weapon_stats() -> void:
	if weapon_type == WeaponType.KNIFE:
		fire_rate = 1.8
		shoot_range = 220.0
	else:
		fire_rate = 1.0
		shoot_range = 600.0
	update_timer()

func update_timer() -> void:
	var modifier = player.attack_frequency_modifier if is_instance_valid(player) and "attack_frequency_modifier" in player else 1.0
	timer.wait_time = 1.0 / (fire_rate * modifier)

func _on_timer_timeout() -> void:
	var target = _find_closest_enemy()
	if target:
		_shoot(target)

func _find_closest_enemy() -> CharacterBody2D:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var closest_enemy: CharacterBody2D = null
	var modifier = player.attack_range_modifier if is_instance_valid(player) and "attack_range_modifier" in player else 1.0
	var min_distance = shoot_range * modifier
	
	for enemy in enemies:
		if is_instance_valid(enemy):
			var dist = global_position.distance_to(enemy.global_position)
			if dist < min_distance:
				min_distance = dist
				closest_enemy = enemy
				
	return closest_enemy

func _shoot(target: CharacterBody2D) -> void:
	if not bullet_scene:
		return
	
	var bullet = bullet_scene.instantiate()
	bullet.global_position = global_position
	bullet.direction = global_position.direction_to(target.global_position)
	
	if weapon_type == WeaponType.KNIFE:
		bullet.speed = 0.0 # Melee doesn't travel forward
		bullet.damage = 18.0 * damage_multiplier
		bullet.lifetime = 0.15 # Fast slash swing duration
		bullet.is_melee = true
		# Offset the slash spawn position toward the target so it overlaps them
		bullet.global_position = global_position + bullet.direction * 110.0
		bullet.get_node("Sprite2D").texture = preload("res://kenney_tiny-dungeon/Tiles/tile_0105.png")
		bullet.get_node("Sprite2D").scale = Vector2(5, 5) # Large melee dagger
		# Scale up the collision shape to match the sweep area
		bullet.get_node("CollisionShape2D").scale = Vector2(4.5, 4.5)
		bullet.rotation = bullet.direction.angle() - 0.6 # Starting swing offset
	else:
		bullet.speed = 500.0 # Magic spark travels forward
		bullet.damage = 8.0 * damage_multiplier
		bullet.lifetime = 1.2 # Travels for 1.2s
		bullet.is_melee = false
		bullet.get_node("Sprite2D").texture = preload("res://kenney_tiny-dungeon/Tiles/tile_0116.png")
		bullet.get_node("Sprite2D").scale = Vector2(4, 4) # Magic potion drop/spark
		bullet.rotation = bullet.direction.angle()

	# Add the bullet to the world/root scene so it doesn't move with the player
	get_tree().current_scene.add_child(bullet)
