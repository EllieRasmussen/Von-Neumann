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

var time_per_extraction: float = 1.0
var extraction_timer: float = 0.0
signal extracted

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
	
	
func _process(delta: float) -> void:
	if extractors > 0:
		extraction_timer += delta
		if extraction_timer >= time_per_extraction:
			extraction_timer = 0.0
			extract_resource(1)
			
func unselected_process(delta: float) -> void:
	if extractors > 0:
		extraction_timer += delta
		if extraction_timer >= time_per_extraction:
			extraction_timer = 0.0
			extract_resource(1)
	
func set_orbital_radius(pRadius) -> void:
	orbital_radius = pRadius
	orbital_velocity = randf_range((1.0/pRadius)*10,(1.0/pRadius)*100)

func  add_extractors(pExtractors) -> void:
	extractors += pExtractors
	time_per_extraction = 10.0 / float(extractors)

func extract_resource(pResource) -> void:
	extracted.emit()

func _on_hover():
	hover = true
	
func _exit_hover():
	hover = false
	
func select():
	selected = true
	
func deselect():
	selected = false
