extends Node2D

const Cam = preload("res://Scripts/cam.gd")
const Star = preload("res://Scripts/star.gd")
const Extractor = preload("res://Scripts/extractor.gd")
const SlidingPanel = preload("res://Scripts/sliding_panel.gd")
const floating_panel_factory: PackedScene = preload("res://Scenes/floating_panel_factory.tscn")
const floating_panel_planet: PackedScene = preload("res://Scenes/floating_panel_planet.tscn")

@export var cam_stars: Cam
@export var cam_planets: Cam
@export var lbl_no_star_selected: Label

@export var viewport_stars: SubViewport
@export var viewport_planets: SubViewport

@export var split_container: HSplitContainer
@export var star_viewer_sprite_star: Sprite2D #A WRETCHED LITTLE VARIABLE THAT I WOULD LIKE TO SOMEDAY KILL

@export var panel_factory_planet: SlidingPanel


var stars: Array[Star] = []
var max_stars = 250

var max_factories_per_star = 10
var max_extractors_per_star = 1

## 'SEL' = SELECTED
var sel_star: Star
var sel_factory: Factory

var spr_star_hover: Sprite2D
var spr_star_selected: Sprite2D



var probe_travel_dist = 50 # LIGHTYEARS
var probe_replication_attempt_rate = 0.5 # ATTEMPTS PER SECOND
var probe_replication_success_rate = 0.1 # % CHANCE


func _ready() -> void:
	
	Globals.split_container_offset_max = int(get_viewport_rect().size.x * 0.995)
	Globals.split_container_offset_star_viewer_open = int(get_viewport_rect().size.x * 0.8)
	Globals.split_container_offset_planet_viewer_open = int(get_viewport_rect().size.x * 0.3)
	
	#GENERATE STARS + ADJACENCY
	var max_star_dist = 10000.0
	for i in max_stars:
		var star_pos = Vector2(
			randf_range(-max_star_dist,max_star_dist),
			randf_range(-max_star_dist,max_star_dist)
		)
		#star_pos *= (star_pos.length_squared() / (max_star_dist*max_star_dist))
		if star_pos.length_squared() < max_star_dist * max_star_dist:
			create_star(star_pos)
	
	stars[0].create_factory()
	cam_stars.center(stars[0].position)
	
	
	for s in stars.size():
		viewport_stars.add_child(stars[s])
	
	spr_star_selected = Sprite2D.new()
	spr_star_selected.name = "spr_star_selected"
	spr_star_selected.texture = load("res://Images/circle_selected0.png")
	spr_star_selected.scale = Vector2.ONE * 5
	spr_star_selected.z_index = 1
	spr_star_selected.visible = false
	viewport_stars.add_child(spr_star_selected)
	
	spr_star_hover = Sprite2D.new()
	spr_star_hover.name = "spr_star_hover"
	spr_star_hover.texture = load("res://Images/circle_hover.png")
	spr_star_hover.scale = Vector2.ONE * 5
	spr_star_hover.z_index = 2
	spr_star_hover.visible = false
	viewport_stars.add_child(spr_star_hover)

	stars[0].select()
	
	
func _process(_delta: float) -> void:
	for planet in panels_planet.keys():
		lines_planet_to_panel[planet].set_point_position(0,planet.position)
		lines_planet_to_panel[planet].set_point_position(1,panels_planet[planet].position)
	
	if sel_factory != null:
		line_factory_to_panel.set_point_position(0,sel_factory.position)
		line_factory_to_panel.set_point_position(1,panel_factory_info.position)


#region STARS

func star_gen() -> void:
	var world_bounds: Vector2 = Vector2(10000,10000)
	
	#GENERATE POINTS AND RADII FOR CLUSTERS
	var cluster_positions: Array[Vector2]
	var cluster_radii: Array[float]
	for i in 10:
		cluster_positions.append(Vector2(randf_range(-world_bounds.x,world_bounds.x),randf_range(-world_bounds.y,world_bounds.y)))
		cluster_radii.append(randf_range(500,1500))
		var pos_marker: Sprite2D = Sprite2D.new()
		pos_marker.texture = load("res://Images/star.png")
		viewport_stars.add_child(pos_marker)
		pos_marker.position = cluster_positions[i]
		
	
	#GENERATE STARS AROUND EACH CLUSTER
	
	#PRIM CLUSTERS
	
	#GENERATE HALLWAYS BETWEEN CLUSTERS
	
	pass

func create_star(pPos: Vector2):
	var s = Star.new()
	s.position = pPos
	
	s.star_hovered.connect(set_hovered_star.bind(s))
	s.star_dehovered.connect(clear_hovered_star)
	s.star_selected.connect(set_selected_star.bind(s))
	
	s.set_sel_planet.connect(set_planet_selected)
	
	s.set_sel_factory.connect(set_selected_factory)
	s.desel_factory.connect(clear_selected_factory)
	
	s.viewport_planets = viewport_planets
	s.game_manager = self
	
	stars.append(s)

func set_hovered_star(pStar: Star) -> void:
	spr_star_hover.position = pStar.position
	spr_star_hover.visible = true
	
func clear_hovered_star() -> void:
	spr_star_hover.visible = false

