extends Node2D
class_name Orbiter

var orbital_position: float # WHERE THE ORBITER CURRENTLY IS IN ITS ORBIT, RADIANS
var orbital_radius_0: float 
var orbital_radius_1: float
var orbital_angle: float # ANGLE FROM X AXIS TO RADIUS_0 AXIS
var orbital_velocity: float
var orbital_focus: Vector2 
var rotational_velocity: float

func _init() -> void:
	orbital_position = randf_range(0.0,6.2831)
	rotational_velocity = 1.0

func update_position(delta: float) -> void:
	orbital_position += orbital_velocity * delta
	if orbital_position > 6.2832:
		orbital_position -= 6.2832
	position = Vector2(
		orbital_radius_0 * cos(orbital_angle) * cos(orbital_position) - orbital_radius_1 * sin(orbital_angle) * sin(orbital_position),
		orbital_radius_0 * sin(orbital_angle) * cos(orbital_position) + orbital_radius_1 * cos(orbital_angle) * sin(orbital_position)
	) + orbital_focus
	orbital_velocity = (1000000/-position.length_squared())
	rotation += rotational_velocity * delta
	if rotation > 6.2832:
		rotation -= 6.2832

func set_orbit(pRadius0:float,pRadius1:float,pFocusDist:float,pOrbitalAngle:float) -> void:
	orbital_radius_0 = pRadius0
	orbital_radius_1 = pRadius1
	orbital_angle = pOrbitalAngle
	#orbital_offset = Vector2(
			#randf_range(-orbital_radius * 0.25, orbital_radius * 0.25),
			#randf_range(-orbital_radius * 0.25, orbital_radius * 0.25)
	#)
	orbital_focus = Vector2(
		cos(orbital_angle) * pFocusDist,
		sin(orbital_angle) * pFocusDist
	)
	orbital_velocity = randf_range((1.0/pRadius0)*10,(1.0/pRadius0)*100) * 100
