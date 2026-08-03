extends Sprite2D

var orbital_position: float
var orbital_radius: float
var orbital_velocity: float
var orbital_eccentricity: float

var rotational_velocity: float

var resource = randi_range(1000,10000)


var selected = false
var hover = false
var spr_selected
var spr_hover

signal planet_selected
signal planet_deselected

func _ready() -> void:
	#SET TEXTURE
	var planet_imgs = []
	planet_imgs.append(load("res://Images/planet0.png"))
	planet_imgs.append(load("res://Images/planet1.png"))
	planet_imgs.append(load("res://Images/planet2.png"))
	planet_imgs.append(load("res://Images/planet3.png"))
	self.texture = planet_imgs[randi()%len(planet_imgs)]
	
	spr_selected = Sprite2D.new()
	spr_selected.texture = load("res://Images/circle_selected.png")
	spr_selected.scale = Vector2.ONE * 7.5
	spr_selected.z_index = 1
	spr_selected.visible = false
	add_child(spr_selected)
	
	spr_hover = Sprite2D.new()
	spr_hover.texture = load("res://Images/circle_hover.png")
	spr_hover.scale = Vector2.ONE * 7.5
	spr_hover.z_index = 2
	spr_hover.visible = false
	add_child(spr_hover)
	
	orbital_position = randf_range(0,6.2832)
	rotational_velocity = randf_range(-0.005,0.05)

func _process(delta: float) -> void:
	orbital_position += orbital_velocity * delta
	
	if hover and not spr_hover.visible:
		spr_hover.visible = true
	elif not hover and spr_hover.visible:
		spr_hover.visible = false
	
	if selected and not spr_selected.visible:
		spr_selected.visible = true
	elif not selected and spr_selected.visible:
		spr_selected.visible = false
		
	if Input.is_action_just_pressed("Click") and hover:
		select()
		
	elif Input.is_action_just_pressed("Click") and selected:
		selected = false
		spr_selected.visible = false

func set_orbital_radius(pRadius) -> void:
	orbital_radius = pRadius
	orbital_velocity = randf_range((1.0/pRadius)*0.0005,(1.0/pRadius)*0.0025)

func extract_resource(pResource) -> void:
	resource -= pResource
	print("Extracted " + str(pResource) + " --- TOTAL: " + str(resource))

func on_hover():
	hover = true
	queue_redraw()
	
func exit_hover():
	hover = false
	queue_redraw()
	
func select():
	selected = true
	spr_selected.visible = true
	planet_selected.emit()
	
func deselect():
	selected = false
	spr_selected.visible = false
	planet_deselected.emit()
