extends Sprite2D

var resource = randi_range(1000,10000)

var orbital_position: float
var orbital_radius: float
var orbital_velocity: float
var orbital_offset: Vector2

var selected = false
var hover = false

var num_extractors = 0
var max_extractors = 10

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
	orbital_velocity = randf_range((1.0/pRadius)*0.05,(1.0/pRadius)*0.25)
	var r = orbital_radius * 0.5
	orbital_offset = Vector2(randf_range(-r,r),randf_range(-r,r))

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
