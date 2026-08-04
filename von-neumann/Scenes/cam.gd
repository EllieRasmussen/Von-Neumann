extends Camera2D

var mouse_pos_last_frame
var mouse_pos
var dragging = false
var speed = 0.05

func _process(delta: float) -> void:
	mouse_pos_last_frame = mouse_pos
	mouse_pos = get_local_mouse_position()
	Input.is_action_just_pressed("Scroll Up")
	#if Input.is_action_just_pressed("Right Click"):
		#dragging = true
	#elif Input.is_action_just_released("Right Click"):
		#dragging = false

@export var min_zoom: Vector2
@export var max_zoom: Vector2
@export var zoom_interval: Vector2
func _input(event: InputEvent) -> void:
	##In a perfect world, funcs like _process would not exist. But this is not a perfect world. 
	if event.is_action_pressed("Right Click") and not dragging:
		dragging = true
	if event.is_action_released("Right Click") and dragging:
		dragging = false
		
	if event is InputEventMouseMotion and dragging:
		position -= mouse_pos - mouse_pos_last_frame
		
	if event.is_action_pressed("Scroll Up"):
		zoom += zoom_interval
		if zoom.x > max_zoom.x:
			zoom = max_zoom
			
	if event.is_action_pressed("Scroll Down"):
		zoom -= zoom_interval
		if zoom.x < min_zoom.x:
			zoom = min_zoom
		
