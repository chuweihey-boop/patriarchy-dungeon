extends Area2D
class_name HeartPickup

@export var heal_amount: float = 5.0
@export var magnet_speed: float = 300.0

var player: CharacterBody2D = null
var is_being_collected: bool = false

func _ready() -> void:
	var sprite = Sprite2D.new()
	sprite.texture = preload("res://art/glossy_heart.png")
	sprite.scale = Vector2(2.0, 2.0)
	add_child(sprite)
	
	var col = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 20.0
	col.shape = circle
	add_child(col)
	
	player = get_tree().get_first_node_in_group("player")
	body_entered.connect(_on_body_entered)
	
	var tween = create_tween().set_loops()
	tween.tween_property(sprite, "position:y", -6.0, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(sprite, "position:y", 6.0, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player):
		return
		
	var dist = global_position.distance_to(player.global_position)
	if dist < 150.0:
		is_being_collected = true
		
	if is_being_collected:
		global_position = global_position.move_toward(player.global_position, magnet_speed * delta)
		magnet_speed += 15.0

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		if body.has_method("heal"):
			body.heal(heal_amount)
		queue_free()
