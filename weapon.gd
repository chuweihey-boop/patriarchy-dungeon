extends Node2D

@export var bullet_scene: PackedScene = preload("res://bullet.tscn")
@export var fire_rate: float = 1.0 # Shots per second
@export var shoot_range: float = 600.0
@export var damage_multiplier: float = 1.0

@onready var timer: Timer = $Timer
@onready var player = get_parent()

func _ready() -> void:
	update_timer()
	timer.timeout.connect(_on_timer_timeout)
	timer.start()

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
	bullet.damage = bullet.damage * damage_multiplier
	
	# Rotate the bullet sprite to point towards the target
	bullet.rotation = bullet.direction.angle()
	
	# Add the bullet to the world/root scene so it doesn't move with the player
	get_tree().current_scene.add_child(bullet)
