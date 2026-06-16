extends CharacterBody2D

@export var speed: float = 100.0
@export var health: float = 3.0
@export var damage: float = 1.0

const GEM_SCENE = preload("res://experience_gem.tscn")

var player: CharacterBody2D = null

func _ready() -> void:
	# Add dynamically to enemies group
	add_to_group("enemies")
	# Find the player in the world scene dynamically
	player = get_tree().get_first_node_in_group("player")

func _physics_process(_delta: float) -> void:
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
