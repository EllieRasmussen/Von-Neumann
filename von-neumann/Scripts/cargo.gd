extends Sprite2D

const Factory = preload("res://Scripts/factory.gd")

var speed = 1000 #1000 feels actually good
var target_factory: Factory

func _ready() -> void:
	self.texture = preload("res://Images/cargo_medium.png")
	scale = Vector2.ONE * 10

func set_target_factory(pTarget: Factory) -> void:
	target_factory = pTarget

func travel(delta: float) -> bool:
	var dir = (target_factory.position - position).normalized()
	position += dir * speed * delta
	return position.distance_squared_to(target_factory.position) < 2500

func arrive() -> void:
	target_factory.add_resource(1)
