extends Sprite2D

var speed = 0.1
var resource = 0

signal arrived

func _ready() -> void:
	self.texture = preload("res://Images/extractor.png")
	scale = Vector2.ONE * 0.25
	position = Vector2(256,256)
	
	
func go_to(pTarget: Node2D) -> void:
	var progress = 0
	var origin = Vector2(position.x,position.y)
	var dist_to_target = position.distance_squared_to(pTarget.position)
	while(dist_to_target > 50):
		progress += get_process_delta_time() * speed
		position = origin.lerp(pTarget.position, progress)
		dist_to_target = position.distance_squared_to(pTarget.position)
		await Engine.get_main_loop().process_frame
			
	arrived.emit()

func stick_to(pTarget: Node2D, pDuration: float) -> void:
	var timer = 0
	while timer <= pDuration:
		timer += get_process_delta_time()
		position = pTarget.position
		await Engine.get_main_loop().process_frame
	
