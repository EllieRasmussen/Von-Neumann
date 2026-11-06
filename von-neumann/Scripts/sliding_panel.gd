extends Node2D

@export var panel_containers: Array[PanelContainer]


@export var button_group: ButtonGroup

# 0 - left
# 1 - right
# 2 - top
# 3 - bottom
@export var dir = 0 
var open: bool = false
var pos_closed: Vector2
var pos_open: Vector2

func _ready() -> void:
	if dir == 0:
		pos_open = Vector2(0,position.y)
		pos_closed = Vector2(-panel_containers[0].size.x,position.y)
	elif dir == 1:
		pos_open = Vector2(get_viewport_rect().size.x-panel_containers[0].size.x,position.y)
		pos_closed = Vector2(get_viewport_rect().size.x,position.y)

func _open() -> void:
	var timer: float = 0
	var duration: float = 0.2
	while(timer < duration):
		timer += Globals.deltaTime
		if timer > duration: timer = duration
		position = pos_closed.lerp(pos_open,timer/duration)
		await Engine.get_main_loop().process_frame
	position = pos_open
	open = true
	
func _close() -> void:
	var timer: float = 0
	var duration: float = 0.2
	while(timer < duration):
		timer += Globals.deltaTime
		if timer > duration: timer = duration
		position = pos_open.lerp(pos_closed,timer/duration)
		await Engine.get_main_loop().process_frame
	position = pos_closed
	open = false
	
func set_active_panel(btn_index: int) -> void:
	# SINGLE-PANEL
	if button_group == null:
		if get_child(0).button_pressed:
			_open()
		else:
			_close()
		panel_containers[0].visible = true
		return
		
	# MULTI-PANEL
	var pressed_btn: TextureButton = button_group.get_pressed_button()
	if pressed_btn == null:
		_close()
	elif not open:
		_open()
	for p in panel_containers.size():
		panel_containers[p].visible = false
	panel_containers[btn_index].visible = true

func set_panel_selected(panel_index: int = 0, selected: bool = false) -> void:
	var panel_children: Array[Node] = panel_containers[panel_index].get_children()
	if selected:
		panel_children[0].visible = true
		panel_children[1].visible = false
	else:
		panel_children[0].visible = false
		panel_children[1].visible = true

func _on_btn_0_toggled(_toggled_on: bool) -> void:
	set_active_panel(0)


func _on_btn_1_toggled(_toggled_on: bool) -> void:
	set_active_panel(1)

func auto_button_press(btn_index: int, isPressed: bool) -> void:
	set_active_panel(btn_index)
	button_group.get_buttons()[btn_index].set_pressed(isPressed)
	set_panel_selected(btn_index,isPressed)
