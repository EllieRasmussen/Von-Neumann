extends Sprite2D

const Star = preload("res://Scripts/star.gd")

var speed = 50

func _ready():
	texture = load("res://Images/probe0.png")
	scale = Vector2.ONE
	
func travel(pFrom: Vector2, pTo: Star) -> void:
	var direction = (pTo.position - pFrom).normalized()
	look_at(position + direction)
	var dist_to_target = global_position.distance_squared_to(pTo.position)
	while(dist_to_target > 25):
		position += direction * speed * get_process_delta_time()
		dist_to_target = global_position.distance_squared_to(pTo.position)
		await Engine.get_main_loop().process_frame
		
	arrive(pTo)
	self.queue_free()

func arrive(pStar: Star) -> void:
	if randf() < pStar.hostility:
		if pStar.factories.size() == 0:
			pStar.create_factory()
