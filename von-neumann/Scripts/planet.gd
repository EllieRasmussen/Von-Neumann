extends Sprite2D

var orbital_offset: float
var orbital_radius: float
var orbital_velocity: float
var orbital_eccentricity: float

var rotational_velocity: float


var selected = false
var hover = false

func _ready() -> void:
	scale = Vector2(0.05,0.05)
	
	#SET TEXTURE
	var planet_imgs = []
	planet_imgs.append(load("res://Images/planet0.png"))
	planet_imgs.append(load("res://Images/planet1.png"))
	planet_imgs.append(load("res://Images/planet2.png"))
	planet_imgs.append(load("res://Images/planet3.png"))
	self.texture = planet_imgs[randi()%len(planet_imgs)]
	
	orbital_radius = randf_range(50,350)
	orbital_offset = randf_range(0,6.2832)
	orbital_velocity = randf_range(0.00001,0.001)
	rotational_velocity = randf_range(-0.005,0.05)

func _process(delta: float) -> void:
	orbital_offset += orbital_velocity
	
func _draw() -> void:
	if hover:
		draw_circle(position, 60, Color.GREEN, false)


func on_hover():
	hover = true
	queue_redraw()
	
func exit_hover():
	hover = false
	queue_redraw()
