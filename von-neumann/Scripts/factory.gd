extends Sprite2D

const ProgBar = preload("res://Scripts/prog_bar.gd")

var orbital_position: float
var orbital_radius: float
var orbital_velocity: float

var resource = 0
var resource_bar: ProgBar

signal created_probe

func _ready() -> void:
	self.texture = load("res://Images/factory.png")
	scale = Vector2.ONE * 0.05
	
	orbital_position = randf_range(0,6.2832)
	orbital_radius = 230
	orbital_velocity = randf_range(0.00000000001,0.0000000001)
	
	resource_bar = ProgBar.new()
	add_child(resource_bar)
	resource_bar.position = Vector2(-25,15)
	resource_bar.set_bar_width(5)
	resource_bar.set_bar_length(50)
	resource_bar.set_bg_color(Color.SLATE_GRAY)
	resource_bar.set_fg_color(Color.BLUE)

func _process(delta: float) -> void:
	orbital_position += orbital_velocity * delta
	

func add_resource(pResource) -> void:
	resource += pResource
	print("Added " + str(pResource) + " TOTAL: " + str(resource))
	if resource >=1:
		created_probe.emit()
		resource -= 1
		print("Created probe. " + "TOTAL: " + str(resource))