func set_selected_star(pStar: Star) -> void:
	if sel_star != null:
		clear_selected_star()
	#cam_planets.position = Vector2.ZERO
	sel_star = pStar
	lbl_no_star_selected.visible = false
	star_viewer_sprite_star.visible = true
	
	if not sel_star.active:
		for l in sel_star.adj_lines.size():
			viewport_stars.add_child(sel_star.adj_lines[l])
	
	if split_container.split_offset < Globals.split_container_offset_planet_viewer_open:
		lerp_split_container_offset(split_container.split_offset, Globals.split_container_offset_planet_viewer_open,0.15)
	
	spr_star_selected.position = sel_star.position
	spr_star_selected.visible = true
	

func clear_selected_star() -> void:
	if sel_star == null:
		return
	clear_selected_factory()
	for planet in panels_planet.keys():
		planet.deselect()
	lbl_no_star_selected.visible = true
	star_viewer_sprite_star.visible = false
	
	if not sel_star.active:
		for l in sel_star.adj_lines.size():
			viewport_stars.remove_child(sel_star.adj_lines[l])
	
	sel_star.deselect()
	sel_star = null
	spr_star_selected.visible = false
	

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
		star0.add_adjacent(star1,null)

#endregion

#region PLANETS
var panels_planet: Dictionary
var lines_planet_to_panel: Dictionary
func set_planet_selected(pPlanet: Planet, pSelected: bool) -> void:
	pPlanet.set_selected(pSelected)
	if pSelected:
		var new_planet_panel: FloatingPanelPlanet = floating_panel_planet.instantiate()
		new_planet_panel.position = pPlanet.position + (pPlanet.position.normalized() * 10000)
		new_planet_panel.cam = cam_planets
		new_planet_panel.planet = pPlanet
		viewport_planets.add_child(new_planet_panel)
		panels_planet.set(pPlanet,new_planet_panel)
		
		var new_line: Line2D = Line2D.new()
		new_line.z_index = -10
		new_line.default_color = Color.DIM_GRAY
		new_line.width = 100
		new_line.add_point(pPlanet.position)
		new_line.add_point(new_planet_panel.position)
		
		viewport_planets.add_child(new_line)
		lines_planet_to_panel.set(pPlanet,new_line)
	else:
		panels_planet[pPlanet].queue_free()
		panels_planet.erase(pPlanet)
		
		lines_planet_to_panel[pPlanet].queue_free()
		lines_planet_to_panel.erase(pPlanet)

#endregion


var panel_factory_info: FloatingPanelFactory
var line_factory_to_panel: Line2D # I HATE THAT THIS IS HERE AS MUCH AS YOU DO BUT STUPID LINES STUPID SCALE WITH THEIR STUPID PARENTS SO IT HAS TO GO HERE
#region FACTORIES
func set_selected_factory(pFactory: Factory) -> void:
	if sel_factory != null:
		clear_selected_factory()
	
	sel_factory = pFactory
	
	
	panel_factory_info = floating_panel_factory.instantiate()
	panel_factory_info.cam = cam_planets
	panel_factory_info.closed.connect(sel_factory.deselect)
	viewport_planets.add_child(panel_factory_info)
	panel_factory_info.position = sel_factory.position + (sel_factory.position.normalized() * 10000)
	panel_factory_info.target = sel_factory
	
	line_factory_to_panel = Line2D.new()
	line_factory_to_panel.z_index = -10
	line_factory_to_panel.default_color = Color.DIM_GRAY
	line_factory_to_panel.width = 100
	line_factory_to_panel.add_point(sel_factory.position)
	line_factory_to_panel.add_point(panel_factory_info.position)
	
	viewport_planets.add_child(line_factory_to_panel)
	panel_factory_info.factory = sel_factory
	
	

func clear_selected_factory() -> void:
	if sel_factory != null:
		sel_factory.set_selected(false)
		sel_factory = null
	
	if panel_factory_info != null:
		panel_factory_info.queue_free()
		line_factory_to_panel.queue_free()

#endregion

#region UI

var split_container_dragging: bool = false
func _on_split_container_drag_started() -> void:
	split_container_dragging = true
	
func _on_split_container_drag_ended() -> void:
	split_container_dragging = false
	split_container.split_offset = clamp(split_container.split_offset, Globals.split_container_offset_min, Globals.split_container_offset_max)

func open_planet_viewer() -> void:
	lerp_split_container_offset(split_container.split_offset,Globals.split_container_offset_planet_viewer_open,0.15)
func close_planet_viewer() -> void:
	lerp_split_container_offset(split_container.split_offset, Globals.split_container_offset_max,0.15)
	
func open_star_viewer() -> void:
	lerp_split_container_offset(split_container.split_offset,Globals.split_container_offset_star_viewer_open,0.15)
func close_star_viewer() -> void:
	lerp_split_container_offset(split_container.split_offset, Globals.split_container_offset_min,0.15)
	
func lerp_split_container_offset(pFrom: float, pTo: float, pDuration: float = 1.0) -> void:
	var timer = 0.0
	while timer <= pDuration:
		timer += Globals.deltaTime
		split_container.split_offset = lerp(pFrom,pTo,lerpf(0.0,1.0,timer/pDuration))
		await Engine.get_main_loop().process_frame
	

#endregion


func _on_area_2d_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if split_container.split_offset < Globals.split_container_offset_star_viewer_open:
				open_star_viewer()


@export var btn_show_hostility: Button
var show_hostility: bool = false
func _on_btn_show_hostility_button_down() -> void:
	show_hostility = not show_hostility
	for s in stars.size():
		stars[s].hostility_label.visible = show_hostility
	if show_hostility:
		btn_show_hostility.text = "Hide Star Hostility"
	else:
		btn_show_hostility.text = "Show Star Hostility"
