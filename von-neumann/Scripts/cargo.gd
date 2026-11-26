extends Traveller
class_name Cargo

var type: int = 0:
	set(new_val):
		type = new_val
		if type == 0:
			sprite.modulate = Color(0,1,0)
		elif type == 1:
			sprite.modulate = Color(0,0,1)
		else:
			sprite.modulate = Color(1,0,0)
var amount: float = 0.0:
	set(new_val):
		amount = new_val
		sprite.scale *= amount

func _ready() -> void:
	sprite.texture = preload("res://Images/cargo_medium.png")
