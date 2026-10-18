extends Sprite2D

const Star = preload("res://Scripts/star.gd")
const Planet = preload("res://Scripts/planet.gd")
const ProgBar = preload("res://Scripts/prog_bar.gd")
const Probe = preload("res://Scripts/probe.gd")
const Factory = preload("res://Scripts/factory.gd")
const Extractor = preload("res://Scripts/extractor.gd")
const Cargo = preload("res://Scripts/cargo.gd")

var hostility: float

var viewport_planets: SubViewport

var planets: Array[Planet]
var factories: Array[Factory]
var extractors: Array[Extractor]
var cargo: Array[Cargo]

var orbit_lines: Array[Line2D]
var factory_orbital_radius: float

var num_points_per_path = 50

signal star_hovered
signal star_dehovered
signal star_selected
signal star_deselected

var selected = false
var hover = false

var active = false
var spr_active: Sprite2D

var area2D: Area2D

var spr_planet_hover: Sprite2D
var spr_planet_selected: Sprite2D

var spr_factory_hover: Sprite2D
var spr_factory_selected: Sprite2D

var adj = []
var adj_lines: Array[Line2D] = []

func _init() -> void:
	hostility = randf_range(0.1,0.5)
	
	#SET TEXTURE
	var star_imgs = []
	star_imgs.append(load("res://Images/Star_0.png"))
	star_imgs.append(load("res://Images/Star_1.png"))
	star_imgs.append(load("res://Images/Star_2.png"))
	star_imgs.append(load("res://Images/Star_3.png"))
	self.texture = star_imgs[randi()%len(star_imgs)]
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	
	create_planets(randi_range(1,Globals.max_planets_per_star))
	
	area2D = Area2D.new()
	var collisionShape = CollisionShape2D.new()
	collisionShape.shape = CircleShape2D.new()
	collisionShape.shape.radius = 10
	area2D.mouse_entered.connect(_on_hover)
	area2D.mouse_exited.connect(_exit_hover)
	area2D.input_event.connect(handle_area2d_input)
	area2D.add_child(collisionShape)
	add_child(area2D)
	
	spr_active = Sprite2D.new()
	spr_active.texture = load("res://Images/star_active.png")
	set_active(false)
	add_child(spr_active)
	
	spr_planet_hover = Sprite2D.new()
	spr_planet_hover.texture = load("res://Images/circle_hover.png")
	spr_planet_hover.visible = false
	spr_planet_hover.scale = Vector2.ONE * 10
	add_child(spr_planet_hover)
	
	spr_planet_selected = Sprite2D.new()
	spr_planet_selected.texture = load("res://Images/circle_selected0.png")
	spr_planet_selected.visible = false
	spr_planet_selected.scale  = Vector2.ONE * 10
	add_child(spr_planet_selected)
	
	spr_factory_hover = Sprite2D.new()
	spr_factory_hover.texture = load("res://Images/circle_hover.png")
	spr_factory_hover.visible = false
	spr_factory_hover.scale = Vector2.ONE * 10
	add_child(spr_factory_hover)
	
	spr_factory_selected = Sprite2D.new()
	spr_factory_selected.texture = load("res://Images/circle_selected0.png")
	spr_factory_selected.visible = false
	spr_factory_selected.scale  = Vector2.ONE * 10
	add_child(spr_factory_selected)
	

func _ready() -> void:
	pass


var has_valid_planet: bool = true
func _process(delta: float) -> void:
	## A BUNCH OF STUFF HERE LEFTOVER FROM THE PATH FOLLOWER DAYS. USEFUL PATTERN TO COME BACK TO WHEN IT'S TIME FOR BATCHING
	#if selected:
		#for f in followers.size():
			#followers[f].process_on_screen(planets[f].orbital_velocity * delta)
		#for f in factory_followers.size():
			#factory_followers[f].process_on_screen(factory_orbit_speed * delta)
		#
	#else:
		#for p in planets.size():
			#planets[p].unselected_process(delta)
		#for f in followers.size():
			#followers[f].process_off_screen(planets[f].orbital_velocity * delta)
		#for f in factory_followers.size():
			#factory_followers[f].process_off_screen(factory_orbit_speed * delta)
	for p in planets.size():
		planets[p].update_position(delta)
		planets[p].update_extraction()
	for f in factories.size():
		factories[f].update_position(delta)
		factories[f].update_factory(has_valid_planet)

