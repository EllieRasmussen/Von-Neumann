extends Orbiter
class_name Planet

var sprite: Sprite2D

var resource_multiplier: float = randf_range(0.25,1.75)

var area2D: Area2D

var spr_hovered: Sprite2D
var spr_selected: Sprite2D

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
signal extracted

func _ready() -> void:	
	#SET TEXTURE
	sprite = Sprite2D.new()
	sprite.texture = load("res://Images/planet" + str(randi_range(0,3)) + ".png")
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = Vector2.ONE * 25
	add_child(sprite)
	
	area2D = Area2D.new()
	var collisionShape = CollisionShape2D.new()
	collisionShape.shape = CircleShape2D.new()
	collisionShape.shape.radius = 200
	area2D.mouse_entered.connect(_on_hover)
	area2D.mouse_exited.connect(_exit_hover)
	area2D.input_event.connect(handle_area2d_input)
	area2D.add_child(collisionShape)
	add_child(area2D)
	
func update_extraction() -> void:
	if extractors > 0:
		extraction_timer += Globals.deltaTime
		if extraction_timer >= time_per_extraction:
			extraction_timer = 0.0
			extract_resource(1)
			
func update_extraction_deselected() -> void:
	if extractors > 0:
		extraction_timer += Globals.deltaTime
		if extraction_timer >= time_per_extraction:
			extraction_timer = 0.0
			extract_resource(1)
	


func add_extractors(pExtractors: int = 1) -> void:
	extractors += pExtractors
	queued_extractors -= pExtractors
	time_per_extraction = 10.0 / float(extractors)
	added_extractor.emit()

func extract_resource(pResource) -> void:
	extracted.emit(self, pResource * resource_multiplier)
	
func get_extraction_progress() -> float:
	return extraction_timer / time_per_extraction

func handle_area2d_input(_viewport: Node, event: InputEvent, _shape_idx: int):
	if event.is_action_pressed("Click"):
		if selected:
			deselect()
		else:
			select()
			
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
