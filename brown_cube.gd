extends Area2D

const SLOW_ZONE_SCENE = preload("res://slow_zone.tscn")

func _ready() -> void:
	# Connect overlap signal
	body_entered.connect(_on_body_entered)



func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		# Trigger landmine slow zone expansion!
		var zone = SLOW_ZONE_SCENE.instantiate()
		zone.global_position = global_position
		get_tree().current_scene.add_child(zone)
		
		# Self destruct
		queue_free()
