extends Orbiter

var anim_sprite: AnimatedSprite2D

var resource_pool_main: float = 0.0
var resource_pool_extractors: float = 0.0
var resource_pool_probes: float = 0.0

var area2d: Area2D

var selected: bool = false
var hover: bool = false
signal factory_hovered
signal factory_dehovered
signal factory_selected
signal factory_deselected

#THESE ARE KINDA MISNAMED, SHOULD BE UPDATE INSTEAD OF ADDED
signal added_resource_to_main
signal added_resource_to_next_extractor
signal added_resource_to_next_probe

signal created_extractor
signal created_probe


var making_extractors: bool = true
var making_probes: bool = true

func _init() -> void:
	anim_sprite = AnimatedSprite2D.new()
	anim_sprite.sprite_frames = load("res://Images/factory/factory.tres")

func _ready() -> void:
	anim_sprite.scale = Vector2.ONE * 10
	anim_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(anim_sprite)
	
	orbital_focus = Vector2.ZERO
	rotational_velocity = 0
	
	area2d = Area2D.new()
	var collisionShape = CollisionShape2D.new()
	collisionShape.shape = CircleShape2D.new()
	collisionShape.shape.radius = 200
	area2d.mouse_entered.connect(_on_hover)
	area2d.mouse_exited.connect(_on_exit)
	area2d.input_event.connect(handle_area2d_input)
	area2d.add_child(collisionShape)
	add_child(area2d)
	area2d.position = Vector2.ZERO
	
	

func update_factory() -> void:
	anim_sprite.look_at(Vector2.ZERO)

#RUNS ONCE PER Globals.factory_funding_interval SECONDS, CALLED FROM STAR
func update_queue() -> void:
	var num_projects = 0
	if making_extractors: num_projects += 1
	if making_probes: num_projects += 1
	
	if resource_pool_main < Globals.factory_funding_amount:
		return
		
	resource_pool_main -= Globals.factory_funding_amount
	added_resource_to_main.emit(resource_pool_main)
	var resource_per_project = Globals.factory_funding_amount / num_projects
	if making_extractors:
		resource_pool_extractors += resource_per_project
		if resource_pool_extractors >= Globals.resource_to_make_extractor:
			resource_pool_extractors -= Globals.resource_to_make_extractor
			resource_pool_main += resource_pool_extractors
			resource_pool_extractors = 0
			created_extractor.emit()
		added_resource_to_next_extractor.emit(resource_pool_extractors)
	if making_probes:
		resource_pool_probes += resource_per_project
		if resource_pool_probes > Globals.resource_to_make_probe:
			resource_pool_probes -= Globals.resource_to_make_probe
			resource_pool_main += resource_pool_probes
			resource_pool_probes = 0
			created_probe.emit()
		added_resource_to_next_probe.emit(resource_pool_probes)
		

func add_resource(pResource: float = 1) -> void:
	resource_pool_main += pResource
	if resource_pool_main > Globals.max_resource_stored_in_factory:
		resource_pool_main = Globals.max_resource_stored_in_factory
	added_resource_to_main.emit(resource_pool_main)
	
	anim_sprite.frame = int((resource_pool_main / float(Globals.max_resource_stored_in_factory)) * anim_sprite.sprite_frames.get_frame_count("default"))
	

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
