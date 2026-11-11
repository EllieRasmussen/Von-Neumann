extends Camera2D

var mouse_pos_last_frame: Vector2
var dragging: bool = false
var centered_on_node: bool = false

@export var subviewport: SubViewport

func _ready() -> void:
	mouse_pos_last_frame = subviewport.get_mouse_position()

##In a perfect world, funcs like _process would not exist. But this is not a perfect world. 
func _process(_delta: float) -> void:
	if dragging:
		mouse_pos_last_frame = subviewport.get_mouse_position()

var min_zoom: float = 0.01
var max_zoom: float = 1.5
var zoom_interval: float = 0.005
signal zoom_changed
func _input(event: InputEvent) -> void:
	
	if event.is_action_pressed("Right Click") and not dragging:
		if centered_on_node:
			reparent(subviewport,true)
			centered_on_node = false
		dragging = true
		mouse_pos_last_frame = subviewport.get_mouse_position()
	if event.is_action_released("Right Click"):
		dragging = false
		
	if event is InputEventMouseMotion and dragging:
		#position -= mouse_pos - mouse_pos_last_frame
		position -= (event.position - mouse_pos_last_frame) / zoom
	
	var new_zoom: float = zoom.x
	if event.is_action_pressed("Scroll Up"):
		new_zoom += zoom_interval
	elif event.is_action_pressed("Scroll Down"):
		new_zoom -= zoom_interval
	new_zoom = clamp(new_zoom, min_zoom, max_zoom)
	zoom = Vector2(new_zoom,new_zoom)
	zoom_changed.emit()

func center(center_point: Vector2) -> void:
	position = center_point - offset
