extends Sprite2D

const Star = preload("res://Scripts/star.gd")
const Planet = preload("res://Scripts/planet.gd")
const ProgBar = preload("res://Scripts/prog_bar.gd")
const Probe = preload("res://Scripts/probe.gd")
const Factory = preload("res://Scripts/factory.gd")
const Extractor = preload("res://Scripts/extractor.gd")
const Cargo = preload("res://Scripts/cargo.gd")

var viewport_planets: SubViewport

var planets: Array[Planet]
var factories: Array[Factory]
var extractors: Array[Extractor]
var cargo: Array[Cargo]

var orbit_lines: Array[Line2D]
var factory_orbital_radius: float

var num_points_per_path = 50
#var paths: Array[Path2D]
#var followers: Array[OffscreenFollower]

#var factory_orbit_speed = 0.001 #0.001 originally
#var factory_path: Path2D
#var factory_followers: Array[OffscreenFollower]

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

func _ready() -> void:
	
	#SET TEXTURE
	var star_imgs = []
	star_imgs.append(load("res://Images/Star_0.png"))
	star_imgs.append(load("res://Images/Star_1.png"))
	star_imgs.append(load("res://Images/Star_2.png"))
	star_imgs.append(load("res://Images/Star_3.png"))
	self.texture = star_imgs[randi()%len(star_imgs)]
	
	create_planets(randi_range(1,10))
	
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
	for f in factories.size():
		factories[f].update_position(delta)
	#for e in range(extractors.size()-1,-1,-1):
		#extractors[e].update_position(delta)
	#for c in range(cargo.size()-1,-1,-1):
		#cargo[c].update_position(delta)

func _draw():
	pass
	#for a in adj.size():
		#draw_line(Vector2.ZERO,adj[a].position - position,Color.DIM_GRAY,2,false)



func create_planets(num_planets: int) -> void:
	for p in num_planets:
		#PLANET
		var new_planet = Planet.new()
		new_planet.set_orbital_radius(randf_range((p+1)*1000,(p+1)*1500))
		new_planet.planet_hovered.connect(set_hovered_planet.bind(new_planet))
		new_planet.planet_dehovered.connect(dehover_planet)
		new_planet.planet_selected.connect(set_selected_planet.bind(new_planet))
		new_planet.planet_deselected.connect(deselect_planet)
		
		
		#LINE
		var new_line = Line2D.new()
		new_line.position = new_planet.orbital_offset
		new_line.z_index = -1
		new_line.closed = true
		new_line.default_color = Color.DIM_GRAY
		new_line.width = 5
		
		var angle = 0.0
		var eccentricity_x: float = randf_range(0.25,1.25)
		var eccentricity_y: float = randf_range(0.25,1.25)
		for point in num_points_per_path:
			var new_point = Vector2(
				cos(angle) * new_planet.orbital_radius * eccentricity_x,
				sin(angle) * new_planet.orbital_radius * eccentricity_y
			)
			new_line.add_point(new_point)
			angle += 6.2832 / (num_points_per_path - 1)
			
		
		
		new_planet.extracted.connect(create_cargo.bind(new_planet))
		
		planets.append(new_planet)
		orbit_lines.append(new_line)

#func create_factory_path():
	#factory_path = Path2D.new()
	#factory_path.curve = Curve2D.new()
	#var new_line = Line2D.new()
		#
	#var angle = 0.0
	#for point in num_points_per_path:
		#var new_point = Vector2(
			#cos(angle) * factory_orbit,
			#sin(angle) * factory_orbit
		#)
		#factory_path.curve.add_point(new_point)
		#new_line.add_point(new_point)
		#angle += 6.2832 / (num_points_per_path - 1)
		#
	#factory_path.add_child(new_line)
	#factory_path.visible = false



var adj_lines: Array[Line2D] = []
func add_adjacent(pStar: Star, p_line: Line2D) -> void:
	if not adj.has(pStar):
		adj.append(pStar)
		
		
	if p_line == null:
		p_line = Line2D.new()
		p_line.position = position
		p_line.z_index = -10
		p_line.add_point(Vector2.ZERO)
		p_line.add_point(pStar.position - position)
		p_line.default_color = Color.DIM_GRAY
		p_line.width = 2
		
		adj_lines.append(p_line)
		
		pStar.add_adjacent(self, p_line)
	elif not adj_lines.has(p_line):
		adj_lines.append(p_line)
	

func create_factory() -> void:
	if factories.size() == 0:
		create_factory_orbit_line()
	
	var new_factory = Factory.new()
	new_factory.factory_hovered.connect(set_hovered_factory.bind(new_factory))
	new_factory.factory_dehovered.connect(dehover_factory)
	new_factory.factory_selected.connect(set_selected_factory.bind(new_factory))
	new_factory.factory_deselected.connect(deselect_factory)
	new_factory.created_extractor.connect(create_extractor)
	new_factory.created_probe.connect(send_probe)
	new_factory.orbital_radius = factory_orbital_radius
	
	factories.append(new_factory)
	
	if not active:
		set_active(true)
		
func create_factory_orbit_line() -> void:
	#FACTORY ORBIT SHOULD BE SLIGHTLY LARGER THAN THE MAX DISTANCE A PLANET CAN GET FROM THE STAR
	var max_orbit_sqr = 0.0
	for p in planets.size():
		var planet_max_sqr = planets[p].orbital_offset.length_squared() + (planets[p].orbital_radius*planets[p].orbital_radius)
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
	var new_extractor = Extractor.new()
	new_extractor.position = factories[0].position
	new_extractor.set_target(planets[0])
	new_extractor.arrived.connect(planets[0].add_extractors)
	new_extractor.arrived.connect(remove_extractor.bind(new_extractor))
	extractors.append(new_extractor)
	if selected:
		viewport_planets.add_child(new_extractor)
	
func remove_extractor(pExtractor: Extractor) -> void:
	extractors.erase(pExtractor)
	pExtractor.queue_free()
	
func create_cargo(pPlanet: Planet) -> void:
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

func send_probe() -> void:
	var target = adj[0]
	var dist_to_target = adj[0].position.distance_squared_to(position)
	var shortest_dist = dist_to_target
	for a in adj.size():
		dist_to_target = adj[a].position.distance_squared_to(position)
		if dist_to_target < shortest_dist:
			shortest_dist = dist_to_target
			target = adj[a]
	var new_probe = Probe.new()
	new_probe.travel(position, target)
	add_child(new_probe)
	
	
	


#func update_followers():
	#for f in followers.size():
		#followers[f].update()
	#
	#for f in factory_followers.size():
		#factory_followers[f].update()

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
		
func deselect():
	selected = false
	hover = false
	queue_redraw()
	star_deselected.emit()
	
func set_active(pActive: bool) -> void:
	active = pActive
	spr_active.visible = active

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
