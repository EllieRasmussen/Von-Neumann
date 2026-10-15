extends Node2D
class_name Orbiter

var orbital_angle: float
var orbital_radius: float
var orbital_velocity: float
var orbital_offset: Vector2
var rotational_velocity: float

func _init() -> void:
	orbital_angle = randf_range(0.0,6.2831)
	rotational_velocity = 1.0

func update_position(delta: float) -> void:
	orbital_angle += orbital_velocity * delta
	if orbital_angle > 6.2832:
		orbital_angle -= 6.2832
	position = Vector2(
		cos(orbital_angle),
		sin(orbital_angle)
	) * orbital_radius + orbital_offset
	
	rotation += rotational_velocity * delta
	if rotation > 6.2832:
		rotation -= 6.2832

func set_orbital_radius(pRadius) -> void:
	orbital_radius = pRadius
	#orbital_offset = Vector2(
			#randf_range(-orbital_radius * 0.25, orbital_radius * 0.25),
			#randf_range(-orbital_radius * 0.25, orbital_radius * 0.25)
	#)
	orbital_offset = Vector2.ZERO
	orbital_velocity = randf_range((1.0/pRadius)*10,(1.0/pRadius)*100)
