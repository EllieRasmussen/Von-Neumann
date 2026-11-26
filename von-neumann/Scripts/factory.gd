extends Orbiter
class_name Factory

var anim_sprite: AnimatedSprite2D

signal fund_solids_changed
signal pool_solids_changed
var pool_solids: float = 0.0:
	set(new_val):
		pool_solids = new_val
		pool_solids_changed.emit()

signal fund_liquids_changed
signal pool_liquids_changed
var pool_liquids: float = 0.0:
	set(new_val):
		pool_liquids = new_val
		pool_liquids_changed.emit()

signal fund_gasses_changed
signal pool_gasses_changed
var pool_gasses: float = 0.0:
	set(new_val):
		pool_gasses = new_val
		pool_gasses_changed.emit()

var active_buildables: Dictionary[int,Vector3]

var area2d: Area2D

var selected: bool = false
var hover: bool = false
signal factory_hovered
signal factory_dehovered
signal factory_selected
signal factory_deselected

signal created_extractor
signal created_scanner
signal created_factory




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
	

func set_buildable_active(pType: int) -> void:
	if active_buildables.has(pType):
		return
	active_buildables.set(pType,Vector3.ZERO)
	var num_using_solids: int = get_num_buildables_needing(0)
	var num_using_liquids: int = get_num_buildables_needing(1)
	var num_using_gasses: int = get_num_buildables_needing(2)
	if num_using_solids > 0 and pool_solids >= Globals.factory_funding_amount and not funding_solids:
		fund_solids(num_using_solids)
	if num_using_liquids > 0 and pool_liquids >= Globals.factory_funding_amount and not funding_liquids:
		fund_liquids(num_using_liquids)
	if num_using_gasses > 0 and pool_gasses >= Globals.factory_funding_amount and not funding_gasses:
		fund_gasses(num_using_gasses)
	
func remove_buildable_active(pType: int) -> void:
	if not active_buildables.has(pType):
		return
	active_buildables.erase(pType)


func get_num_buildables_needing(pResourceType: int) -> int:
	var num_buildables: int = 0
	for type in active_buildables.keys():
		if Globals.build_costs[type][pResourceType] > 0 and active_buildables[type][pResourceType] < Globals.build_costs[type][pResourceType]:
			num_buildables += 1
	return num_buildables

var funding_solids: bool = false
signal funded_solids
func fund_solids(num_projects: int) -> void:
	funding_solids = true
	
	while(funding_solids):
		var timer: float = 0
		while(timer < Globals.factory_funding_interval):
			timer += Globals.deltaTime
			fund_solids_changed.emit(timer)
			await Engine.get_main_loop().process_frame
		fund_solids_changed.emit(0)
		
		var resource_per_project: float = Globals.factory_funding_amount / num_projects
		pool_solids -= Globals.factory_funding_amount
		for type in active_buildables.keys():
			if Globals.build_costs[type][0] > 0:
				active_buildables[type][0] += resource_per_project
				try_build(type)
		funded_solids.emit(resource_per_project)
		funding_solids = pool_solids >= Globals.factory_funding_amount and get_num_buildables_needing(0) > 0


var funding_liquids: bool = false
signal funded_liquids
func fund_liquids(num_projects: int) -> void:
	funding_liquids = true
	
	while(funding_liquids):
		var timer: float = 0
		while(timer < Globals.factory_funding_interval):
			timer += Globals.deltaTime
			fund_liquids_changed.emit(timer)
			await Engine.get_main_loop().process_frame
		fund_liquids_changed.emit(0)
		
		var resource_per_project: float = Globals.factory_funding_amount / num_projects
		pool_liquids -= Globals.factory_funding_amount
		for type in active_buildables.keys():
			if Globals.build_costs[type][1] > 0:
				active_buildables[type][1] += resource_per_project
				try_build(type)
		funded_liquids.emit(resource_per_project)
		funding_liquids = pool_liquids >= Globals.factory_funding_amount and get_num_buildables_needing(1) > 0

