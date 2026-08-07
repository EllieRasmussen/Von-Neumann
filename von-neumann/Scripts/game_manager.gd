extends Node2D

const Star = preload("res://Scripts/star.gd")
const Planet = preload("res://Scripts/planet.gd")
const Factory = preload("res://Scripts/factory.gd")
const Extractor = preload("res://Scripts/extractor.gd")
const Line = preload("res://Scripts/line.gd")

var time: float

@export var cam_stars: Camera2D
@export var cam_planets: Camera2D

@export var viewport_stars: SubViewport
@export var viewport_planets: SubViewport
@export var window_upgrades: Window

@export var btn_star_viewer_window: Button
@export var btn_upgrades_window: Button

var stars: Array[Star] = []
var line_pool: Array[Line2D] = []

## 'SEL' = SELECTED
var sel_star: Star
var sel_planets: Array[Planet]
var sel_planet_paths: Array[Path2D]
var sel_factories: Array[Factory]
var sel_extractors: Array[Extractor]

var spr_star_hover: Sprite2D
var spr_star_selected: Sprite2D

var star_viewer_sprite_star: Sprite2D #A WRETCHED LITTLE VARIABLE THAT I WOULD LIKE TO SOMEDAY KILL

var probe_travel_dist = 50 # LIGHTYEARS
var probe_replication_attempt_rate = 0.5 # ATTEMPTS PER SECOND
var probe_replication_success_rate = 0.1 # % CHANCE

func _ready() -> void:	
	#GENERATE STARS + ADJACENCY
	for i in 25:
		create_star(Vector2((randf() * 1860) + 30, (randf() * 880) + 200))
	stars[0].add_factory()
	stars[0].add_extractor()
	
	
	Prim()
	
	time = 0
	
	spr_star_selected = Sprite2D.new()
	spr_star_selected.name = "spr_star_selected"
	spr_star_selected.texture = load("res://Images/circle_selected.png")
	spr_star_selected.scale = Vector2.ONE
	spr_star_selected.z_index = -1
	spr_star_selected.visible = false
	viewport_stars.add_child(spr_star_selected)
	
	spr_star_hover = Sprite2D.new()
	spr_star_hover.name = "spr_star_hover"
	spr_star_hover.texture = load("res://Images/circle_hover.png")
	spr_star_hover.scale = Vector2.ONE
	spr_star_hover.z_index = -2
	spr_star_hover.visible = false
	viewport_stars.add_child(spr_star_hover)
	
	
func _process(delta: float) -> void:
	time += delta
	
	if split_container_dragging:
		split_container.split_offset = clamp(split_container.split_offset,split_container_min,split_container_max)
	
	if sel_star != null:
		for p in sel_planets.size():
			var dist_to_mouse = viewport_planets.get_mouse_position().distance_squared_to(sel_planets[p].position)
			if dist_to_mouse < 300 and not sel_planets[p].hover:
				sel_planets[p].on_hover()
			elif sel_planets[p].hover:
				sel_planets[p].exit_hover()


#region STARS

func create_star(pPos: Vector2):
	var s = Star.new()
	s.position = pPos
	
	s.star_hovered.connect(set_hovered_star.bind(s))
	s.star_dehovered.connect(clear_hovered_star)
	s.star_selected.connect(set_selected_star.bind(s))
	
	stars.append(s)
	viewport_stars.add_child(s)


func set_hovered_star(pStar: Star) -> void:
	spr_star_hover.position = pStar.position
	spr_star_hover.visible = true
	
func clear_hovered_star() -> void:
	spr_star_hover.visible = false

func set_selected_star(pStar: Star) -> void:
	if sel_star != null:
		clear_selected_star()
	sel_star = pStar
	sel_planets = pStar.planets
	for p in sel_planets.size():
		var new_path = Path2D.new()
		new_path.curve = Curve2D.new()
		var angle = 0
		var num_points = 100
		for point in num_points:
			var new_point = Vector2(
				cos(angle) * sel_planets[p].orbital_radius,
				sin(angle) * sel_planets[p].orbital_radius
			)
			new_path.curve.add_point(new_point)
		sel_planet_paths.append(new_path)
		
	sel_factories = pStar.factories
	sel_extractors = pStar.extractors
	spr_star_selected.position = pStar.position
	spr_star_selected.visible = true
	open_star_viewer()
	orbit_planets()
	

func clear_selected_star() -> void:
	close_star_viewer()
	sel_star.deselect()
	sel_star = null
	sel_planets = []
	sel_factories = []
	sel_extractors = []
	spr_star_selected.visible = false
	

