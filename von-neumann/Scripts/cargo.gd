extends Sprite2D

const Factory = preload("res://Scripts/factory.gd")

var speed = 1000 #1000 feels actually good
var target_factory: Factory
var target_factory_follower: PathFollow2D

func _ready() -> void:
	self.texture = preload("res://Images/cargo_medium.png")
	scale = Vector2.ONE * 10

func set_target_factory(pTarget: Factory, pFollower: PathFollow2D) -> void:
	target_factory = pTarget
	target_factory_follower = pFollower

func travel(delta: float, banked_progress: float) -> bool:
	var target_pos = get_target_position(banked_progress)
	var dir = (target_pos - position).normalized()
	position += dir * speed * delta
	return position.distance_squared_to(target_pos) < 2500

	
func get_target_position(banked_progress: float) -> Vector2:
	var angle = 6.283 * (target_factory_follower.progress_ratio + banked_progress)
	var pos = Vector2(
		cos(angle) * target_factory.orbital_radius,
		sin(angle) * target_factory.orbital_radius
	)
	return pos
	

func arrive() -> void:
	target_factory.add_resource(1)
