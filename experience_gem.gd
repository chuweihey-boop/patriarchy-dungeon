extends Area2D

@export var xp_value: int = 1
@export var magnet_speed: float = 300.0

var player: CharacterBody2D = null
var is_being_collected: bool = false

func _ready() -> void:
	# Find the player in group "player"
	player = get_tree().get_first_node_in_group("player")
	
	# Connect overlap signal
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	if not player:
		return
		
	var dist = global_position.distance_to(player.global_position)
	# Magnet distance threshold (e.g. 150 pixels)
	if dist < 150.0:
		is_being_collected = true
		
	if is_being_collected:
		# Move towards the player
		global_position = global_position.move_toward(player.global_position, magnet_speed * delta)
		# Accelerate magnet speed to feel juicy
		magnet_speed += 15.0

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		if body.has_method("gain_xp"):
			body.gain_xp(xp_value)
		queue_free()