func create_planets(num_planets: int) -> void:
	for p in num_planets:
		#PLANET
		var new_planet = Planet.new()
		new_planet.planet_hovered.connect(set_hovered_planet.bind(new_planet))
		new_planet.planet_dehovered.connect(dehover_planet)
		new_planet.planet_selected.connect(set_selected_planet.bind(new_planet))
		new_planet.planet_deselected.connect(deselect_planet)
		new_planet.extracted.connect(create_cargo)
		
		
		#LINE
		var new_line = Line2D.new()
		new_line.position = Vector2.ZERO
		new_line.z_index = 1
		new_line.closed = true
		new_line.default_color = Color.DIM_GRAY
		new_line.width = 5
		
		
		var r0 = (p+1) * 2000
		var r1 = randf_range(0.65,1.0) * (p+1) * 2000
		var orbit_angle = randf() * 6.2832
		var focus_distance = sqrt(abs((r0*r0)-(r1*r1)))
		var focus = Vector2(
			cos(orbit_angle) * focus_distance,
			sin(orbit_angle) * focus_distance
		)
		new_planet.set_orbit(r0,r1,focus_distance,orbit_angle)
		
		var t = 0.0
		for point in num_points_per_path:
			var new_point = Vector2(
				r0 * cos(orbit_angle) * cos(t) - r1 * sin(orbit_angle) * sin(t) + focus.x,
				r0 * sin(orbit_angle) * cos(t) + r1 * cos(orbit_angle) * sin(t) + focus.y
			)
			new_line.add_point(new_point)
			t += 6.2832 / (num_points_per_path - 1)
			
		
		
		
		
		planets.append(new_planet)
		orbit_lines.append(new_line)

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

func create_probe() -> void:
	adj = get_adjacent_stars()
	var closest: Star = null
	var min_dist: float = 100000000000
	for a in adj.size():
		if adj[a].factories.size() == 0:
			var dist_between: float = (adj[a].position - position).length_squared()
			if dist_between < min_dist:
				min_dist = dist_between
				closest = adj[a]
			
	
	if closest != null:
		var new_probe = Probe.new()
		new_probe.travel(position, closest)
		add_child(new_probe)

func create_factory() -> void:
	set_active(true)
	
	if factories.size() == 0:
		create_factory_orbit_line()
	
	var new_factory = Factory.new()
	new_factory.factory_hovered.connect(set_hovered_factory.bind(new_factory))
	new_factory.factory_dehovered.connect(dehover_factory)
	new_factory.factory_selected.connect(set_selected_factory.bind(new_factory))
	new_factory.factory_deselected.connect(deselect_factory)
	new_factory.created_extractor.connect(create_extractor)
	new_factory.created_probe.connect(create_probe)
	new_factory.set_orbit(factory_orbital_radius,factory_orbital_radius,sqrt(factory_orbital_radius*factory_orbital_radius+factory_orbital_radius*factory_orbital_radius),0)
	new_factory.add_resource(Globals.starting_resource_in_factroy)
	factories.append(new_factory)
	
	if selected:
		viewport_planets.add_child(new_factory)
	


func create_factory_orbit_line() -> void:
	#FACTORY ORBIT SHOULD BE SLIGHTLY LARGER THAN THE MAX DISTANCE A PLANET CAN GET FROM THE STAR
	var max_orbit_sqr = 0.0
	for p in planets.size():
		var planet_max_sqr = planets[p].orbital_focus.length_squared() + (planets[p].orbital_radius_0*planets[p].orbital_radius_0)
		if planet_max_sqr > max_orbit_sqr:
			max_orbit_sqr = planet_max_sqr
	factory_orbital_radius = sqrt(max_orbit_sqr) + 500
	
	
	var new_line = Line2D.new()
	new_line.z_index = -1
	new_line.closed = true
	new_line.default_color = Color.SKY_BLUE
	new_line.width = 5
	
	var angle = 0.0
	for point in num_points_per_path:
		var new_point = Vector2(
			cos(angle) * factory_orbital_radius,
			sin(angle) * factory_orbital_radius
		)
		new_line.add_point(new_point)
		angle += 6.2832 / (num_points_per_path - 1)
	
	orbit_lines.append(new_line)

func create_extractor() -> void:
	var target: Planet = find_planet_with_room_for_extractor()
	if target == null:
		has_valid_planet = false
		return
	target.queued_extractors += 1
	var new_extractor = Extractor.new()
	new_extractor.position = factories[0].position
	new_extractor.arrived.connect(target.add_extractors)
	new_extractor.arrived.connect(remove_extractor.bind(new_extractor))
	new_extractor.set_target(target)
	
	extractors.append(new_extractor)
	if selected:
		viewport_planets.add_child(new_extractor)
	

