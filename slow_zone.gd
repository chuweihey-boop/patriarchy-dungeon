extends Area2D

@export var radius: float = 75.0

var affected_player = null

func _ready() -> void:
	# Connect overlap signals
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Start fading out immediately over 5 seconds
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 5.0)
	tween.finished.connect(queue_free)



func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		affected_player = body
		if body.has_method("add_slow_zone"):
			body.add_slow_zone()

func _on_body_exited(body: Node) -> void:
	if body == affected_player:
		if is_instance_valid(affected_player) and affected_player.has_method("remove_slow_zone"):
			affected_player.remove_slow_zone()
		affected_player = null

func _exit_tree() -> void:
	# Safety check to clean up speed modifier on player if the zone vanishes
	if is_instance_valid(affected_player):
		if affected_player.has_method("remove_slow_zone"):
			affected_player.remove_slow_zone()
