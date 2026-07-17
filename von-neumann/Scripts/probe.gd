extends Sprite2D

var speed = 1
var direction: Vector2
var target

func _ready():
	texture = load("res://Images/probe.png")
	
func set_target(pTarget):
	target = pTarget
	direction = (target.position - position).normalized()

func process_travel(delta: float) -> bool:
	position += direction * speed * delta
	if position.distance_squared_to(target.position) < 100:
		return true
	else:
		return false
	
