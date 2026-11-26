extends Node2D

const Cam = preload("res://Scripts/cam.gd")
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


var stars: Array[Star] = []

## 'SEL' = SELECTED
var sel_star: Star
var sel_factory: Factory

var num_points_per_orbit_line: int = 50
var factory_orbit_line: Line2D
var planet_orbit_lines: Array[Line2D]
var planet_sprites: Array[AnimatedSprite2D]
var planet_sprite_frames: SpriteFrames

func _ready() -> void:
	Globals.viewport_stars = viewport_stars
	Globals.split_container_offset_max = int(get_viewport_rect().size.x * 0.995)
	Globals.split_container_offset_star_viewer_open = int(get_viewport_rect().size.x * 0.8)
	Globals.split_container_offset_planet_viewer_open = int(get_viewport_rect().size.x * 0.3)
	
	star_gen()
	#for s in stars.size():
		#stars[s].create_factory()
	stars[0].create_factory()
	cam_stars.center(stars[0].position)
	
	
	for s in stars.size():
		viewport_stars.add_child(stars[s])
	
	factory_orbit_line = Line2D.new()
	factory_orbit_line.z_index = -1
	factory_orbit_line.closed = true
	factory_orbit_line.default_color = Color.SKY_BLUE
	factory_orbit_line.width = 25
	
	var angle = 0.0
	for point in num_points_per_orbit_line:
		var new_point = Vector2(
			cos(angle) * Globals.factory_orbital_radius,
			sin(angle) * Globals.factory_orbital_radius
		)
		factory_orbit_line.add_point(new_point)
		angle += 6.2832 / (num_points_per_orbit_line - 1)
	viewport_planets.add_child(factory_orbit_line)
	
	planet_sprite_frames = load("res://Images/planets/planets.tres")
	for p in Globals.max_planets_per_star:
		var new_line = Line2D.new()
		new_line.z_index = -10
		new_line.closed = true
		new_line.default_color = Color.DIM_GRAY
		new_line.width = 25
		planet_orbit_lines.append(new_line)
		viewport_planets.add_child(new_line)
		new_line.position = Vector2.ZERO
		
		var new_sprite = AnimatedSprite2D.new()
		new_sprite.sprite_frames = planet_sprite_frames
		new_sprite.scale = Vector2.ONE * 100
		planet_sprites.append(new_sprite)
		viewport_planets.add_child(new_sprite)
	
	stars[0].select()

func _process(_delta: float) -> void:
	for planet in panels_planet.keys():
		lines_planet_to_panel[planet].set_point_position(0,planet.position)
		lines_planet_to_panel[planet].set_point_position(1,panels_planet[planet].position)
	
	if sel_factory != null:
		line_factory_to_panel.set_point_position(0,sel_factory.position)
		line_factory_to_panel.set_point_position(1,panel_factory_info.position)
		
	if sel_star != null:
		for p in sel_star.planets.size():
			planet_sprites[p].position = sel_star.planets[p].position


#region STARS

var qt_root: Quad
func star_gen() -> void:
	qt_root = Quad.new()
	qt_root.set_quad(-Globals.world_bound*1.5,-Globals.world_bound*1.5,Globals.world_bound*3,0,qt_root)
	#GENERATE POINTS AND RADII FOR CLUSTERS
	var num_clusters: int = 10
	var cluster_positions: Array[Vector2]
	var cluster_radii: Array[float]
	while cluster_positions.size() < num_clusters:
		var clangle: float = randf() * 6.2831
		var dist: float = randf()*Globals.world_bound
		var new_pos: Vector2 = Vector2(cos(clangle)*dist,sin(clangle)*dist)
		var new_radius: float = randf_range(10000,20000)
		var has_overlap: bool = false
		for c in cluster_positions.size():
			if (new_radius*new_radius + cluster_radii[c]*cluster_radii[c]) > (cluster_positions[c] - new_pos).length_squared():
				has_overlap = true
		if cluster_positions.size() == 0 or not has_overlap:
			cluster_positions.append(new_pos)
			cluster_radii.append(new_radius)
		
	
	#GENERATE STARS AROUND EACH CLUSTER
	for c in num_clusters:
		var num_stars: int = 150
		var star_positions: Array[Vector2]
		while star_positions.size() < num_stars:
			var stangle: float = randf() * 6.2831
			var dist_to_cluster = randf() * cluster_radii[c]
			var new_pos: Vector2 = Vector2(cluster_positions[c] + Vector2(cos(stangle)*dist_to_cluster,sin(stangle)*dist_to_cluster))
			var has_overlap: bool = false
			for s in star_positions.size():
				if 300 > (star_positions[s] - new_pos).length():
					has_overlap = true
			if star_positions.size() == 0 or not has_overlap:
				star_positions.append(new_pos)
		for s in num_stars:
			qt_root.add_star(create_star(star_positions[s]),qt_root)
	
	#GENERATE ROGUE STARS
	var num_rogues: int = 100
	var rogue_positions: Array[Vector2]
	while rogue_positions.size() < num_rogues:
		var rangle: float = randf() * 6.2831
		var dist_from_center = randf() * Globals.world_bound
		var new_pos: Vector2 = Vector2(cos(rangle) * dist_from_center,sin(rangle)*dist_from_center)
		var is_in_cluster: bool = false
		for c in cluster_positions.size():
			if cluster_radii[c] * cluster_radii[c] > (cluster_positions[c] - new_pos).length_squared():
				is_in_cluster = true
		for r in rogue_positions.size():
			#90,000 = 300^2
			if 90000 > (rogue_positions[r] - new_pos).length_squared(): 
				is_in_cluster = true #TECHNICALLY SHOULD BE HAS_OVERLAP BUT I WOULD RATHER DIE THAN MAKE ONE MORE BOOLEAN
		if rogue_positions.size() == 0 or not is_in_cluster:
			rogue_positions.append(new_pos)
	for r in num_rogues:
		qt_root.add_star(create_star(rogue_positions[r]),qt_root)


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

