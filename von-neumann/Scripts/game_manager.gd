extends Node2D

const Star = preload("res://Scripts/star.gd")
const Planet = preload("res://Scripts/planet.gd")
const Factory = preload("res://Scripts/factory.gd")
const Extractor = preload("res://Scripts/extractor.gd")

var time: float

@export var cam_stars: Camera2D
@export var cam_planets: Camera2D

@export var viewport_stars: SubViewport
@export var viewport_planets: SubViewport

var stars: Array[Star] = []

## 'SEL' = SELECTED
var max_planets_per_star = 10
var sel_star: Star
var sel_planet: Planet
var num_points_per_path = 50
var sel_paths: Array[Path2D]
var sel_path_followers: Array[PathFollow2D]
var sel_path_lines: Array[Line2D]
var sel_planet_areas: Array[Area2D]

var spr_star_hover: Sprite2D
var spr_star_selected: Sprite2D
var spr_planet_hover: Sprite2D
var spr_planet_selected: Sprite2D

var star_viewer_sprite_star: Sprite2D #A WRETCHED LITTLE VARIABLE THAT I WOULD LIKE TO SOMEDAY KILL

@export var info_name: Label
@export var info_texture: TextureRect
@export var info_lbl: Label

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
	spr_star_selected.z_index = 1
	spr_star_selected.visible = false
	viewport_stars.add_child(spr_star_selected)
	
	spr_star_hover = Sprite2D.new()
	spr_star_hover.name = "spr_star_hover"
	spr_star_hover.texture = load("res://Images/circle_hover.png")
	spr_star_hover.scale = Vector2.ONE
	spr_star_hover.z_index = 2
	spr_star_hover.visible = false
	viewport_stars.add_child(spr_star_hover)
	
	spr_planet_selected = Sprite2D.new()
	spr_planet_selected.name = "spr_planet_selected"
	spr_planet_selected.texture = load("res://Images/circle_selected.png")
	spr_planet_selected.scale = Vector2.ONE
	spr_planet_selected.z_index = 1
	spr_planet_selected.visible = false
	viewport_planets.add_child(spr_planet_selected)
	
	spr_planet_hover = Sprite2D.new()
	spr_planet_hover.name = "spr_planet_hover"
	spr_planet_hover.texture = load("res://Images/circle_hover.png")
	spr_planet_hover.scale = Vector2.ONE
	spr_planet_hover.z_index = 2
	spr_planet_hover.visible = false
	viewport_planets.add_child(spr_planet_hover)
	
	
	#INSTANTIATE PATHS, PATH FOLLOWERS, PLANETS
	for p in max_planets_per_star:
		#CREATE NEW PATH
		var new_line = Line2D.new()
		new_line.z_index = -1
		new_line.closed = true
		new_line.default_color = Color.DIM_GRAY
		new_line.width = 10
		
		var new_path = Path2D.new()
		new_path.curve = Curve2D.new()
		
		for point in num_points_per_path:
			new_path.curve.add_point(Vector2.ZERO)
			new_line.add_point(Vector2.ZERO)
		
		#CREATE NEW PATH FOLLOWER
		var new_follower = PathFollow2D.new()
		new_follower.loop = true
		
		#CREATE CLICKABLE AREAS
		var new_area = Area2D.new()
		var collision_shape = CollisionShape2D.new()
		collision_shape.shape = CircleShape2D.new()
		collision_shape.shape.radius = 10
		new_area.input_event.connect(_try_select_planet)
		new_area.add_child(collision_shape)
		sel_planet_areas.append(new_area)
		
		sel_paths.append(new_path)
		sel_path_followers.append(new_follower)
		sel_path_lines.append(new_line)
		sel_paths[p].add_child(sel_path_followers[p])
		sel_paths[p].add_child(sel_path_lines[p])
		viewport_planets.add_child(sel_paths[p])
		
	
	
