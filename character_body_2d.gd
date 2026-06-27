extends CharacterBody2D

# Signals to notify HUD of changes
signal health_changed(current_health: float, max_health: float)
signal experience_changed(current_xp: int, xp_required: int)
signal level_up(new_level: int)
signal coins_changed(current_coins: int)

@export var speed: float = 300.0
@export var acceleration: float = 1200.0 # Rate of speed change (momentum)
@export var max_health: float = 100.0
@export var damage_cooldown: float = 0.5

var health: float = 100.0
var level: int = 1
var experience: int = 0
var experience_required: int = 10
var coins: int = 0

# Character Stats
var default_speed: float = 300.0
var attack_frequency_modifier: float = 1.0
var attack_range_modifier: float = 1.0
var near_field_damage_modifier: float = 1.0
var ranged_damage_modifier: float = 1.0
var regen_speed: float = 0.0
var shield: int = 0
var current_dir: String = "down"
var slow_zones_overlapping: int = 0

var damage_timer: float = 0.0
var damage_tween: Tween = null

@onready var hurtbox: Area2D = $Hurtbox
@onready var sprite: AnimatedSprite2D = $Sprite


func _ready() -> void:
	if hurtbox:
		hurtbox.collision_mask = 3
	health = max_health
	# Emit initial values
	health_changed.emit(health, max_health)
	experience_changed.emit(experience, experience_required)
	reposition_weapons()

func get_weapons() -> Array:
	var list = []
	for child in get_children():
		if "weapon_type" in child and "damage_multiplier" in child:
			list.append(child)
	return list

func reposition_weapons() -> void:
	var w_list = get_weapons()
	var offsets = [Vector2(-25, -25), Vector2(25, -25), Vector2(-25, 25), Vector2(25, 25)]
	for i in range(w_list.size()):
		if i < offsets.size():
			w_list[i].position = offsets[i]

func _physics_process(delta: float) -> void:
	# HP Regeneration over time
	if regen_speed > 0.0 and health < max_health:
		health = min(max_health, health + regen_speed * delta)
		health_changed.emit(health, max_health)

	# Move the character with momentum (acceleration/deceleration)
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var target_velocity = direction * speed
	velocity = velocity.move_toward(target_velocity, acceleration * delta)
	move_and_slide()

	# Play Walk / Idle Animations based on 8-directional input mapping to 6 animations
	if velocity != Vector2.ZERO:
		if velocity.y > 5.0: # Moving Downwards
			if velocity.x < -5.0:
				current_dir = "left_down"
			elif velocity.x > 5.0:
				current_dir = "right_down"
			else:
				current_dir = "down"
		elif velocity.y < -5.0: # Moving Upwards
			if velocity.x < -5.0:
				current_dir = "left_up"
			elif velocity.x > 5.0:
				current_dir = "right_up"
			else:
				current_dir = "up"
		else: # Moving horizontally only
			if velocity.x < 0:
				current_dir = "left_down" # Default pure Left to Left_Down
			elif velocity.x > 0:
				current_dir = "right_down" # Default pure Right to Right_Down

		var walk_anim = "walk_" + current_dir
		if sprite.animation != walk_anim:
			sprite.play(walk_anim)
	else:
		var idle_anim = "idle_" + current_dir
		if sprite.animation != idle_anim:
			sprite.play(idle_anim)


	# Check for enemy contact damage
	damage_timer += delta
	if damage_timer >= damage_cooldown:
		var overlapping_bodies = hurtbox.get_overlapping_bodies()
		for body in overlapping_bodies:
			if body.is_in_group("enemies"):
				take_damage(body.damage)
				_bounce_nearby_enemies(150.0)
				damage_timer = 0.0
				break

func _bounce_nearby_enemies(radius: float) -> void:
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy.has_method("bounce_back"):
			if global_position.distance_to(enemy.global_position) <= radius:
				enemy.bounce_back(global_position)

func take_damage(amount: float) -> void:
	# Shield reduces damage, minimum 1.0 damage taken
	var final_damage = max(1.0, amount - shield)
	health = max(0.0, health - final_damage)
	health_changed.emit(health, max_health)
	
	_spawn_damage_number(final_damage)
	
	if damage_tween and damage_tween.is_valid():
		damage_tween.kill()
	sprite.modulate = Color(1.0, 0.2, 0.2)
	damage_tween = create_tween()
	damage_tween.tween_property(sprite, "modulate", Color.WHITE, 0.3)
	
	if health <= 0:
		_die()