func create_star(pPos: Vector2) -> Star:
	var s = Star.new()
	s.position = pPos
	
	s.star_selected.connect(set_selected_star.bind(s))
	
	s.set_sel_planet.connect(set_planet_selected)
	
	
	s.viewport_planets = viewport_planets
	s.game_manager = self
	
	stars.append(s)
	return s
	
func _on_sub_viewport_container_stars_gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("Click"):
		var mouse_position: Vector2 = cam_stars.get_global_mouse_position()
		var clicked_quad: Quad = qt_root.get_leaf_at(mouse_position)
		for s in clicked_quad.stars.size():
			var dist_to_mouse = (clicked_quad.stars[s].position - mouse_position).length_squared()
			if dist_to_mouse < 90000:
				clicked_quad.stars[s].select()
	if event is InputEventMouseMotion:
		var mouse_position: Vector2 = cam_stars.get_global_mouse_position()
		var mouse_quad: Quad = qt_root.get_leaf_at(mouse_position)
		for s in mouse_quad.stars.size():
			var dist_to_mouse = (mouse_quad.stars[s].position - mouse_position).length_squared()
			if dist_to_mouse < 5000:
				mouse_quad.stars[s]._on_hover()
			elif mouse_quad.stars[s].hover:
				mouse_quad.stars[s]._exit_hover()

func _on_sub_viewport_container_planets_gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("Click"):
		if sel_star != null:
			var mouse_position: Vector2 = cam_planets.get_global_mouse_position()
			for p in sel_star.planets.size():
				var dist_to_mouse = (sel_star.planets[p].position - mouse_position).length_squared()
				if dist_to_mouse < 900000:
					sel_star.planets[p].select()
		

func set_selected_star(pStar: Star) -> void:
	if sel_star != null:
		clear_selected_star()
	#cam_planets.position = Vector2.ZERO
	sel_star = pStar
	lbl_no_star_selected.visible = false
	star_viewer_sprite_star.visible = true
	
	for p in Globals.max_planets_per_star:
		if p >= pStar.planets.size():
			planet_orbit_lines[p].visible = false
			planet_sprites[p].visible = false
			continue
		
		planet_sprites[p].frame = sel_star.planets[p].sprite_frame
		planet_orbit_lines[p].clear_points()
		
		var t = 0.0
		for point in num_points_per_orbit_line:
			var new_point = Vector2(
				pStar.planets[p].orbital_radius_0 * cos(pStar.planets[p].orbital_angle) * cos(t) - pStar.planets[p].orbital_radius_1 * sin(pStar.planets[p].orbital_angle) * sin(t) + pStar.planets[p].orbital_focus.x,
				pStar.planets[p].orbital_radius_0 * sin(pStar.planets[p].orbital_angle) * cos(t) + pStar.planets[p].orbital_radius_1 * cos(pStar.planets[p].orbital_angle) * sin(t) + pStar.planets[p].orbital_focus.y
			)
			planet_orbit_lines[p].add_point(new_point)
			t += 6.2832 / (num_points_per_orbit_line - 1)
	
	if sel_star.factory != null:
		sel_star.factory.factory_selected.connect(set_selected_factory.bind(sel_star.factory))
		factory_orbit_line.visible = true
	
	if split_container.split_offset < Globals.split_container_offset_planet_viewer_open:
		lerp_split_container_offset(split_container.split_offset, Globals.split_container_offset_planet_viewer_open,0.15)

func clear_selected_star() -> void:
	if sel_star == null:
		return
	clear_selected_factory()
	for planet in panels_planet.keys():
		planet.deselect()
	lbl_no_star_selected.visible = true
	star_viewer_sprite_star.visible = false
	
	if sel_star.factory != null:
		sel_star.factory.factory_selected.disconnect(set_selected_factory)
		factory_orbit_line.visible = false
	
	sel_star.deselect()
	sel_star = null
	

#endregion

#region PLANETS
var panels_planet: Dictionary[Planet,FloatingPanelPlanet]
var lines_planet_to_panel: Dictionary[Planet,Line2D]
func set_planet_selected(pPlanet: Planet, pSelected: bool) -> void:
	pPlanet.set_selected(pSelected)
	if pSelected:
		var new_planet_panel: FloatingPanelPlanet = floating_panel_planet.instantiate()
		new_planet_panel.position = pPlanet.position + (pPlanet.position.normalized() * 10000)
		new_planet_panel.cam = cam_planets
		new_planet_panel.planet = pPlanet
		viewport_planets.add_child(new_planet_panel)
		panels_planet.set(pPlanet,new_planet_panel)
		panels_planet[pPlanet].texture_planet_sprite.texture = planet_sprite_frames.get_frame_texture("default",pPlanet.sprite_frame)
		
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
	panel_factory_info.closed.connect(clear_selected_factory)
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
