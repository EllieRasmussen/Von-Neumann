extends Sprite2D

const Star = preload("res://Scripts/star.gd")
const Planet = preload("res://Scripts/planet.gd")
const ProgBar = preload("res://Scripts/prog_bar.gd")
const Probe = preload("res://Scripts/probe.gd")
const Factory = preload("res://Scripts/factory.gd")
const Extractor = preload("res://Scripts/extractor.gd")
const Cargo = preload("res://Scripts/cargo.gd")
const OffscreenFollower = preload("res://Scripts/offscreen_follower.gd")

var viewport_planets: SubViewport

var planets: Array[Planet]
var factories: Array[Factory]
var extractors: Array[Extractor]
var cargo: Array[Cargo]

var num_points_per_path = 50
var paths: Array[Path2D]
var followers: Array[OffscreenFollower]

var factory_orbit = 15000 #15000 originally 
var factory_orbit_speed = 0.001 #0.001 originally
var factory_path: Path2D
var factory_followers: Array[OffscreenFollower]

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
	create_factory_path()
	
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



func _process(delta: float) -> void:
	if selected:
		for f in followers.size():
			followers[f].process_on_screen(planets[f].orbital_velocity * delta)
		for f in factory_followers.size():
			factory_followers[f].process_on_screen(factory_orbit_speed * delta)
		
	else:
		for p in planets.size():
			planets[p].unselected_process(delta)
		for f in followers.size():
			followers[f].process_off_screen(planets[f].orbital_velocity * delta)
		for f in factory_followers.size():
			factory_followers[f].process_off_screen(factory_orbit_speed * delta)
	
	
	for e in range(extractors.size()-1,-1,-1):
			if extractors[e].travel(delta):
				extractors[e].arrive()
				extractors[e].queue_free()
				extractors.remove_at(e)
	for c in range(cargo.size()-1,-1,-1):
		if cargo[c].travel(delta):
			cargo[c].arrive()
			cargo[c].queue_free()
			cargo.remove_at(c)

func _draw():
	for a in adj.size():
		draw_line(Vector2.ZERO,adj[a].position - position,Color.DIM_GRAY,2,false)



func create_planets(num_planets: int) -> void:
	for p in num_planets:
		#PLANET
		var new_planet = Planet.new()
		new_planet.centered = true
		new_planet.set_orbital_radius(randf_range((p+1)*500,(p+1)*1500))
		new_planet.planet_hovered.connect(set_hovered_planet.bind(new_planet))
		new_planet.planet_dehovered.connect(dehover_planet)
		new_planet.planet_selected.connect(set_selected_planet.bind(new_planet))
		new_planet.planet_deselected.connect(deselect_planet)
		
		#PATH
		var new_path = Path2D.new()
		new_path.curve = Curve2D.new()
		var path_offset = Vector2(
			randf_range(-new_planet.orbital_radius * 0.25, new_planet.orbital_radius * 0.25),
			randf_range(-new_planet.orbital_radius * 0.25, new_planet.orbital_radius * 0.25)
		)
		new_planet.orbital_offset = path_offset
		new_path.position += path_offset
		
		#LINE
		var new_line = Line2D.new()
		new_line.z_index = -1
		new_line.closed = true
		new_line.default_color = Color.DIM_GRAY
		new_line.width = 5
		
		var angle = 0.0
		for point in num_points_per_path:
			var new_point = Vector2(
				cos(angle) * new_planet.orbital_radius,
				sin(angle) * new_planet.orbital_radius
			)
			new_path.curve.add_point(new_point)
			new_line.add_point(new_point)
			angle += 6.2832 / (num_points_per_path - 1)
			
		var new_follower = OffscreenFollower.new()
		new_follower.loop = true
		new_follower.banked_progress = randf()
		
		new_planet.extracted.connect(add_cargo.bind(new_planet, new_follower))
		
		new_follower.add_child(new_planet)
		new_path.add_child(new_follower)
		new_path.add_child(new_line)
		planets.append(new_planet)
		paths.append(new_path)
		followers.append(new_follower)

func create_factory_path():
	factory_path = Path2D.new()
	factory_path.curve = Curve2D.new()
	var new_line = Line2D.new()
		
	var angle = 0.0
	for point in num_points_per_path:
		var new_point = Vector2(
			cos(angle) * factory_orbit,
			sin(angle) * factory_orbit
		)
		factory_path.curve.add_point(new_point)
		new_line.add_point(new_point)
		angle += 6.2832 / (num_points_per_path - 1)
		
	factory_path.add_child(new_line)
	factory_path.visible = false





func add_adjacent(pStar: Star) -> void:
	if not adj.has(pStar):
		adj.append(pStar)
	if not pStar.adj.has(self):
		pStar.adj.append(self)
	

func add_factory() -> void:
	factory_path.visible = true
	
	var new_factory = Factory.new()
	new_factory.created_probe.connect(send_probe)
	new_factory.orbital_radius = factory_orbit
	
	
	var new_follower = OffscreenFollower.new()
	new_follower.loop = true
	new_follower.banked_progress = randf()
	
	
	new_follower.add_child(new_factory)
	factory_path.add_child(new_follower)
	factories.append(new_factory)
	factory_followers.append(new_follower)
	
	if not active:
		set_active(true)
		
func add_extractor() -> void:
	var new_extractor = Extractor.new()
	new_extractor.position = get_factory_position_from_progress_ratio(factory_followers[0].get_real_progress()) + (Vector2(randf(),randf())*10000)
	new_extractor.set_target_planet(planets[0],followers[0])
	extractors.append(new_extractor)
	if selected:
		viewport_planets.add_child(new_extractor)
	
	
func add_cargo(pPlanet: Planet, pFollower: OffscreenFollower) -> void:
	var new_cargo = Cargo.new()
	var angle = 6.283 * pFollower.get_real_progress()
	new_cargo.position = Vector2(
		cos(angle) * pPlanet.orbital_radius,
		sin(angle) * pPlanet.orbital_radius
	)
	new_cargo.position += pPlanet.orbital_offset
	factory_followers[0].print_progress = true
	new_cargo.set_target_factory(factories[0], factory_followers[0])
	cargo.append(new_cargo)
	if selected:
		viewport_planets.add_child(new_cargo)
	


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
	
	
	


func get_planet_position(progress_ratio: float, orbit: float) -> Vector2:
	var angle = 6.283 * progress_ratio
	return Vector2(
		cos(angle) * orbit,
		sin(angle) * orbit
	)

func get_factory_position_from_progress_ratio(pRatio: float) -> Vector2:
	var angle = 6.283 * pRatio
	return Vector2(
		cos(angle) * factory_orbit,
		sin(angle) * factory_orbit
	)


func update_followers():
	for f in followers.size():
		followers[f].update()
	
	for f in factory_followers.size():
		factory_followers[f].update()

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
	
func enter_hover_planet(pPlanet: Planet) -> void:
	pPlanet.on_hover()
	
func exit_hover_planet(pPlanet: Planet) -> void:
	pPlanet.exit_hover()
	
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
func set_selected_planet(pPlanet: Planet) -> void:
	spr_planet_selected.reparent(pPlanet)
	spr_planet_selected.position = Vector2.ZERO
	spr_planet_selected.visible = true
	set_sel_planet.emit(pPlanet)

func deselect_planet() -> void:
	spr_planet_selected.visible = false

#endregion
