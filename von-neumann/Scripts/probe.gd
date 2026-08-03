extends Sprite2D

const Star = preload("res://Scripts/star.gd")

var speed = 10

func _ready():
	texture = load("res://Images/probe.png")
	scale = Vector2.ONE * 0.25
	
func travel(pFrom: Vector2, pTo: Star) -> void:
	var direction = (pTo.position - pFrom).normalized()
	var dist_to_target = global_position.distance_squared_to(pTo.position)
	while(dist_to_target > 25):
		position += direction * speed * get_process_delta_time()
		dist_to_target = global_position.distance_squared_to(pTo.position)
		print(dist_to_target)
		await Engine.get_main_loop().process_frame
		
	
