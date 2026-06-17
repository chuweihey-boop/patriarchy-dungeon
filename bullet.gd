extends Area2D

@export var speed: float = 600.0
@export var damage: float = 1.0
@export var lifetime: float = 3.0
@export var is_melee: bool = false

var direction: Vector2 = Vector2.RIGHT

func _ready() -> void:
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
		if body.has_method("take_damage"):
			body.take_damage(damage)
		if not is_melee:
			queue_free()
