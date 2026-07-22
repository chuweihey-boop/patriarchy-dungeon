extends CanvasLayer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS # keep running when paused
	
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	
	var panel = PanelContainer.new()
	center.add_child(panel)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 30)
	panel.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	margin.add_child(vbox)
	
	var lbl = Label.new()
	lbl.text = "PAUSED"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var label_settings = LabelSettings.new()
	label_settings.font_size = 32
	lbl.label_settings = label_settings
	vbox.add_child(lbl)
	
	vbox.add_child(HSeparator.new())
	
	var btn_resume = Button.new()
	btn_resume.text = "Resume"
	btn_resume.pressed.connect(_on_resume)
	vbox.add_child(btn_resume)
	
	var btn_restart = Button.new()
	btn_restart.text = "Restart"
	btn_restart.pressed.connect(_on_restart)
	vbox.add_child(btn_restart)
	
	var btn_exit = Button.new()
	btn_exit.text = "Exit Game"
	btn_exit.pressed.connect(_on_exit)
	vbox.add_child(btn_exit)

func _on_resume() -> void:
	get_tree().paused = false
	queue_free()

func _on_restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_exit() -> void:
	get_tree().quit()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.is_echo():
		if event.keycode == KEY_ESCAPE:
			get_viewport().set_input_as_handled()
			_on_resume()