func _process(delta: float) -> void:
	time += delta
	
	if split_container_dragging:
		split_container.split_offset = clamp(split_container.split_offset,split_container_min,split_container_max)


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
	clear_selected_star()
	#cam_planets.position = Vector2.ZERO
	sel_star = pStar
	for p in sel_star.planets.size():
		sel_paths[p].curve = Curve2D.new()
		var angle = 0.0
		for point in num_points_per_path:
			var new_point = Vector2(
				cos(angle) * sel_star.planets[p].orbital_radius,
				sin(angle) * sel_star.planets[p].orbital_radius
			)
			sel_paths[p].curve.add_point(new_point)
			sel_path_lines[p].points[point] = new_point
			angle += 6.2832 / (num_points_per_path - 1)
			
		sel_paths[p].position = sel_star.planets[p].orbital_offset
		sel_path_lines[p].visible = true
		sel_path_followers[p].add_child(sel_star.planets[p])
		sel_star.planets[p].add_child(sel_planet_areas[p])
		sel_planet_areas[p].mouse_entered.connect(_hover_planet.bind(sel_star.planets[p]))
		sel_planet_areas[p].mouse_exited.connect(_exit_hover_planet.bind(sel_star.planets[p]))
		sel_path_followers[p].progress_ratio = sel_star.planets[p].orbital_position
		
	spr_star_selected.position = sel_star.position
	spr_star_selected.visible = true
	
	star_viewer_sprite_star = Sprite2D.new()
	star_viewer_sprite_star.texture = load("res://Images/star.png")
	star_viewer_sprite_star.scale = Vector2.ONE * 10
	star_viewer_sprite_star.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	viewport_planets.add_child(star_viewer_sprite_star)
	
	orbit_planets()
	

func clear_selected_star() -> void:
	if sel_star == null:
		return
		
	for p in sel_star.planets.size():
		sel_paths[p].curve.clear_points()
		sel_paths[p].curve = null
		sel_path_lines[p].visible = false
		sel_path_followers[p].remove_child(sel_star.planets[p])
		sel_star.planets[p].remove_child(sel_planet_areas[p])
		var callables = sel_planet_areas[p].mouse_entered.get_connections()
		for c in callables.size():
			sel_planet_areas[p].mouse_entered.disconnect(callables[c].callable)
		callables = sel_planet_areas[p].mouse_exited.get_connections()
		for c in callables.size():
			sel_planet_areas[p].mouse_exited.disconnect(callables[c].callable)
		
		
	star_viewer_sprite_star.queue_free()
	
	sel_star.deselect()
	sel_star = null
	spr_star_selected.visible = false
	
	
	

#endregion




#region PLANETS
func orbit_planets():
	while sel_star != null:
		for p in sel_star.planets.size():
			sel_path_followers[p].progress_ratio += sel_star.planets[p].orbital_velocity #TODO sel_path_followers[p] WILL SOMEDAY CAUSE A PROBLEM
			
		for f in sel_star.factories.size():
			var x = cos(time + sel_star.factories[f].orbital_position) * sel_star.factories[f].orbital_radius + 256
			var y = sin(time + sel_star.factories[f].orbital_position) * sel_star.factories[f].orbital_radius + 256
			sel_star.factories[f].position = Vector2(x,y)
			
			
		await get_tree().process_frame
		
		
func _hover_planet(pPlanet: Planet):
	pPlanet._on_hover()
	spr_planet_hover.visible = true
	spr_planet_hover.reparent(pPlanet, false)

func _exit_hover_planet(pPlanet: Planet):
	pPlanet._exit_hover()
	spr_planet_hover.visible = false
	
func set_selected_planet(pPlanet: Planet):
	if sel_planet != null:
		clear_selected_planet()
	info_name.text = "PLANET"
	info_texture.texture = pPlanet.texture
	info_lbl.text = "RESOURCE: " + str(pPlanet.resource)
	spr_planet_hover.visible = false
	spr_planet_selected.visible = true
	spr_planet_selected.reparent(pPlanet, false)
	pPlanet.select()
	
func clear_selected_planet():
	info_name.text = ""
	info_texture.texture = null
	info_lbl.text = ""
	spr_planet_selected.visible = false

func _try_select_planet(_viewport: Node, event: InputEvent, _shape_idx: int):
	if event.is_action_pressed("Click"):
		for p in sel_star.planets.size():
			if sel_star.planets[p].hover:
				set_selected_planet(sel_star.planets[p])


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



@export var split_container: HSplitContainer
var split_container_min = 200
var split_container_max = 1800
var split_container_dragging = false
func _on_h_split_container_2_drag_ended() -> void:
	split_container_dragging = false


func _on_h_split_container_2_drag_started() -> void:
	split_container_dragging = true
