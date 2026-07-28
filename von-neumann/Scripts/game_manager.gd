extends Node2D

const Star = preload("res://Scripts/star.gd")
const Planet = preload("res://Scripts/planet.gd")

var time: float

@export var window_star_viewer: Window
@export var window_upgrades: Window

@export var btn_star_viewer_window: Button
@export var btn_upgrades_window: Button

@export var star_viewer_viewport: SubViewport

var stars: Array[Star] = []
var selected_star: Star
var selected_star_planets: Array[Planet]

var star_viewer_sprite_star: Sprite2D #A WRETCHED LITTLE VARIABLE THAT I WOULD LIKE TO SOMEDAY KILL

var probe_travel_dist = 50 # LIGHTYEARS
var probe_replication_attempt_rate = 0.5 # ATTEMPTS PER SECOND
var probe_replication_success_rate = 0.1 # % CHANCE

func _ready() -> void:	
	#GENERATE STARS + ADJACENCY
	for i in 25:
		create_star(Vector2((randf() * 1860) + 30, (randf() * 880) + 200))
	
	#POPULATE FIRST STAR WITH 1 INTERSTELLAR PROBE
	stars[0].add_star_probes(1)
	Prim()
	
	time = 0
	
	
func _process(delta: float) -> void:
	time += delta
	
	var mouse_pos = get_global_mouse_position()
	for s in stars.size():
		if mouse_pos.distance_squared_to(stars[s].position) < 350:
			stars[s]._on_hover()
		elif stars[s].hover:
			stars[s]._exit_hover()
	
	if selected_star != null:
		for p in selected_star_planets.size():
			var dist_to_mouse = star_viewer_viewport.get_mouse_position().distance_squared_to(selected_star_planets[p].position)
			if dist_to_mouse < 300 and not selected_star_planets[p].hover:
				selected_star_planets[p].on_hover()
			elif selected_star_planets[p].hover:
				selected_star_planets[p].exit_hover()
	
	if Input.is_action_just_pressed("Click"):
		for s in stars.size():
			if stars[s].hover:
				stars[s].select()


#region STARS

func create_star(pPos: Vector2):
	var s = Star.new()
	s.position = pPos
	s.star_selected.connect(set_selected_star.bind(s))
	
	stars.append(s)
	add_child(s)


##EDITED FROM VERSION IN game2.gd, MAY NEED REWORKING ONCE TESTED
func set_selected_star(pStar: Star) -> void:
	if selected_star != null:
		clear_selected_star()
	selected_star = pStar
	selected_star_planets = pStar.planets
	open_star_viewer()
	orbit_planets()
	

##EDITED FROM VERSION IN game2.gd, MAY NEED REWORKING ONCE TESTED
func clear_selected_star() -> void:
	close_star_viewer()
	selected_star.deselect()
	selected_star = null
	selected_star_planets = []
	

#endregion




#region PLANETS
func orbit_planets():
	while selected_star != null:
		for p in selected_star_planets.size():
			var x = cos(time + selected_star_planets[p].orbital_offset) * selected_star_planets[p].orbital_radius + 256
			var y = sin(time + selected_star_planets[p].orbital_offset) * selected_star_planets[p].orbital_radius + 256
			selected_star_planets[p].position = Vector2(x,y)
			selected_star_planets[p].rotate(selected_star_planets[p].rotational_velocity)
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
	window_star_viewer.visible = true
	btn_star_viewer_window.disabled = true
	if selected_star == null:
		#HANDLE OPENING WITHOUT A SELECTED STAR
		pass
	else:
		#LOAD STAR INTO STAR VIEWER
		star_viewer_sprite_star = Sprite2D.new()
		star_viewer_sprite_star.scale = Vector2(0.3,0.3)
		star_viewer_sprite_star.texture = load("res://Images/star.png")
		star_viewer_viewport.add_child(star_viewer_sprite_star)
		star_viewer_sprite_star.position = Vector2(256,256)
		
		for p in selected_star_planets.size():
			star_viewer_viewport.add_child(selected_star_planets[p])


func close_star_viewer() -> void:
	window_star_viewer.visible = false
	btn_star_viewer_window.disabled = false
	if selected_star == null:
		#HANDLE CLOSING WITHOUT A SELECTED STAR
		pass
	else:
		#CLEAR STAR FROM STAR VIEWER
		star_viewer_sprite_star.queue_free()
		
		for p in selected_star_planets.size():
			star_viewer_viewport.remove_child(selected_star_planets[p])

func _on_btn_star_viewer_pressed() -> void:
	if window_star_viewer.visible:
		close_star_viewer()
	else:
		open_star_viewer()


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
