extends Orbiter

var anim_sprite: AnimatedSprite2D

var resource = 0

var area2d: Area2D

var selected: bool = false
var hover: bool = false
signal factory_hovered
signal factory_dehovered
signal factory_selected
signal factory_deselected

signal added_resource
signal update_new_extractor_progress
signal update_new_probe_progbar

signal created_extractor
signal created_probe


var making_extractors: bool = false
var processing_new_extractor: bool = false
var next_extractor_timer: float

var making_probes: bool = false

func _ready() -> void:
	anim_sprite = AnimatedSprite2D.new()
	anim_sprite.sprite_frames = load("res://Images/factory/factory.tres")
	anim_sprite.scale = Vector2.ONE * 10
	anim_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(anim_sprite)
	
	orbital_offset = Vector2.ZERO
	rotational_velocity = 0
	
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
	anim_sprite.look_at(Vector2.ZERO)
	if making_extractors and resource >= Globals.resource_to_make_extractor and not processing_new_extractor:
		make_extractor()

func add_resource(pResource: int = 1) -> void:
	
	resource += pResource
	added_resource.emit()
	
	anim_sprite.frame = int((resource / float(Globals.max_resource_stored_in_factory)) * anim_sprite.sprite_frames.get_frame_count("default"))
	
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
			update_new_extractor_progress.emit(resources_added,(timer/time_per_resource))
			await get_tree().process_frame
		
		resources_added += 1
		resource -= 1
		update_new_extractor_progress.emit(resources_added,0)
	created_extractor.emit()
	update_new_extractor_progress.emit(0,0)
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