func remove_extractor(pExtractor: Extractor) -> void:
	extractors.erase(pExtractor)
	pExtractor.queue_free()

func create_cargo(pPlanet: Planet,pResource:int=1) -> void:
	if factories.size() > 0:
		var new_cargo = Cargo.new()
		new_cargo.position = pPlanet.position
		new_cargo.set_target(factories[0])
		new_cargo.arrived.connect(factories[0].add_resource)
		new_cargo.arrived.connect(remove_cargo.bind(new_cargo))
		cargo.append(new_cargo)
		if selected:
			viewport_planets.add_child(new_cargo)
	
	
func remove_cargo(pCargo: Cargo) -> void:
	cargo.erase(pCargo)
	pCargo.queue_free()



#region HOVER, SELECTION, ACTIVE
func _on_hover(): 
	hover = true
	queue_redraw()
	star_hovered.emit()
	
func _exit_hover():
	hover = false
	queue_redraw()
	star_dehovered.emit()

func handle_area2d_input(_viewport: Node, event: InputEvent, _shape_idx: int):
	if event.is_action_pressed("Click") and not selected:
		select()
	
func select():
	selected = true
	queue_redraw()
	star_selected.emit()
	
	for l in orbit_lines.size():
		viewport_planets.add_child(orbit_lines[l])
	for p in planets.size():
		viewport_planets.add_child(planets[p])
	for f in factories.size():
		viewport_planets.add_child(factories[f])
	for e in extractors.size():
		viewport_planets.add_child(extractors[e])
	for c in cargo.size():
		viewport_planets.add_child(cargo[c])
		
	adj = get_adjacent_stars()
	for l in adj.size():
		var new_line = Line2D.new()
		new_line.position = position
		new_line.z_index = -10
		new_line.add_point(Vector2.ZERO)
		new_line.add_point(adj[l].position - position)
		new_line.default_color = Color.DIM_GRAY
		new_line.width = 2
		
		adj_lines.append(new_line)
		game_manager.viewport_stars.add_child(new_line)
		
func deselect():
	selected = false
	hover = false
	queue_redraw()
	star_deselected.emit()
	
	for l in orbit_lines.size():
		viewport_planets.remove_child(orbit_lines[l])
	for p in planets.size():
		viewport_planets.remove_child(planets[p])
	for f in factories.size():
		viewport_planets.remove_child(factories[f])
	for e in extractors.size():
		viewport_planets.remove_child(extractors[e])
	for c in cargo.size():
		viewport_planets.remove_child(cargo[c])
		
	for l in range(adj_lines.size() - 1, -1, -1):
		if not adj_lines[l].is_queued_for_deletion():
			adj_lines[l].queue_free()
			adj_lines.remove_at(l)
	
signal activated
func set_active(pActive: bool) -> void:
	active = pActive
	spr_active.visible = active
	activated.emit()

func set_hovered_planet(pPlanet: Planet) -> void:
	spr_planet_hover.reparent(pPlanet)
	spr_planet_hover.position = Vector2.ZERO
	spr_planet_hover.visible = true

func dehover_planet() -> void:
	spr_planet_hover.visible = false

signal set_sel_planet
signal desel_planet #HATE THIS ABBREVIATION BUT WE ALL SIN IN THE DARK
func set_selected_planet(pPlanet: Planet) -> void:
	spr_planet_selected.reparent(pPlanet)
	spr_planet_selected.position = Vector2.ZERO
	spr_planet_selected.visible = true
	set_sel_planet.emit(pPlanet)

func deselect_planet() -> void:
	spr_planet_selected.visible = false
	desel_planet.emit()


func set_hovered_factory(pFactory: Factory) -> void:
	spr_factory_hover.reparent(pFactory)
	spr_factory_hover.position = Vector2.ZERO
	spr_factory_hover.visible = true
	
func dehover_factory() -> void:
	spr_factory_hover.visible = false
	
signal set_sel_factory
signal desel_factory
func set_selected_factory(pFactory: Factory) -> void:
	spr_factory_selected.reparent(pFactory)
	spr_factory_selected.position = Vector2.ZERO
	spr_factory_selected.visible = true
	set_sel_factory.emit(pFactory)
	
func deselect_factory() -> void:
	spr_factory_selected.visible = false
	desel_factory.emit()
#endregion
