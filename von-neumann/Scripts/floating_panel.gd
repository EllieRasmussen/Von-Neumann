extends Node2D

class_name FloatingPanel

var delta_to_mouse: Vector2
var dragging: bool = false

@export var cam: Camera2D:
	set(new_cam):
		cam = new_cam
		cam.zoom_changed.connect(update_scale)

var target: Node2D

func _process(delta: float) -> void:
	if dragging:
		position = get_global_mouse_position() - delta_to_mouse
		
func update_scale() -> void:
	if dragging:
		return
	if cam.zoom.x < 0.015:
		scale = Vector2.ONE / 0.015
	else:
		scale = (Vector2.ONE / cam.zoom)

func _on_area_2d_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event.is_action_pressed("Click"):
		dragging = true
		delta_to_mouse = get_global_mouse_position() - position
	elif event.is_action_released("Click"):
		dragging = false
		update_scale()
		


signal closed
func _on_btn_close_button_down() -> void:
	closed.emit()
