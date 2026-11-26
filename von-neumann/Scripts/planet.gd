extends Orbiter
class_name Planet

var sprite_frame: int = 0

var solids: float 
var liquids: float
var gasses: float

var spr_hovered: Sprite2D = null
var spr_selected: Sprite2D = null

var selected = false
var hover = false

signal planet_hovered
signal planet_dehovered
signal planet_selected
signal planet_deselected

var extractors: int = 0
var max_extractors: int = 10
var queued_extractors: int = 0
signal added_extractor

var time_per_extraction: float = 1.0
var extraction_timer: float = 0.0

func _init() -> void:
	sprite_frame = randi_range(0,29)
	scale = Vector2.ONE * randf_range(0.25,1.5)
	
	solids = randf_range(0.5,5.0)
	if solids < 0.6:
		solids = 0
	elif solids > 4.8:
		solids = 5
	
	liquids = randf_range(0.5,5.0)
	if liquids < 0.6:
		liquids = 0
	elif liquids > 4.8:
		liquids = 5
		
	gasses = randf_range(0.5,5.0)
	if gasses < 0.6:
		gasses = 0
	elif gasses > 4.8:
		gasses = 5

func update_extraction() -> void:
	if extractors > 0:
		extraction_timer += Globals.deltaTime
		if extraction_timer >= time_per_extraction:
			extraction_timer = 0.0
			drill_solids()
			drill_liquids()
			drill_gasses()
			
func update_extraction_deselected() -> void:
	if extractors > 0:
		extraction_timer += Globals.deltaTime
		if extraction_timer >= time_per_extraction:
			extraction_timer = 0.0
			drill_solids()
			drill_liquids()
			drill_gasses()
	

signal created_cargo
func drill_solids() -> void:
	var new_cargo = Cargo.new()
	new_cargo.type = 0
	new_cargo.amount = solids
	new_cargo.position = position
	created_cargo.emit(new_cargo)
	
func drill_liquids() -> void:
	var new_cargo = Cargo.new()
	new_cargo.type = 1
	new_cargo.amount = liquids
	new_cargo.position = position
	created_cargo.emit(new_cargo)
	
func drill_gasses() -> void:
	var new_cargo = Cargo.new()
	new_cargo.type = 2
	new_cargo.amount = gasses
	new_cargo.position = position
	created_cargo.emit(new_cargo)

func add_extractors(pExtractors: int = 1) -> void:
	extractors += pExtractors
	queued_extractors -= pExtractors
	time_per_extraction = 10.0 / float(extractors)
	added_extractor.emit()

func get_extraction_progress() -> float:
	return extraction_timer / time_per_extraction

#region HOVER, SELECT
func _on_hover():
	hover = true
	
	spr_hovered = Sprite2D.new()
	spr_hovered.texture = load("res://Images/circle_hover.png")
	spr_hovered.scale = Vector2.ONE * 50
	add_child(spr_hovered)
	
	planet_hovered.emit()
	
func _exit_hover():
	hover = false
	spr_hovered.queue_free()
	planet_dehovered.emit()
	
func select():
	selected = true
	
	spr_selected = Sprite2D.new()
	spr_selected.texture = load("res://Images/circle_selected0.png")
	spr_selected.scale  = Vector2.ONE * 50
	add_child(spr_selected)
	
	planet_selected.emit()
	
func deselect():
	selected = false
	spr_selected.queue_free()
	planet_deselected.emit()
	
func set_selected(pVal: bool) -> void:
	selected = pVal
#endregion
