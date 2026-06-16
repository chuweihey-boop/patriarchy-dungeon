extends Area2D

@export var speed: float = 600.0
@export var damage: float = 1.0

var direction: Vector2 = Vector2.RIGHT

func _ready() -> void:
	# Connect the body_entered signal to detect when the bullet hits an enemy
	body_entered.connect(_on_body_entered)
	
	# Automatically destroy bullet after 3 seconds so we don't leak memory
	get_tree().create_timer(3.0).timeout.connect(queue_free)

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("enemies"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		queue_free()
