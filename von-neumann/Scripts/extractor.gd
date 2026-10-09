extends Sprite2D

const Planet = preload("res://Scripts/planet.gd")

var speed = 5000 #1000 feels actually good
var target_planet: Planet
var target_planet_follower: PathFollow2D

func _ready() -> void:
	self.texture = preload("res://Images/extractor.png")
	scale = Vector2.ONE
	

func set_target_planet(pTarget: Planet, pFollower: PathFollow2D) -> void:
	target_planet = pTarget
	target_planet_follower = pFollower
	
func travel(delta: float) -> bool:
	var target_pos = get_target_position()
	var dir = (target_pos - position).normalized()
	position += dir * speed * delta
	return position.distance_squared_to(target_pos) < 2500
	
func get_target_position() -> Vector2:
	var angle = 6.283 * target_planet_follower.progress_ratio
	var pos = Vector2(
		cos(angle) * target_planet.orbital_radius,
		sin(angle) * target_planet.orbital_radius
	)
	pos += target_planet.orbital_offset
	return pos
	

func arrive() -> void:
	target_planet.add_extractors(1)
