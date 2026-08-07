extends Camera2D

var mouse_pos_last_frame: Vector2
var dragging = false
var speed = 0.005

@export var subviewport: SubViewport

func _ready() -> void:
	mouse_pos_last_frame = subviewport.get_mouse_position()

##In a perfect world, funcs like _process would not exist. But this is not a perfect world. 
func _process(delta: float) -> void:
	if dragging:
		mouse_pos_last_frame = subviewport.get_mouse_position()

@export var min_zoom: Vector2
@export var max_zoom: Vector2
@export var zoom_interval: Vector2
func _input(event: InputEvent) -> void:
	
	if event.is_action_pressed("Right Click") and not dragging:
		dragging = true
	if event.is_action_released("Right Click"):
		dragging = false
		
	if event is InputEventMouseMotion and dragging:
		#position -= mouse_pos - mouse_pos_last_frame
		position -= event.position - mouse_pos_last_frame
		print(event)
		
	if event.is_action_pressed("Scroll Up"):
		zoom += zoom_interval
		if zoom.x > max_zoom.x:
			zoom = max_zoom
			
	if event.is_action_pressed("Scroll Down"):
		zoom -= zoom_interval
		if zoom.x < min_zoom.x:
			zoom = min_zoom
		
