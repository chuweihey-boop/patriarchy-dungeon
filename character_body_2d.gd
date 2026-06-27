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
var regen_speed: float = 0.0
var shield: int = 0
var current_dir: String = "down"
var slow_zones_overlapping: int = 0

var damage_timer: float = 0.0

@onready var hurtbox: Area2D = $Hurtbox
@onready var sprite: AnimatedSprite2D = $Sprite


func _ready() -> void:
	health = max_health
	# Emit initial values
	health_changed.emit(health, max_health)
	experience_changed.emit(experience, experience_required)

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
				damage_timer = 0.0
				break

func take_damage(amount: float) -> void:
	# Shield reduces damage, minimum 1.0 damage taken
	var final_damage = max(1.0, amount - shield)
	health = max(0.0, health - final_damage)
	health_changed.emit(health, max_health)
	if health <= 0:
		_die()

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
	
	var effect = Sprite2D.new()
	effect.set_script(preload("res://effect_sprite.gd"))
	control.add_child(effect)
	effect.position = control.get_viewport_rect().size / 2.0
	effect.setup(preload("res://art/effects/gameover/symbol_game_over_text_001_large_red/spritesheet.png"), "res://art/effects/gameover/symbol_game_over_text_001_large_red/spritesheet.txt", 20.0, true)
	
	var timer = Timer.new()
	timer.wait_time = 3.0
	timer.one_shot = true
	canvas.add_child(timer)
	timer.timeout.connect(func():
		get_tree().paused = false
		get_tree().reload_current_scene()
	)
	timer.start()

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
