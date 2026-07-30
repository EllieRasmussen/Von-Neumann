extends Sprite2D

const Star = preload("res://Scripts/star.gd")
const Planet = preload("res://Scripts/planet.gd")
const ProgBar = preload("res://Scripts/prog_bar.gd")
const Probe = preload("res://Scripts/probe.gd")
const Factory = preload("res://Scripts/factory.gd")
const Extractor = preload("res://Scripts/extractor.gd")

var planets: Array[Planet]
var factories: Array[Factory]
var extractors: Array[Extractor]

var bar_total_star_probes: ProgBar
var bar_next_star_probe: ProgBar

var activity_log = []

signal star_hovered
signal star_dehovered
signal star_selected
signal star_deselected
signal log_added

var selected = false
var hover = false

var adj = []

func _ready() -> void:
	
	#SET TEXTURE
	var star_imgs = []
	star_imgs.append(load("res://Images/Star_0.png"))
	star_imgs.append(load("res://Images/Star_1.png"))
	star_imgs.append(load("res://Images/Star_2.png"))
	star_imgs.append(load("res://Images/Star_3.png"))
	self.texture = star_imgs[randi()%len(star_imgs)]
	
	var num_planets = randi_range(5,5)
	for i in num_planets:
		var p = Planet.new()
		p.centered = true
		p.scale = Vector2.ONE * randf_range(0.005,0.015)
		p.set_orbital_radius((i+1)*50)
		planets.append(p)
		
	bar_total_star_probes = ProgBar.new()
	add_child(bar_total_star_probes)
	bar_total_star_probes.position = Vector2(-25,15)
	bar_total_star_probes.set_bar_width(5)
	bar_total_star_probes.set_bar_length(50)
	bar_total_star_probes.set_bg_color(Color.SLATE_GRAY)
	bar_total_star_probes.set_fg_color(Color.BLUE)
	
	
	bar_next_star_probe = ProgBar.new()
	add_child(bar_next_star_probe)
	bar_next_star_probe.position = Vector2(-25,20)
	bar_next_star_probe.set_bar_width(2)
	bar_next_star_probe.set_bar_length(50)
	bar_next_star_probe.set_bg_color(Color.DARK_SLATE_GRAY)
	bar_next_star_probe.set_fg_color(Color.AQUA)
	bar_next_star_probe.set_value(0)
	
	#TEMPORARY: STARS SHOULD NOT ALWAYS START WITH ONE FACTORY
	add_factory()
	add_extractor()
	

func _draw():
	for a in adj.size():
		draw_line(Vector2.ZERO,adj[a].position - position,Color.DIM_GRAY,2,false)

func add_adjacent(pStar: Star) -> void:
	if not adj.has(pStar):
		adj.append(pStar)
	if not pStar.adj.has(self):
		pStar.adj.append(self)
	

func add_log(pLog: String):
	activity_log.push_front(pLog)
	log_added.emit()
	

func add_factory() -> void:
	var new_factory = Factory.new()
	factories.append(new_factory)
	
func add_extractor() -> void:
	var new_extractor = Extractor.new()
	new_extractor.arrived.connect(handle_extractor_arrived.bind(new_extractor))
	extractors.append(new_extractor)
	
func handle_extractor_arrived(pExtractor: Extractor) -> void:
	#IF EXTRACTOR HAS RESOURCE
	if pExtractor.resource > 0:
		#DEPOSIT RESOURCE INTO FACTORY, SEND TO NEAREST PLANET
		factories[0].add_resource(pExtractor.resource)
		pExtractor.resource = 0
		
		var closest_index = 0
		var closest_dist = pExtractor.position.distance_squared_to(planets[0].position)
		for p in range(1,planets.size()):
			if pExtractor.position.distance_squared_to(planets[p].position) < closest_dist:
				closest_dist = pExtractor.position.distance_squared_to(planets[p].position)
				closest_index = p
		
		pExtractor.go_to(planets[closest_index])
	#ELSE
	else:
		#EXTRACT RESOURCE FROM PLANET, SEND TO NEAREST FACTORY
		var closest_index = 0
		var closest_dist = pExtractor.position.distance_squared_to(planets[0].position)
		for p in range(1,planets.size()):
			if pExtractor.position.distance_squared_to(planets[p].position) < closest_dist:
				closest_dist = pExtractor.position.distance_squared_to(planets[p].position)
				closest_index = p
		
		planets[closest_index].extract_resource(1)
		pExtractor.resource += 1
		
		
		pExtractor.go_to(factories[0])


#region HOVER AND SELECTION
func _on_hover(): 
	hover = true
	queue_redraw()
	star_hovered.emit()
	
func _exit_hover():
	hover = false
	queue_redraw()
	star_dehovered.emit()
	
func enter_hover_planet(pPlanet: Planet) -> void:
	pPlanet.on_hover()
	
func exit_hover_planet(pPlanet: Planet) -> void:
	pPlanet.exit_hover()
	
func select():
	selected = true
	queue_redraw()
	star_selected.emit()
	
	extractors[0].go_to(factories[0])
		
func deselect():
	selected = false
	hover = false
	queue_redraw()
	star_deselected.emit()
#endregion
