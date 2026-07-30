extends Sprite2D

var orbital_position: float
var orbital_radius: float
var orbital_velocity: float

var resource = 0

func _ready() -> void:
	self.texture = load("res://Images/factory.png")
	scale = Vector2.ONE * 0.05
	
	orbital_position = randf_range(0,6.2832)
	orbital_radius = 230
	orbital_velocity = randf_range(0.0000000001,0.00000001)
	print("FACTRY: " + str(orbital_velocity))

func _process(delta: float) -> void:
	orbital_position += orbital_velocity * delta
	

func add_resource(pResource) -> void:
	resource += pResource
	print("Added " + str(pResource) + " TOTAL: " + str(resource))
