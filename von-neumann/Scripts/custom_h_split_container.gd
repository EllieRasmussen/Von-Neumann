extends HSplitContainer



func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		print("mouse")
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			print("right click")
			grab_focus()
