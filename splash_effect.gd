extends Node2D

var radius: float = 120.0
var color: Color = Color(0.9, 0.2, 0.1, 0.25) # Semi-transparent red
var border_color: Color = Color(0.95, 0.3, 0.1, 0.6) # Brighter orange border
var current_radius: float = 0.0

func _ready() -> void:
	# Animate the radius from 0 to full, and fade out opacity
	var tween = create_tween().set_parallel(true)
	# Expand radius
	tween.tween_property(self, "current_radius", radius, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	# Fade out
	tween.tween_property(self, "modulate:a", 0.0, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	# Free when done
	tween.chain().tween_callback(queue_free)

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	# Draw filled circle
	draw_circle(Vector2.ZERO, current_radius, color)
	# Draw border outline using draw_arc
	draw_arc(Vector2.ZERO, current_radius, 0.0, TAU, 36, border_color, 2.5, true)
