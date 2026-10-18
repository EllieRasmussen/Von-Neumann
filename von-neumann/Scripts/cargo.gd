extends Traveller

var resource: float = 0.0

func _ready() -> void:
	super()
	sprite.texture = preload("res://Images/cargo_medium.png")
