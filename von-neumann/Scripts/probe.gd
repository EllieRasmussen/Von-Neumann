extends Sprite2D
class_name Probe

# 0: SCANNER PROBE
# 1: FACTORY PROBE
var probe_type: int = 0:
	set(new_val):
		probe_type = new_val
		if probe_type == 0:
			texture = load("res://Images/probe0.png")
		elif probe_type == 1:
			texture = load("res://Images/factory/Factory-1.png")

func _ready():
	scale = Vector2.ONE * 5
	
func travel(pFrom: Vector2, pTo: Star) -> void:
	var direction = (pTo.position - pFrom).normalized()
	look_at(position + direction)
	var dist_to_target = global_position.distance_squared_to(pTo.position)
	while(dist_to_target > 25):
		position += direction * Globals.probe_speed * get_process_delta_time()
		dist_to_target = global_position.distance_squared_to(pTo.position)
		await Engine.get_main_loop().process_frame
		
	arrive(pTo)
	self.queue_free()

func arrive(pStar: Star) -> void:
	#SCANNER PROBE:
	if probe_type == 0:
		if randf() < pStar.hostility * 2:
			pStar.scan()
	if randf() < pStar.hostility:
		if pStar.factory == null:
			pStar.create_factory()
		else:
			pStar.factory.add_resource(10)