var funding_gasses: bool = false
signal funded_gasses
func fund_gasses(num_projects: int) -> void:
	funding_gasses = true
	while(funding_gasses):
		var timer: float = 0
		while(timer < Globals.factory_funding_interval):
			timer += Globals.deltaTime
			fund_gasses_changed.emit(timer)
			await Engine.get_main_loop().process_frame
		fund_gasses_changed.emit(0)
		
		var resource_per_project: float = Globals.factory_funding_amount / num_projects
		pool_gasses -= Globals.factory_funding_amount
		for type in active_buildables.keys():
			if Globals.build_costs[type][2] > 0:
				active_buildables[type][2] += resource_per_project
				try_build(type)
		funded_gasses.emit(resource_per_project)
		funding_gasses = pool_gasses >= Globals.factory_funding_amount and get_num_buildables_needing(2) > 0

func try_build(pBuildableType: int) -> void:
	if not active_buildables.has(pBuildableType):
		return
	if active_buildables[pBuildableType][0] >= Globals.build_costs[pBuildableType][0] and active_buildables[pBuildableType][1] >= Globals.build_costs[pBuildableType][1] and active_buildables[pBuildableType][2] >= Globals.build_costs[pBuildableType][2]:
		active_buildables[pBuildableType] -= Globals.build_costs[pBuildableType]
		pool_solids += active_buildables[pBuildableType][0]
		pool_liquids += active_buildables[pBuildableType][1]
		pool_gasses += active_buildables[pBuildableType][2]
		active_buildables[pBuildableType] = Vector3.ZERO
		
		if pBuildableType == 0:
			created_extractor.emit()
			print("Created Drill!")
		elif pBuildableType == 1:
			created_scanner.emit()
			print("Created Scanner!")
		elif pBuildableType == 2:
			created_factory.emit()
			print("Created Factory!")

func receive_cargo(pCargo: Cargo) -> void:
	var num_buildables_using_type: int = get_num_buildables_needing(pCargo.type)
	if pCargo.type == 0:
		pool_solids += pCargo.amount
		if pool_solids >= Globals.max_solids:
			pool_solids = Globals.max_solids
		
		if pool_solids >= Globals.factory_funding_amount and not funding_solids and num_buildables_using_type > 0:
			fund_solids(num_buildables_using_type)
			
	elif pCargo.type == 1:
		pool_liquids += pCargo.amount
		if pool_liquids >= Globals.max_liquids:
			pool_liquids = Globals.max_liquids
			
		if pool_liquids >= Globals.factory_funding_amount and not funding_liquids and num_buildables_using_type > 0:
			fund_liquids(num_buildables_using_type)
	
	else:
		pool_gasses += pCargo.amount
		if pool_gasses >= Globals.max_gasses:
			pool_gasses = Globals.max_gasses
		
		if pool_gasses >= Globals.factory_funding_amount and not funding_gasses and num_buildables_using_type > 0:
			fund_gasses(num_buildables_using_type)

func handle_area2d_input(_viewport: Node, event: InputEvent, _shape_idx: int):
	if event.is_action_pressed("Click"):
		if selected:
			deselect()
		else:
			select()

#region HOVER, SELECT
var spr_hover = null
func _on_hover() -> void:
	hover = true
	
	spr_hover = Sprite2D.new()
	spr_hover.texture = load("res://Images/circle_hover.png")
	spr_hover.scale = Vector2.ONE * 10
	add_child(spr_hover)
	
	factory_hovered.emit()
	
func _on_exit() -> void:
	hover = false
	spr_hover.queue_free()
	factory_dehovered.emit()
	
var spr_selected = null
func select() -> void:
	selected = true
	
	spr_selected = Sprite2D.new()
	spr_selected.texture = load("res://Images/circle_selected0.png")
	spr_selected.scale  = Vector2.ONE * 10
	add_child(spr_selected)
	
	factory_selected.emit()
	
func deselect() -> void:
	selected = false
	spr_selected.queue_free()
	factory_deselected.emit()
	
func set_selected(pVal: bool) -> void:
	selected = pVal
#endregion
