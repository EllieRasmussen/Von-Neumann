extends Camera2D

var mouse_pos_last_frame: Vector2
var dragging = false

@export var subviewport: SubViewport

func _ready() -> void:
	mouse_pos_last_frame = subviewport.get_mouse_position()

##In a perfect world, funcs like _process would not exist. But this is not a perfect world. 
func _process(delta: float) -> void:
	if dragging:
		mouse_pos_last_frame = subviewport.get_mouse_position()

var min_zoom = 0.00001
var max_zoom = 1.5
@export var zoom_interval: Vector2
func _input(event: InputEvent) -> void:
	
	if event.is_action_pressed("Right Click") and not dragging:
		dragging = true
	if event.is_action_released("Right Click"):
		dragging = false
		
	if event is InputEventMouseMotion and dragging:
		#position -= mouse_pos - mouse_pos_last_frame
		position -= (event.position - mouse_pos_last_frame) / zoom
		
	if event.is_action_pressed("Scroll Up"):
		if zoom.x < max_zoom:
			zoom += zoom_interval
			
	if event.is_action_pressed("Scroll Down"):
		if zoom.x - zoom_interval.x >= min_zoom:
			zoom -= zoom_interval
		
