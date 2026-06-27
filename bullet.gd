extends Area2D

@export var speed: float = 600.0
@export var damage: float = 1.0
@export var lifetime: float = 3.0
@export var is_melee: bool = false
@export var splash_radius: float = 120.0
@export var max_splash_targets: int = 5

const SPLASH_EFFECT_SCRIPT = preload("res://splash_effect.gd")

var direction: Vector2 = Vector2.RIGHT

func _ready() -> void:
	collision_mask = 3
	# Connect the body_entered signal to detect when the bullet hits an enemy
	body_entered.connect(_on_body_entered)
	
	# Automatically destroy bullet after lifetime so we don't leak memory
	get_tree().create_timer(lifetime).timeout.connect(queue_free)
	
	if is_melee:
		# Swing animation: rotate and scale up, then shrink to zero
		var tween = create_tween().set_parallel(true)
		tween.tween_property(self, "rotation", rotation + 1.2, lifetime)
		tween.tween_property(self, "scale", scale * 1.4, lifetime * 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.chain().tween_property(self, "scale", Vector2.ZERO, lifetime * 0.5)

func _physics_process(delta: float) -> void:
	if speed > 0.0:
		global_position += direction * speed * delta

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("enemies"):
		if is_melee:
			if body.has_method("take_damage"):
				body.take_damage(damage)
		else:
			_apply_splash_damage()

func _apply_splash_damage() -> void:
	var explosion = Sprite2D.new()
	explosion.set_script(preload("res://effect_sprite.gd"))
	get_tree().current_scene.add_child(explosion)
	explosion.global_position = global_position
	var scale_factor = (2.0 * splash_radius) / 48.0
	explosion.scale = Vector2(scale_factor, scale_factor)
	explosion.setup(preload("res://art/effects/explosion/spritesheet.png"), "res://art/effects/explosion/spritesheet.txt", 25.0, false)
	
	# Find and damage all enemies in splash radius
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy.has_method("take_damage"):
			if global_position.distance_to(enemy.global_position) <= splash_radius:
				enemy.take_damage(damage)
			
	queue_free()
