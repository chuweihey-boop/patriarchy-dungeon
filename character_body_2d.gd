extends CharacterBody2D

# Signals to notify HUD of changes
signal health_changed(current_health: float, max_health: float)
signal experience_changed(current_xp: int, xp_required: int)
signal level_up(new_level: int)

@export var speed: float = 300.0
@export var max_health: float = 100.0
@export var damage_cooldown: float = 0.5

var health: float = 100.0
var level: int = 1
var experience: int = 0
var experience_required: int = 10

var damage_timer: float = 0.0

@onready var hurtbox: Area2D = $Hurtbox

func _ready() -> void:
	health = max_health
	# Emit initial values
	health_changed.emit(health, max_health)
	experience_changed.emit(experience, experience_required)

func _physics_process(delta: float) -> void:
	# Move the character
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if direction != Vector2.ZERO:
		velocity = direction * speed
	else:
		velocity = velocity.move_toward(Vector2.ZERO, speed)
	move_and_slide()

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
	health = max(0.0, health - amount)
	health_changed.emit(health, max_health)
	if health <= 0:
		_die()

func gain_xp(amount: int) -> void:
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
	# Reload current scene to restart
	get_tree().reload_current_scene()
