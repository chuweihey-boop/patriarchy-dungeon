extends Node2D

enum WeaponType { EGGBUSKET, NEGI, FISHKNIFE, WOODENSWORD }

@export var bullet_scene: PackedScene = preload("res://bullet.tscn")
@export var weapon_type: WeaponType = WeaponType.EGGBUSKET
@export var damage_multiplier: float = 1.0
var level: int = 1

func get_weapon_name() -> String:
	match weapon_type:
		WeaponType.EGGBUSKET: return "🥚 Egg Basket"
		WeaponType.NEGI: return "葱 Negi"
		WeaponType.FISHKNIFE: return "🔪 Fish Knife"
		WeaponType.WOODENSWORD: return "🗡️ Wooden Sword"
	return "Weapon"

var fire_rate: float = 1.0 # Shots per second
var shoot_range: float = 600.0

@onready var timer: Timer = $Timer
@onready var player = get_parent()

func _ready() -> void:
	initialize_weapon_stats()
	timer.timeout.connect(_on_timer_timeout)
	timer.start()

func initialize_weapon_stats() -> void:
	match weapon_type:
		WeaponType.EGGBUSKET:
			fire_rate = 1.5
			shoot_range = 550.0
		WeaponType.NEGI:
			fire_rate = 2.0
			shoot_range = 220.0
		WeaponType.FISHKNIFE:
			fire_rate = 0.8
			shoot_range = 220.0
		WeaponType.WOODENSWORD:
			fire_rate = 3.5
			shoot_range = 220.0
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
	
	match weapon_type:
		WeaponType.EGGBUSKET:
			bullet.speed = 600.0
			var r_mod = player.ranged_damage_modifier if is_instance_valid(player) and "ranged_damage_modifier" in player else 1.0
			bullet.damage = 10.0 * damage_multiplier * r_mod
			bullet.lifetime = 1.2
			bullet.is_melee = false
			
			var atlas_tex = AtlasTexture.new()
			atlas_tex.atlas = preload("res://art/weapons/singleeggs.png")
			if randf() < 0.5:
				atlas_tex.region = Rect2(0, 0, 16, 32)
			else:
				atlas_tex.region = Rect2(16, 0, 16, 32)
				
			bullet.get_node("Sprite2D").texture = atlas_tex
			bullet.get_node("Sprite2D").scale = Vector2(2.5, 2.5)
			bullet.rotation = bullet.direction.angle()
			
		WeaponType.NEGI:
			bullet.speed = 0.0
			var n_mod = player.near_field_damage_modifier if is_instance_valid(player) and "near_field_damage_modifier" in player else 1.0
			bullet.damage = 14.0 * damage_multiplier * n_mod
			bullet.lifetime = 0.2
			bullet.is_melee = true
			bullet.global_position = global_position + bullet.direction * 80.0
			bullet.get_node("Sprite2D").texture = preload("res://art/weapons/negi.png")
			bullet.get_node("Sprite2D").scale = Vector2(2.5, 2.5)
			bullet.get_node("CollisionShape2D").scale = Vector2(2.8, 2.8)
			bullet.rotation = bullet.direction.angle() - 0.6
			_spawn_directional_impact(bullet.global_position, bullet.direction)
			
		WeaponType.FISHKNIFE:
			bullet.speed = 0.0
			var n_mod = player.near_field_damage_modifier if is_instance_valid(player) and "near_field_damage_modifier" in player else 1.0
			bullet.damage = 32.0 * damage_multiplier * n_mod
			bullet.lifetime = 0.3
			bullet.is_melee = true
			bullet.global_position = global_position + bullet.direction * 80.0
			bullet.get_node("Sprite2D").texture = preload("res://art/weapons/fishknife.png")
			bullet.get_node("Sprite2D").scale = Vector2(3.0, 3.0)
			bullet.get_node("CollisionShape2D").scale = Vector2(3.3, 3.3)
			bullet.rotation = bullet.direction.angle() - 0.6
			_spawn_directional_impact(bullet.global_position, bullet.direction)
			
		WeaponType.WOODENSWORD:
			bullet.speed = 0.0
			var n_mod = player.near_field_damage_modifier if is_instance_valid(player) and "near_field_damage_modifier" in player else 1.0
			bullet.damage = 8.0 * damage_multiplier * n_mod
			bullet.lifetime = 0.12
			bullet.is_melee = true
			bullet.global_position = global_position + bullet.direction * 80.0
			bullet.get_node("Sprite2D").texture = preload("res://art/weapons/woodensword.png")
			bullet.get_node("Sprite2D").scale = Vector2(2.2, 2.2)
			bullet.get_node("CollisionShape2D").scale = Vector2(2.5, 2.5)
			bullet.rotation = bullet.direction.angle() - 0.6
			_spawn_directional_impact(bullet.global_position, bullet.direction)

	# Add the bullet to the world/root scene so it doesn't move with the player
	get_tree().current_scene.add_child(bullet)

func _spawn_directional_impact(pos: Vector2, dir: Vector2) -> void:
	var effect = Sprite2D.new()
	effect.set_script(preload("res://effect_sprite.gd"))
	get_tree().current_scene.add_child(effect)
	effect.global_position = pos
	effect.rotation = dir.angle()
	effect.scale = Vector2(2.5, 2.5)
	effect.setup(preload("res://art/effects/directional_impact/spritesheet.png"), "res://art/effects/directional_impact/spritesheet.txt", 20.0, false)
