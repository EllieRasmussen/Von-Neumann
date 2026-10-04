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

var num_points_per_path = 50
var paths: Array[Path2D]
var followers: Array[PathFollow2D]
var progress_bank: Array[float] #you can't advance progress without being in the scene tree >:[

var factory_orbit = 15000
var factory_orbit_speed = 0.001
var factory_path: Path2D
var factory_followers: Array[PathFollow2D]
var factory_progress_bank: Array[float] # YOU CAN"T ADVANCE PROGRESS WITHOUT BEING IN THE SCENE TREE >:[

signal star_hovered
signal star_dehovered
signal star_selected
signal star_deselected

var selected = false
var hover = false

var active = false
var spr_active: Sprite2D

var area2D: Area2D
var collisionShape: CollisionShape2D

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
	collisionShape = CollisionShape2D.new()
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
	



func _process(delta: float) -> void:
	if selected:
		for f in followers.size():
			followers[f].progress_ratio += planets[f].orbital_velocity * delta
		for f in factory_followers.size():
			factory_followers[f].progress_ratio += factory_orbit_speed * delta
		for e in range(extractors.size()-1,-1,-1):
			if extractors[e].travel(delta):
				extractors[e].arrive()
				extractors[e].queue_free()
				extractors.remove_at(e)
		for c in range(cargo.size()-1,-1,-1):
			if cargo[c].travel(delta, factory_progress_bank[0]):
				cargo[c].arrive()
				cargo[c].queue_free()
				cargo.remove_at(c)
	else:
		for p in planets.size():
			planets[p].unselected_process(delta)
		for f in progress_bank.size():
			progress_bank[f] += planets[f].orbital_velocity * delta
		for f in factory_progress_bank.size():
			factory_progress_bank[f] += factory_orbit_speed * delta
		for e in range(extractors.size()-1,-1,-1):
			if extractors[e].travel(delta):
				extractors[e].arrive()
				extractors[e].queue_free()
				extractors.remove_at(e)
		for c in range(cargo.size()-1,-1,-1):
			if cargo[c].travel(delta, factory_progress_bank[0]):
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
			
		var new_follower = PathFollow2D.new()
		new_follower.loop = true
		progress_bank.append(randf())
		
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
	
	
	var new_follower = PathFollow2D.new()
	new_follower.loop = true
	factory_progress_bank.append(randf())
	
	new_follower.add_child(new_factory)
	factory_path.add_child(new_follower)
	factories.append(new_factory)
	factory_followers.append(new_follower)
	
	
	if not active:
		set_active(true)
		
func add_extractor() -> void:
	var new_extractor = Extractor.new()
	new_extractor.position = get_factory_position_from_progress_ratio(factory_followers[0].progress_ratio + factory_progress_bank[0]) + (Vector2(randf(),randf())*10000)
	new_extractor.set_target_planet(planets[0],followers[0])
	extractors.append(new_extractor)
	if selected:
		viewport_planets.add_child(new_extractor)
	
	
func add_cargo(pPlanet: Planet, pFollower: PathFollow2D) -> void:
	var new_cargo = Cargo.new()
	var angle = 6.283 * pFollower.progress_ratio
	new_cargo.position = Vector2(
		cos(angle) * pPlanet.orbital_radius,
		sin(angle) * pPlanet.orbital_radius
	)
	new_cargo.position += pPlanet.orbital_offset
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
		followers[f].progress_ratio += progress_bank[f]
		progress_bank[f] = 0.0
	
	for f in factory_followers.size():
		factory_followers[f].progress_ratio += factory_progress_bank[f]
		factory_progress_bank[f] = 0.0

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

#endregion
