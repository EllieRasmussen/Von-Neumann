extends Node2D

const Star = preload("res://Scripts/star.gd")
const Planet = preload("res://Scripts/planet.gd")

@export var star_viewer_viewport: SubViewport

var stars: Array[Star] = []
var selected_star: Star
var selected_star_planets: Array[Planet]

var probe_travel_dist = 50 # LIGHTYEARS
var probe_replication_attempt_rate = 0.5 # ATTEMPTS PER SECOND
var probe_replication_success_rate = 0.1 # % CHANCE

func _ready() -> void:	
	#GENERATE STARS + ADJACENCY
	for i in 25:
		create_star(Vector2((randf() * 780) + 30, (randf() * 1020) + 30))
	
	#POPULATE FIRST STAR WITH 1 INTERSTELLAR PROBE
	stars[0].add_star_probes(1)
	Prim()
		
	clear_selected_star(null)
	

func create_star(pPos: Vector2):
	var s = Star.new()
	s.position = pPos
	s.set_star_viewer_viewport(star_viewer_viewport)
	s.set_star_interstellar_probes_label(lbl_num_star_probes)
	
	s.star_probe_replicate_attempt.connect(attempt_star_probe_replication.bind(s))
	s.star_selected.connect(load_activity_log.bind(s))
	s.star_selected.connect(set_selected_star.bind(s))
	s.star_deselected.connect(clear_selected_star.bind(s))
	s.log_added.connect(load_activity_log.bind(s))
	s.star_probe_count_changed.connect(update_star_probe_count_label.bind(s))
	
	s.set_replication_rate(star_probe_replication_attempt_rate)
	stars.append(s)
	add_child(s)


##EDITED FROM VERSION IN game2.gd, MAY NEED REWORKING ONCE TESTED
func set_selected_star(pStar: Star) -> void:
	selected_star = pStar
	update_star_probe_count_label(pStar)
	load_activity_log(pStar)

##EDITED FROM VERSION IN game2.gd, MAY NEED REWORKING ONCE TESTED
func clear_selected_star(pStar: Star) -> void:
	selected_star = null
	for p in range(selected_star_planets.size(),-1,-1):
		remove_child(selected_star_planets[p])
	if selected_star == null:
		pass
		#star_viewer_root.visible = false 




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
