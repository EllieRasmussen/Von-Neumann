extends Node2D

const Cam = preload("res://Scripts/cam.gd")
const Star = preload("res://Scripts/star.gd")
const Planet = preload("res://Scripts/planet.gd")
const Factory = preload("res://Scripts/factory.gd")
const Extractor = preload("res://Scripts/extractor.gd")

@export var cam_stars: Cam
@export var cam_planets: Camera2D
@export var lbl_no_star_selected: Label

@export var viewport_stars: SubViewport
@export var viewport_planets: SubViewport

@export var UpgradeButton: Button
@export var UpgradeWindow: Window

@export var split_container: HSplitContainer

@export_group("Planet Info Window")
@export var window_planet_info: Window
@export var texture_planet_sprite: TextureRect
@export var lbl_planet_resource_multiplier: Label
@export var lbl_planet_extractors: Label
@export var progbar_planet_next_extraction: ProgressBar
@export var progbar_planet_manual_extraction: ProgressBar
@export var btn_manual_extraction: Button

@export_group("Factory Info Window")
@export var window_factory_info: Window
@export var lbl_factory_total_resource: Label
@export var btn_factory_make_extractors: Button
@export var btn_factory_make_probes: Button
@export var progbar_fund: ProgressBar
@export var progbar_next_extractor: ProgressBar
@export var lbl_progbar_next_extractor: Label
@export var progbar_next_probe: ProgressBar
@export var lbl_progbar_next_probe: Label


var stars: Array[Star] = []
var max_stars = 250

var max_factories_per_star = 10
var max_extractors_per_star = 1

## 'SEL' = SELECTED
var sel_star: Star
var sel_planet: Planet
var sel_factory: Factory

var spr_star_hover: Sprite2D
var spr_star_selected: Sprite2D

var star_viewer_sprite_star: Sprite2D #A WRETCHED LITTLE VARIABLE THAT I WOULD LIKE TO SOMEDAY KILL

var probe_travel_dist = 50 # LIGHTYEARS
var probe_replication_attempt_rate = 0.5 # ATTEMPTS PER SECOND
var probe_replication_success_rate = 0.1 # % CHANCE


func _ready() -> void:
	
	Globals.split_container_offset_max = int(get_viewport_rect().size.x * 0.995)
	Globals.split_container_offset_star_viewer_open = int(get_viewport_rect().size.x * 0.2)
	Globals.split_container_offset_planet_viewer_open = int(get_viewport_rect().size.x * 0.8)
	
	#GENERATE STARS + ADJACENCY
	var max_star_dist = 10000.0
	for i in max_stars:
		var star_pos = Vector2(
			randf_range(-max_star_dist,max_star_dist),
			randf_range(-max_star_dist,max_star_dist)
		)
		star_pos *= (star_pos.length_squared() / (max_star_dist*max_star_dist))
		if star_pos.length_squared() < max_star_dist * max_star_dist:
			create_star(star_pos)
		
	stars[0].create_factory()
	cam_stars.center(stars[0].position)
	
	for s in stars.size():
		viewport_stars.add_child(stars[s])
	
	spr_star_selected = Sprite2D.new()
	spr_star_selected.name = "spr_star_selected"
	spr_star_selected.texture = load("res://Images/circle_selected0.png")
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
	
	UpgradeButton.pressed.connect(toggle_upgrade_window)
	
	
	lbl_progbar_next_extractor.text = "0/" + str(Globals.resource_to_make_extractor)
	lbl_progbar_next_probe.text = "0/" + str(Globals.resource_to_make_probe)


func _process(delta: float) -> void:
	if sel_planet != null:
		progbar_planet_next_extraction.value = sel_planet.get_extraction_progress() * 100.0
		if manual_extract_tracker > 0.0:
			manual_extract_tracker -= delta * 7.5
		progbar_planet_manual_extraction.value = manual_extract_tracker
		


#region STARS

func create_star(pPos: Vector2):
	var s = Star.new()
	s.position = pPos
	
	s.star_hovered.connect(set_hovered_star.bind(s))
	s.star_dehovered.connect(clear_hovered_star)
	s.star_selected.connect(set_selected_star.bind(s))
	
	s.set_sel_planet.connect(set_selected_planet)
	s.desel_planet.connect(clear_selected_planet)
	
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
	clear_selected_star()
	#cam_planets.position = Vector2.ZERO
	sel_star = pStar
	lbl_no_star_selected.visible = false
	if not sel_star.active:
		for l in sel_star.adj_lines.size():
			viewport_stars.add_child(sel_star.adj_lines[l])
	
	if split_container.split_offset > Globals.split_container_offset_planet_viewer_open:
		lerp_split_container_offset(split_container.split_offset, Globals.split_container_offset_planet_viewer_open,0.15)
	
	spr_star_selected.position = sel_star.position
	spr_star_selected.visible = true
	
	star_viewer_sprite_star = Sprite2D.new()
	star_viewer_sprite_star.texture = load("res://Images/star.png")
	star_viewer_sprite_star.scale = Vector2.ONE * 10
	star_viewer_sprite_star.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	viewport_planets.add_child(star_viewer_sprite_star)

func clear_selected_star() -> void:
	if sel_star == null:
		return
	clear_selected_factory()
	clear_selected_planet()
	lbl_no_star_selected.visible = true
	
	if not sel_star.active:
		for l in sel_star.adj_lines.size():
			viewport_stars.remove_child(sel_star.adj_lines[l])
	
	
	star_viewer_sprite_star.queue_free()
	
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
func set_selected_planet(pPlanet: Planet) -> void:
	if sel_planet != null:
		clear_selected_planet()
	close_star_viewer()
	
	sel_planet = pPlanet
	window_planet_info.visible = true
	texture_planet_sprite.texture = pPlanet.sprite.texture
	window_planet_info.title = pPlanet.name
	btn_manual_extraction.disabled = sel_star == null or sel_star.factory == null
	sel_planet.added_extractor.connect(update_planet_window)
	update_planet_window()
	
