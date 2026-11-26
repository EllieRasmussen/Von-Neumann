extends AnimatedSprite2D
class_name Star

const Extractor = preload("res://Scripts/extractor.gd")

var hostility: float

var viewport_planets: SubViewport

var planets: Array[Planet]
var factory: Factory
var extractors: Array[Extractor]
var cargo: Array[Cargo]

signal star_hovered
signal star_dehovered
signal star_selected
signal star_deselected

var selected = false
var hover = false

var scanned: bool = false

var active = false
var spr_active: Sprite2D

var hostility_label: Label
func _init() -> void:
	hostility = randf_range(0.1,0.5)
	hostility_label = Label.new()
	hostility_label.visible = false
	hostility_label.text = str("%.2f" % hostility)
	add_child(hostility_label)
	hostility_label.position = Vector2(-10,30)
	
	#SET TEXTURE
	sprite_frames = load("res://Images/star viewer/star_sprites.tres")
	frame = 0
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	scale = Vector2.ONE * 5
	
	create_planets(Globals.max_planets_per_star,0.5)
	
	spr_active = Sprite2D.new()
	spr_active.texture = load("res://Images/star_active.png")
	set_active(false)
	add_child(spr_active)


var has_valid_planet: bool = true
func _process(delta: float) -> void:
	for p in planets.size():
		planets[p].update_position(delta)
		planets[p].update_extraction()
	if factory != null:
		factory.update_position(delta)
		factory.update_factory()

func create_planets(max_planets: int, planet_spawn_chance: float) -> void:
	for p in max_planets:
		if randf() < planet_spawn_chance:
			#PLANET
			var new_planet = Planet.new()
			new_planet.planet_selected.connect(set_planet_selected.bind(new_planet,true))
			new_planet.planet_deselected.connect(set_planet_selected.bind(new_planet,false))
			new_planet.created_cargo.connect(add_cargo)
			
			var r0 = (p+2) * 6000
			var r1 = randf_range(0.65,1.0) * (p+2) * 6000
			var orbit_angle = randf() * 6.2832
			var focus_distance = sqrt(abs((r0*r0)-(r1*r1)))
			new_planet.set_orbit(r0,r1,focus_distance,orbit_angle)
			
			planets.append(new_planet)
		
		
		
		
		

func add_cargo(pCargo: Cargo) -> void:
	if factory != null:
		pCargo.set_target(factory)
		pCargo.arrived.connect(factory.receive_cargo.bind(pCargo))
		pCargo.arrived.connect(remove_cargo.bind(pCargo))
		cargo.append(pCargo)
	
	if selected:
		viewport_planets.add_child(pCargo)

func remove_cargo(pCargo: Cargo) -> void:
	cargo.erase(pCargo)
	pCargo.queue_free()



func find_planet_with_room_for_extractor() -> Planet:
	for p in planets.size():
		if planets[p].extractors + planets[p].queued_extractors < Globals.max_extractors_per_planet:
			return planets[p]
	return null



var game_manager #TODO KILL KILL KILL KILL THIS IT MUST DIE BEFORE RELEASE KILL
func get_adjacent_stars() -> Array[Star]:
	var arr: Array[Star] = []
	for s in game_manager.stars.size():
		var dist_to_star: Vector2 = game_manager.stars[s].position - position
		if dist_to_star.length_squared() <= Globals.star_adjacency_max * Globals.star_adjacency_max and game_manager.stars[s] != self:
			arr.append(game_manager.stars[s])
	return arr

func create_scanner() -> void:
	var adj = get_adjacent_stars()
	var closest: Star = null
	var min_dist: float = Globals.scanner_probe_travel_dist
	for a in adj.size():
		if adj[a].factory == null:
			var dist_between: float = (adj[a].position - position).length_squared()
			if dist_between < min_dist:
				min_dist = dist_between
				closest = adj[a]
			
	
	if closest != null:
		var new_probe = Probe.new()
		new_probe.probe_type = 0
		new_probe.travel(position, closest)
		add_child(new_probe)

func create_factory() -> void:
	set_active(true)
	
	factory = Factory.new()
	factory.created_extractor.connect(create_extractor)
	factory.created_scanner.connect(create_scanner)
	factory.set_orbit(Globals.factory_orbital_radius,Globals.factory_orbital_radius,
						Globals.factory_orbital_focus_dist,
						0)
	factory.pool_solids = Globals.starting_resource_in_factroy
	factory.pool_liquids = Globals.starting_resource_in_factroy
	factory.pool_gasses = Globals.starting_resource_in_factroy
	
	if selected:
		viewport_planets.add_child(factory)
	

func create_extractor() -> void:
	var target: Planet = find_planet_with_room_for_extractor()
	if target == null:
		has_valid_planet = false
		return
	target.queued_extractors += 1
	var new_extractor = Extractor.new()
	new_extractor.position = factory.position
	new_extractor.arrived.connect(target.add_extractors)
	new_extractor.arrived.connect(remove_extractor.bind(new_extractor))
	new_extractor.set_target(target)
	
	extractors.append(new_extractor)
	if selected:
		viewport_planets.add_child(new_extractor)
	

func remove_extractor(pExtractor: Extractor) -> void:
	extractors.erase(pExtractor)
	pExtractor.queue_free()





#region HOVER, SELECTION, ACTIVE
func _on_hover(): 
	if selected:
		return
	
	if scanned:
		frame = 3
	else:
		frame = 1
	hover = true
	star_hovered.emit()
	
func _exit_hover():
	if selected: 
		return
	
	if scanned: 
		frame = 2
	else:
		frame = 0
	hover = false
	star_dehovered.emit()

func select():
	#if not scanned:
		#return
	
	selected = true
	frame = 4
	star_selected.emit()
	
	if factory != null:
		viewport_planets.add_child(factory)
	for p in planets.size():
		viewport_planets.add_child(planets[p])		
	for e in extractors.size():
		viewport_planets.add_child(extractors[e])
	for c in cargo.size():
		viewport_planets.add_child(cargo[c])

func deselect():
	selected = false
	frame = 2
	star_deselected.emit()
	
	if factory != null:
		viewport_planets.remove_child(factory)
	for p in planets.size():
		viewport_planets.remove_child(planets[p])
	for e in extractors.size():
		viewport_planets.remove_child(extractors[e])
	for c in cargo.size():
		viewport_planets.remove_child(cargo[c])

signal activated
func set_active(pActive: bool) -> void:
	active = pActive
	scanned = pActive
	spr_active.visible = active
	activated.emit()
	

signal set_sel_planet
func set_planet_selected(pPlanet: Planet, pSelected: bool = false) -> void:
	set_sel_planet.emit(pPlanet,pSelected)

func scan() -> void:
	scanned = true
	frame = 2

#endregion
