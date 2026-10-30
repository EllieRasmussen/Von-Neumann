extends Node2D

@export var panel_container: PanelContainer
@export var button_close: TextureButton
@export var button_open: TextureButton

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
		pos_closed = Vector2(-panel_container.size.x,position.y)
	elif dir == 1:
		pos_open = Vector2(get_viewport_rect().size.x-panel_container.size.x,position.y)
		pos_closed = Vector2(get_viewport_rect().size.x,position.y)

func update_btn() -> void:
	if open:
		button_close.visible = true
		button_open.visible = false
	else:
		button_close.visible = false
		button_open.visible = true

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
	update_btn()
	
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
	update_btn()

func _on_button_open_button_down() -> void:
	_open()

func _on_button_close_button_down() -> void:
	_close()
