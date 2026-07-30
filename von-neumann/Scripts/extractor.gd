extends Sprite2D

var speed = 0.05
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
	while(dist_to_target > 100):
		progress += get_process_delta_time() * speed
		position = origin.lerp(pTarget.position, progress)
		dist_to_target = position.distance_squared_to(pTarget.position)
		if pTarget == null:
			dist_to_target = 0
		else:
			await get_tree().process_frame
	arrived.emit()
