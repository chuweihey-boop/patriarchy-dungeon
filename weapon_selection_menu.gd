extends CanvasLayer

@onready var eggbusket_button: Button = $Panel/HBoxContainer/EggbusketButton
@onready var negi_button: Button = $Panel/HBoxContainer/NegiButton
@onready var fishknife_button: Button = $Panel/HBoxContainer/FishknifeButton
@onready var woodensword_button: Button = $Panel/HBoxContainer/WoodenswordButton

func _ready() -> void:
	# Pause the game tree immediately during selection
	get_tree().paused = true
	
	# Connect buttons
	eggbusket_button.pressed.connect(func(): _select_weapon(0))
	negi_button.pressed.connect(func(): _select_weapon(1))
	fishknife_button.pressed.connect(func(): _select_weapon(2))
	woodensword_button.pressed.connect(func(): _select_weapon(3))

func _select_weapon(type_id: int) -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var weapon = player.get_node("Weapon")
		if weapon:
			weapon.weapon_type = type_id
			weapon.initialize_weapon_stats()
			print("Selected starting weapon type: %d" % type_id)
		else:
			print("Error: Player weapon node not found during selection!")
	else:
		print("Error: Player node not found during weapon selection!")
		
	# Unpause the game tree and close the menu
	get_tree().paused = false
	queue_free()
