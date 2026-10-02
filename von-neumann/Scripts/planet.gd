extends Sprite2D

var resource = randi_range(1000,10000)

var orbital_position: float
var orbital_radius: float
var orbital_velocity: float
var orbital_offset: Vector2

var selected = false
var hover = false

var extractors: int = 0
var max_extractors: int = 10

var time_per_extraction: float

func _ready() -> void:	
	#SET TEXTURE
	var planet_imgs = []
	planet_imgs.append(load("res://Images/planet0.png"))
	planet_imgs.append(load("res://Images/planet1.png"))
	planet_imgs.append(load("res://Images/planet2.png"))
	planet_imgs.append(load("res://Images/planet3.png"))
	self.texture = planet_imgs[randi()%len(planet_imgs)]
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	scale = Vector2.ONE * 10
	
	orbital_position = randf_range(0,1)
	
	
func set_orbital_radius(pRadius) -> void:
	orbital_radius = pRadius
	orbital_velocity = randf_range((1.0/pRadius)*10,(1.0/pRadius)*100)

func  add_extractors(pExtractors) -> void:
	extractors += pExtractors

func extract_resource(pResource) -> void:
	resource -= pResource
	print("Extracted " + str(pResource) + " --- TOTAL: " + str(resource))

func _on_hover():
	hover = true
	
func _exit_hover():
	hover = false
	
func select():
	selected = true
	
func deselect():
	selected = false
