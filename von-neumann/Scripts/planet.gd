extends Orbiter

var sprite: Sprite2D

var resource: float = randf_range(0.25,1.75)

var area2D: Area2D

var selected = false
var hover = false

signal planet_hovered
signal planet_dehovered
signal planet_selected
signal planet_deselected

var extractors: int = 0
var max_extractors: int = 10

var time_per_extraction: float = 1.0
var extraction_timer: float = 0.0
signal extracted

func _ready() -> void:	
	#SET TEXTURE
	sprite = Sprite2D.new()
	sprite.texture = load("res://Images/planet" + str(randi_range(0,3)) + ".png")
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = Vector2.ONE * 10
	add_child(sprite)
	
	area2D = Area2D.new()
	var collisionShape = CollisionShape2D.new()
	collisionShape.shape = CircleShape2D.new()
	collisionShape.shape.radius = 100
	area2D.mouse_entered.connect(_on_hover)
	area2D.mouse_exited.connect(_exit_hover)
	area2D.input_event.connect(handle_area2d_input)
	area2D.add_child(collisionShape)
	add_child(area2D)
	
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
	


func  add_extractors(pExtractors: int = 1) -> void:
	extractors += pExtractors
	time_per_extraction = 10.0 / float(extractors)

func extract_resource(pResource) -> void:
	extracted.emit()
	
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
	planet_hovered.emit()
	
func _exit_hover():
	hover = false
	planet_dehovered.emit()
	
func select():
	selected = true
	planet_selected.emit()
	
func deselect():
	selected = false
	planet_deselected.emit()
	
func set_selected(pVal: bool) -> void:
	selected = pVal
#endregion
