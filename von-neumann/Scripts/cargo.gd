extends Sprite2D

const Factory = preload("res://Scripts/factory.gd")
const OffscreenFollower = preload("res://Scripts/offscreen_follower.gd")

var speed = 1000 #1000 feels actually good
var target_factory: Factory
var target_factory_follower: OffscreenFollower

func _ready() -> void:
	self.texture = preload("res://Images/cargo_medium.png")
	scale = Vector2.ONE * 10

func set_target_factory(pTarget: Factory, pFollower: PathFollow2D) -> void:
	target_factory = pTarget
	target_factory_follower = pFollower

func travel(delta: float) -> bool:
	var target_pos = get_target_position()
	var dir = (target_pos - position).normalized()
	position += dir * speed * delta
	return position.distance_squared_to(target_pos) < 2500

	
func get_target_position() -> Vector2:
	var angle = 6.283 * (target_factory_follower.get_real_progress())
	return Vector2(
		cos(angle) * target_factory.orbital_radius,
		sin(angle) * target_factory.orbital_radius
	)
	

func arrive() -> void:
	target_factory.add_resource(1)
