extends Sprite2D

const Planet = preload("res://Scripts/planet.gd")

var speed = 1000 #1000 feels actually good
var target_planet: Planet

func _ready() -> void:
	self.texture = preload("res://Images/extractor.png")
	scale = Vector2.ONE * 10
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	

func set_target_planet(pTarget: Planet) -> void:
	target_planet = pTarget
	
func travel(delta: float) -> bool:
	var dir = (target_planet.position - position).normalized()
	position += dir * speed * delta
	return position.distance_squared_to(target_planet.position) < 2500
	
func arrive() -> void:
	target_planet.add_extractors(1)