#endregion




#region PLANETS
func orbit_planets():
	while sel_star != null:
		for p in sel_planets.size():
			var x = cos(time + sel_planets[p].orbital_position) * sel_planets[p].orbital_radius + 256
			var y = sin(time + sel_planets[p].orbital_position) * sel_planets[p].orbital_radius + 256
			sel_planets[p].position = Vector2(x,y)
			sel_planets[p].rotate(sel_planets[p].rotational_velocity)
			
		for f in sel_factories.size():
			var x = cos(time + sel_factories[f].orbital_position) * sel_factories[f].orbital_radius + 256
			var y = sin(time + sel_factories[f].orbital_position) * sel_factories[f].orbital_radius + 256
			sel_factories[f].position = Vector2(x,y)
			
			
		await get_tree().process_frame

#endregion

## GENERATES A MINIMUM-SPANNING-TREE OF THE STARS STORED IN STARS[]
func Prim() -> void:
	#CREATE TEMP ARRAY WITH ALL ADJACENCIES
	var full_graph = []
	for s0 in stars.size():
		var edges = []
		for s1 in stars.size():
			if s0 == s1:
				edges.append(9223372036854775807)
			else:
				edges.append(stars[s0].position.distance_squared_to(stars[s1].position))
		full_graph.append(edges)
	
	
	
	#ADD FIRST STAR TO STAR LIST
	var used_stars = []
	used_stars.append(stars[0])
	
	while(used_stars.size() < stars.size()):
		#FIND SHORTEST EDGE FROM AVAILABLE STARS
		var shortest_edge = 9223372036854775807 
		var star0 = null
		var star1 = null
		
		
		for s in used_stars.size():
			var star_index = stars.find(used_stars[s])
			for a in full_graph[star_index].size():
					if full_graph[star_index][a] < shortest_edge and not used_stars.has(stars[a]):
						shortest_edge = full_graph[star_index][a]
						star0 = stars[star_index]
						star1 = stars[a]
		
		#ADD ADJACENT STAR TO STAR LIST
		if not used_stars.has(star0):
			used_stars.append(star0)
		if not used_stars.has(star1):
			used_stars.append(star1)
		
		#SET STAR ADJACENCIES
		star0.add_adjacent(star1)



#region WINDOW TOGGLING LOGIC

func open_star_viewer() -> void:
	btn_star_viewer_window.disabled = true
	if sel_star == null:
		#HANDLE OPENING WITHOUT A SELECTED STAR
		pass
	else:
		#LOAD STAR INTO STAR VIEWER
		star_viewer_sprite_star = Sprite2D.new()
		star_viewer_sprite_star.scale = Vector2.ONE * 0.06
		star_viewer_sprite_star.texture = load("res://Images/star.png")
		viewport_planets.add_child(star_viewer_sprite_star)
		star_viewer_sprite_star.position = Vector2(256,256)
		
		for p in sel_planets.size():
			viewport_planets.add_child(sel_planets[p])
			
		for f in sel_factories.size():
			viewport_planets.add_child(sel_factories[f])
			
		for e in sel_extractors.size():
			viewport_planets.add_child(sel_extractors[e])


func close_star_viewer() -> void:
	btn_star_viewer_window.disabled = false
	if sel_star == null:
		#HANDLE CLOSING WITHOUT A SELECTED STAR
		pass
	else:
		#CLEAR STAR FROM STAR VIEWER
		star_viewer_sprite_star.queue_free()
		
		for p in sel_planets.size():
			viewport_planets.remove_child(sel_planets[p])
		
		for f in sel_factories.size():
			viewport_planets.remove_child(sel_factories[f])
			
		for e in sel_extractors.size():
			viewport_planets.remove_child(sel_extractors[e])


func _on_window__star_viewer_close_requested() -> void:
	clear_selected_star()


func _on_btn_upgrades_pressed() -> void:
	if window_upgrades.visible:
		window_upgrades.visible = false
		btn_upgrades_window.disabled = false
	else:
		window_upgrades.visible = true
		btn_upgrades_window.disabled = true


func _on_window__upgrades_close_requested() -> void:
	window_upgrades.visible = false
	btn_upgrades_window.disabled = false

#endregion

@export var split_container: HSplitContainer
var split_container_min = 200
var split_container_max = 1800
var split_container_dragging = false
func _on_h_split_container_2_drag_ended() -> void:
	split_container_dragging = false


func _on_h_split_container_2_drag_started() -> void:
	split_container_dragging = true