func clear_selected_planet() -> void:
	if sel_planet != null:
		sel_planet.set_selected(false)
		sel_planet = null
	
	manual_extract_tracker = 0.0
	texture_planet_sprite.texture = null
	lbl_planet_resource_multiplier.text = ""
	lbl_planet_extractors.text = ""
	
	window_planet_info.visible = false
	
	
func update_planet_window() -> void:
	if sel_planet == null:
		return
	
	lbl_planet_resource_multiplier.text = "RESOURCE: x" + ("%.2f" % sel_planet.resource_multiplier)
	lbl_planet_extractors.text = "EXTRACTORS: " + str(sel_planet.extractors)
#endregion

@export var factory_window_sprite: TextureRect
#region FACTORIES
func set_selected_factory(pFactory: Factory) -> void:
	if sel_factory != null:
		clear_selected_factory()
	
	close_star_viewer()
	
	sel_factory = pFactory
	window_factory_info.visible = true
	update_factory_window()
	
	sel_factory.added_resource_to_main.connect(update_factory_resource_main)
	sel_factory.added_resource_to_next_extractor.connect(update_factory_resource_next_extractor)
	sel_factory.added_resource_to_next_probe.connect(update_factory_resource_next_probe)
	update_factory_resource_main(sel_factory.resource_pool_main)
	update_factory_resource_next_extractor(sel_factory.resource_pool_extractors)
	update_factory_resource_next_probe(sel_factory.resource_pool_probes)
	
	
	sel_star.update_funding_timer.connect(update_factory_fund_progbar)

func clear_selected_factory() -> void:
	if sel_factory != null:
		sel_factory.added_resource_to_main.disconnect(update_factory_resource_main)
		sel_factory.added_resource_to_next_extractor.disconnect(update_factory_resource_next_extractor)
		sel_factory.added_resource_to_next_probe.disconnect(update_factory_resource_next_probe)
		sel_factory.set_selected(false)
		sel_factory = null
	lbl_factory_total_resource.text = ""
	
	window_factory_info.visible = false
	

func update_factory_window() -> void:
	if sel_factory == null: 
		return
		
	btn_factory_make_extractors.button_pressed = sel_factory.making_extractors
	if sel_factory.making_extractors:
		btn_factory_make_extractors.text = "MAKING EXTRACTORS"
	else:
		btn_factory_make_extractors.text = "MAKE EXTRACTORS"
		
	btn_factory_make_probes.button_pressed = sel_factory.making_probes
	if sel_factory.making_probes:
		btn_factory_make_probes.text = "MAKING PROBES"
	else:
		btn_factory_make_probes.text = "MAKE PROBES"
	
	window_factory_info.title = "FACTORY AT " + sel_star.name
	lbl_factory_total_resource.text = "TOTAL RESOURCE: " + str(sel_factory.resource_pool_main)

func update_factory_resource_main(pResource: float) -> void:
	factory_window_sprite.texture = sel_factory.anim_sprite.sprite_frames.get_frame_texture("default",sel_factory.anim_sprite.frame)
	lbl_factory_total_resource.text = "TOTAL RESOURCE: " + str("%.2f" % pResource)
	
	
func update_factory_resource_next_extractor(pResource: float) -> void:
	lbl_progbar_next_extractor.text = str("%.2f" % pResource) + "/" + str(str("%.2f" % Globals.resource_to_make_extractor))
	progbar_next_extractor.max_value = Globals.resource_to_make_extractor
	progbar_next_extractor.value = pResource

func update_factory_resource_next_probe(pResource: float) -> void:
	lbl_progbar_next_probe.text = str("%.2f" % pResource) + "/" + str("%.2f" % Globals.resource_to_make_probe)
	progbar_next_probe.max_value = Globals.resource_to_make_probe
	progbar_next_probe.value = pResource

func update_factory_fund_progbar(pProgress: float) -> void:
	progbar_fund.max_value = Globals.factory_funding_interval
	progbar_fund.value = Globals.factory_funding_interval - pProgress
	






#endregion

#region UI

func _on_split_container_drag_ended() -> void:
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
	

func toggle_upgrade_window():
	UpgradeWindow.visible = !UpgradeWindow.visible;



func _on_planet_info_close_requested() -> void:
	window_planet_info.visible = false
	if sel_planet != null:
		sel_planet.deselect()
		
func _on_factory_info_close_requested() -> void:
	window_factory_info.visible = false
	if sel_factory != null:
		sel_factory.deselect()


var manual_extract_tracker: float = 0.0
func _on_btn_planet_manual_extracation_button_down() -> void:
	manual_extract_tracker += Globals.percentage_added_on_manual_extraction
	if manual_extract_tracker >= 100.0 and sel_planet != null:
		manual_extract_tracker -= 100
		sel_planet.extract_resource(1)



#endregion


func _on_btn_make_extractors_toggled(toggled_on: bool) -> void:
	if sel_factory != null:
		sel_factory.making_extractors = toggled_on
		update_factory_window()


func _on_btn_make_probes_toggled(toggled_on: bool) -> void:
	if sel_factory != null:
		sel_factory.making_probes = toggled_on
		update_factory_window()


func _on_area_2d_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if split_container.split_offset < Globals.split_container_offset_star_viewer_open:
				open_star_viewer()