func _spawn_damage_number(amount: float) -> void:
	var label = Label.new()
	label.text = str(int(round(amount)))
	
	var font = preload("res://fonts/Xolonium-Regular.ttf")
	label.add_theme_font_override("font", font)
	
	var base_size = 18
	var font_size = int(clamp(base_size + amount * 1.5, base_size, 72))
	label.add_theme_font_size_override("font_size", font_size)
	
	label.add_theme_color_override("font_color", Color(0.75, 0.2, 0.95))
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 4)
	
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	label.grow_vertical = Control.GROW_DIRECTION_BOTH
	
	get_tree().current_scene.add_child(label)
	
	var offset = Vector2(randf_range(-15.0, 15.0), randf_range(-25.0, -10.0))
	label.global_position = global_position + offset
	
	var tween = label.create_tween().set_parallel(true)
	var target_pos = label.global_position + Vector2(randf_range(-10.0, 10.0), -50.0)
	tween.tween_property(label, "global_position", target_pos, 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(label.queue_free)

func heal(amount: float) -> void:
	if health < max_health:
		var recovered = min(max_health - health, amount)
		health = health + recovered
		health_changed.emit(health, max_health)
		_spawn_heal_number(recovered)

func _spawn_heal_number(amount: float) -> void:
	var label = Label.new()
	label.text = "+" + str(int(round(amount)))
	
	var font = preload("res://fonts/Xolonium-Regular.ttf")
	label.add_theme_font_override("font", font)
	
	var base_size = 18
	var font_size = int(clamp(base_size + amount * 1.5, base_size, 72))
	label.add_theme_font_size_override("font_size", font_size)
	
	label.add_theme_color_override("font_color", Color(0.2, 0.95, 0.3))
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 4)
	
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	label.grow_vertical = Control.GROW_DIRECTION_BOTH
	
	get_tree().current_scene.add_child(label)
	
	var offset = Vector2(randf_range(-15.0, 15.0), randf_range(-25.0, -10.0))
	label.global_position = global_position + offset
	
	var tween = label.create_tween().set_parallel(true)
	var target_pos = label.global_position + Vector2(randf_range(-10.0, 10.0), -50.0)
	tween.tween_property(label, "global_position", target_pos, 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(label.queue_free)

func gain_xp(amount: int) -> void:
	coins += amount
	coins_changed.emit(coins)
	experience += amount
	if experience >= experience_required:
		# Level up!
		experience -= experience_required
		level += 1
		experience_required = int(experience_required * 1.5) # Increase requirement for next level
		level_up.emit(level)
		
	experience_changed.emit(experience, experience_required)

func _die() -> void:
	print("Player Died!")
	get_tree().paused = true
	
	var canvas = CanvasLayer.new()
	canvas.process_mode = PROCESS_MODE_ALWAYS
	canvas.layer = 100
	get_tree().current_scene.add_child(canvas)
	
	var control = Control.new()
	control.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(control)
	
	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0, 0, 0, 0.6)
	control.add_child(bg)
	
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	control.add_child(center)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 30)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(vbox)
	
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(400, 140)
	vbox.add_child(spacer)
	
	var effect = Sprite2D.new()
	effect.set_script(preload("res://effect_sprite.gd"))
	spacer.add_child(effect)
	effect.position = Vector2(200, 70)
	effect.setup(preload("res://art/effects/gameover/symbol_game_over_text_001_large_red/spritesheet.png"), "res://art/effects/gameover/symbol_game_over_text_001_large_red/spritesheet.txt", 20.0, true)
	
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 25)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(hbox)
	
	var restart_btn = Button.new()
	restart_btn.text = "🔄 Restart"
	restart_btn.custom_minimum_size = Vector2(160, 55)
	restart_btn.add_theme_font_override("font", preload("res://fonts/Xolonium-Regular.ttf"))
	restart_btn.add_theme_font_size_override("font_size", 20)
	restart_btn.pressed.connect(func():
		get_tree().paused = false
		get_tree().reload_current_scene()
	)
	hbox.add_child(restart_btn)
	
	var exit_btn = Button.new()
	exit_btn.text = "🚪 Exit"
	exit_btn.custom_minimum_size = Vector2(160, 55)
	exit_btn.add_theme_font_override("font", preload("res://fonts/Xolonium-Regular.ttf"))
	exit_btn.add_theme_font_size_override("font_size", 20)
	exit_btn.pressed.connect(func():
		get_tree().quit()
	)
	hbox.add_child(exit_btn)
	
	restart_btn.grab_focus()

func add_slow_zone() -> void:
	slow_zones_overlapping += 1
	_update_speed()

func remove_slow_zone() -> void:
	slow_zones_overlapping = max(0, slow_zones_overlapping - 1)
	_update_speed()

func _update_speed() -> void:
	if slow_zones_overlapping > 0:
		speed = default_speed * 0.5
	else:
		speed = default_speed
