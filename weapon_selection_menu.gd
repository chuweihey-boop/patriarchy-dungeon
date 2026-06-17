extends CanvasLayer

@onready var knife_button: Button = $Panel/HBoxContainer/KnifeButton
@onready var wand_button: Button = $Panel/HBoxContainer/WandButton

func _ready() -> void:
	# Pause the game tree immediately during selection
	get_tree().paused = true
	
	# Connect buttons
	knife_button.pressed.connect(_on_knife_selected)
	wand_button.pressed.connect(_on_wand_selected)

func _on_knife_selected() -> void:
	_select_weapon(0) # 0 corresponds to WeaponType.KNIFE

func _on_wand_selected() -> void:
	_select_weapon(1) # 1 corresponds to WeaponType.WAND

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
