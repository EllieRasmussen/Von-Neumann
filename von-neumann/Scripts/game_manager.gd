extends Node2D

const Cam = preload("res://Scripts/cam.gd")
const Star = preload("res://Scripts/star.gd")
const Planet = preload("res://Scripts/planet.gd")
const Factory = preload("res://Scripts/factory.gd")
const Extractor = preload("res://Scripts/extractor.gd")

var time: float

@export var cam_stars: Cam
@export var cam_planets: Camera2D

@export var viewport_stars: SubViewport
@export var viewport_planets: SubViewport

@export var UpgradeButton: Button
@export var UpgradeWindow: Window

@export var split_container: HSplitContainer

@export_group("Planet Info Window")
@export var window_planet_info: Window
@export var texture_planet_sprite: TextureRect
@export var lbl_planet_name: Label
@export var lbl_planet_resource_multiplier: Label
@export var lbl_planet_extractors: Label
@export var progbar_planet_next_extraction: ProgressBar
@export var progbar_planet_manual_extraction: ProgressBar

@export_group("Factory Info Window")
@export var window_factory_info: Window
@export var lbl_factory_name: Label

var stars: Array[Star] = []
var max_stars = 25
var max_planets_per_star = 10
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
	#GENERATE STARS + ADJACENCY
	for i in max_stars:
		create_star(Vector2((randf() * 1860) + 30, (randf() * 880) + 200))
	
	stars[0].create_factory()
	stars[0].create_extractor()
	for i in 9:
		stars[0].create_extractor()
	cam_stars.center(stars[0].position)
	
	Prim()
	time = 0
	set_hover_sprites()
	
	UpgradeButton.pressed.connect(toggle_upgrade_window)
	
	
func set_hover_sprites():
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


func _process(delta: float) -> void:
	time += delta
	
	if split_container_dragging:
		split_container.split_offset = clamp(split_container.split_offset,split_container_min,split_container_max)
		
	if sel_planet != null:
		progbar_planet_next_extraction.value = sel_planet.get_extraction_progress() * 100.0
		if manual_extract_tracker > 0.0:
			manual_extract_tracker -= delta * 5
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
	
	for p in sel_star.paths.size():
		viewport_planets.add_child(sel_star.paths[p])
	if sel_star.factory_path != null:
		viewport_planets.add_child(sel_star.factory_path)
	for e in sel_star.extractors.size():
		viewport_planets.add_child(sel_star.extractors[e])
	for c in sel_star.cargo.size():
		viewport_planets.add_child(sel_star.cargo[c])
	
	spr_star_selected.position = sel_star.position
	spr_star_selected.visible = true
	
	star_viewer_sprite_star = Sprite2D.new()
	star_viewer_sprite_star.texture = load("res://Images/star.png")
	star_viewer_sprite_star.scale = Vector2.ONE * 10
	star_viewer_sprite_star.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	viewport_planets.add_child(star_viewer_sprite_star)
	sel_star.update_followers()

func clear_selected_star() -> void:
	if sel_star == null:
		return
	
	for p in sel_star.followers.size():
		sel_star.followers[p].bank_progress()
	for p in sel_star.paths.size():
		viewport_planets.remove_child(sel_star.paths[p])
	if sel_star.factory_path != null:
		for f in sel_star.factory_followers.size():
			sel_star.factory_followers[f].bank_progress()
		viewport_planets.remove_child(sel_star.factory_path)
	for e in sel_star.extractors.size():
		viewport_planets.remove_child(sel_star.extractors[e])
	for c in sel_star.cargo.size():
		viewport_planets.remove_child(sel_star.cargo[c])
	
	
	star_viewer_sprite_star.queue_free()
	
	sel_star.deselect()
	sel_star = null
	spr_star_selected.visible = false

#endregion




#region PLANETS
func set_selected_planet(pPlanet: Planet) -> void:
	if sel_planet != null:
		clear_selected_planet()
	sel_planet = pPlanet
	window_planet_info.visible = true
	texture_planet_sprite.texture = pPlanet.texture
	lbl_planet_name.text = pPlanet.name
	lbl_planet_resource_multiplier.text = "RESOURCE: x" + ("%.2f" % pPlanet.resource)
	lbl_planet_extractors.text = "EXTRACTORS: " + str(pPlanet.extractors)
	
func clear_selected_planet() -> void:
	if sel_planet != null:
		sel_planet.set_selected(false)
		sel_planet = null
	
	texture_planet_sprite.texture = null
	lbl_planet_name.text = ""
	lbl_planet_resource_multiplier.text = ""
	lbl_planet_extractors.text = ""
	
	window_planet_info.visible = false
	

func set_selected_factory(pFactory: Factory) -> void:
	if sel_factory != null:
		clear_selected_factory()
	sel_factory = pFactory
	window_factory_info.visible = true
	lbl_factory_name.text = "FACTORY: " + sel_star.name

func clear_selected_factory() -> void:
	if sel_factory != null:
		sel_factory.set_selected(false)
		sel_factory = null
	lbl_factory_name.text = ""


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


#region UI

var split_container_min = 200
var split_container_max = 1800
var split_container_dragging = false
func _on_h_split_container_2_drag_ended() -> void:
	split_container_dragging = false


func _on_h_split_container_2_drag_started() -> void:
	split_container_dragging = true

func toggle_upgrade_window():
	UpgradeWindow.visible = !UpgradeWindow.visible;



func _on_planet_info_close_requested() -> void:
	window_planet_info.visible = false
	if sel_planet != null:
		sel_planet.deselect()

#endregion


var manual_extract_tracker: float = 0.0
func _on_btn_planet_manual_extracation_button_down() -> void:
	manual_extract_tracker += 5
	if manual_extract_tracker >= 100.0 and sel_planet != null:
		manual_extract_tracker -= 100
		sel_planet.extract_resource(1)


func _on_factory_info_close_requested() -> void:
	window_factory_info.visible = false
	if sel_factory != null:
		sel_factory.deselect()
