extends Sprite2D

var orbital_radius: float
var orbital_position: float
var orbital_velocity: float

var resource = 0

var area2d: Area2D

var selected: bool = false
var hover: bool = false
signal factory_hovered
signal factory_dehovered
signal factory_selected
signal factory_deselected

signal added_resource
signal added_resource_to_new_extractor
signal update_new_extractor_progbar
signal update_new_probe_progbar

signal created_extractor
signal created_probe


var making_extractors: bool = false
var processing_new_extractor: bool = false
var next_extractor_timer: float

var making_probes: bool = false

func _ready() -> void:
	self.texture = load("res://Images/factory.png")
	scale = Vector2.ONE * 5
	
	orbital_position = randf_range(0,1)
	orbital_velocity = randf_range(0.00000000001,0.0000000001)
	
	area2d = Area2D.new()
	var collisionShape = CollisionShape2D.new()
	collisionShape.shape = CircleShape2D.new()
	collisionShape.shape.radius = 50
	area2d.mouse_entered.connect(_on_hover)
	area2d.mouse_exited.connect(_on_exit)
	area2d.input_event.connect(handle_area2d_input)
	area2d.add_child(collisionShape)
	add_child(area2d)
	area2d.position = Vector2.ZERO

func _process(delta: float) -> void:
	orbital_position += orbital_velocity * delta
	
	if making_extractors and resource >= Globals.resource_to_make_extractor and not processing_new_extractor:
		make_extractor()

func add_resource(pResource) -> void:
	resource += pResource
	added_resource.emit()
	if resource >= 1000:
		created_probe.emit()
		resource -= 1
		

func make_extractor() -> void:
	processing_new_extractor = true
	var resources_added: int = 0
	var time_per_resource: float = Globals.time_factory_make_extractor / Globals.resource_to_make_extractor
	while resources_added < Globals.resource_to_make_extractor:
		var timer = 0.0
		while timer < time_per_resource:
			timer += Globals.deltaTime
			update_new_extractor_progbar.emit(resources_added,(timer/time_per_resource))
			await get_tree().process_frame
		
		resources_added += 1
		resource -= 1
		added_resource_to_new_extractor.emit(resources_added,0)
	created_extractor.emit()
	added_resource_to_new_extractor.emit(0,0)
	processing_new_extractor = false

func handle_area2d_input(_viewport: Node, event: InputEvent, _shape_idx: int):
	if event.is_action_pressed("Click"):
		if selected:
			deselect()
		else:
			select()

#region HOVER, SELECT
func _on_hover() -> void:
	hover = true
	factory_hovered.emit()
	
func _on_exit() -> void:
	hover = false
	factory_dehovered.emit()
	
func select() -> void:
	selected = true
	factory_selected.emit()
	
func deselect() -> void:
	selected = false
	factory_deselected.emit()
	
func set_selected(pVal: bool) -> void:
	selected = pVal
#endregion
