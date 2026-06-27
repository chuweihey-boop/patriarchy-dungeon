extends Area2D

const SLOW_ZONE_SCENE = preload("res://slow_zone.tscn")

func _ready() -> void:
	# Connect overlap signal
	body_entered.connect(_on_body_entered)
	
	# Vanish after 5s: sit for 4s, flash twice over 1s, then disappear
	var tween = create_tween()
	tween.tween_interval(4.0)
	tween.tween_property(self, "modulate:a", 0.2, 0.25)
	tween.tween_property(self, "modulate:a", 1.0, 0.25)
	tween.tween_property(self, "modulate:a", 0.2, 0.25)
	tween.tween_property(self, "modulate:a", 1.0, 0.25)
	tween.tween_callback(queue_free)



func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		# Trigger landmine slow zone expansion!
		var zone = SLOW_ZONE_SCENE.instantiate()
		zone.global_position = global_position
		get_tree().current_scene.add_child(zone)
		
		# Self destruct
		queue_free()
