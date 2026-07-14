extends Node2D

const Star = preload("res://Scripts/star.gd")

@export var UI_contianer_root: Container
@export var star_viewer_root: Container
@export var viewport_star: SubViewport
@export var lbl_num_star_probes: Label
@export var lbl_star_probe_travel_dist: Label
@export var lbl_star_probe_replication_attempt_rate: Label
@export var lbl_star_probe_replication_success_rate: Label
@export var prgBar_add_interstellar_probe: ProgressBar

var stars: Array[Star] = []
var selected_star: Star

@export var star_activity_log_container: VBoxContainer
var star_activity_log = []

var star_probe_travel_dist = 50 # LIGHTYEARS
var star_probe_replication_attempt_rate = 0.20 # ATTEMPTS PER SECOND
var star_probe_replication_success_rate = 0.01 # % CHANCE

func _ready() -> void:	
	#GENERATE STARS + ADJACENCY
	for i in 25:
		create_star(Vector2((randf() * 780) + 30, (randf() * 1020) + 30))
	
	#POPULATE FIRST STAR WITH 1 INTERSTELLAR PROBE
	stars[0].add_star_probes(1)
	Prim()
	
	for l in 100:
		var label = Label.new()
		label.text = ""
		label.custom_minimum_size = Vector2(500,0)
		star_activity_log_container.add_child(label)
		star_activity_log.append(label)
		
	clear_selected_star(null)
	
func create_star(pPos: Vector2):
	var s = Star.new()
	s.position = pPos
	s.set_star_viewer_viewport(viewport_star)
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
	
func _process(delta: float) -> void:
	for s in stars.size():
		var dist_to_mouse = get_global_mouse_position().distance_squared_to(stars[s].position)
		if dist_to_mouse < 225:
			enter_hover_star(stars[s])
		elif stars[s].hover:
			exit_hover_star(stars[s])
	
	add_star_probe_val -= 0.01
	if add_star_probe_val < 0:
		add_star_probe_val = 0
	prgBar_add_interstellar_probe.value = add_star_probe_val
	
	queue_redraw()
			
func _draw(): 
	for s in stars.size():
		if stars[s].hover or stars[s].selected:
			draw_circle(stars[s].position, 15,Color.GREEN,false)
		if stars[s].star_probes > 0:
			draw_circle(stars[s].position, star_probe_travel_dist, Color.DIM_GRAY, false)

func enter_hover_star(pStar: Star) -> void:
	pStar._on_hover()
	
func exit_hover_star(pStar: Star) -> void:
	pStar._exit_hover()

func set_selected_star(pStar: Star) -> void:
	selected_star = pStar
	update_star_probe_count_label(pStar)
	load_activity_log(pStar)
	star_viewer_root.visible = true

func clear_selected_star(pStar: Star) -> void:
	if selected_star == pStar:
		selected_star = null
	if selected_star == null:
		star_viewer_root.visible = false 

func update_star_probe_count_label(pStar: Star):
	lbl_num_star_probes.text = "INTERSTELLAR PROBES:   " + str(pStar.star_probes) + " / " + str(pStar.max_star_probes)

func attempt_star_probe_replication(pStar: Star):
	var rnd = RandomNumberGenerator.new()
	var num_probes_added = 0
	var num_star_probes = pStar.star_probes
	pStar.add_log(str("Attempting to replicate ",pStar.star_probes," interstellar probes at ", star_probe_replication_success_rate, " success rate."))
	for i in pStar.star_probes:
		var randNum = rnd.randf()
		if randNum <= star_probe_replication_success_rate:
			num_probes_added += 1
		rnd.seed = randNum
	if num_probes_added > 0:
		if pStar.star_probes + num_probes_added > pStar.max_star_probes:
			var stars_to_add = pStar.max_star_probes - pStar.star_probes
			pStar.add_star_probes(stars_to_add)
			send_probes_to_star(num_probes_added - stars_to_add)
		pStar.add_star_probes(num_probes_added)
		pStar.add_log(str("Replicated ",num_probes_added, " interstellar probes."))
	else:
		pStar.add_log(str("No interstellar probes replicated."))
		
		
		
func send_probes_to_star(pStar: Star) -> void:
	pass
	
	
	
func load_activity_log(pStar: Star):
	if pStar == selected_star:
		for l in pStar.activity_log.size():
			star_activity_log[l].text = pStar.activity_log[l]
		
func clear_activity_log():
	for l in star_activity_log.size():
		star_activity_log[l].text = ""
	

#INTERSTELLAR PROBES AT STARS DUPLICATE AND SEND COPY TO NEAREST NEIGHBOR

#INTERSTELLAR PROBES AT STARS PRODUCE PLANETARY PROBES

#PLANETARY PROBES TRAVEL TO NEAREST UNPOPULATED PLANET

#IF ALL PLANETS ARE POPULATED, PLANETARY PROBES TRAVEL TO LEAST-POPULATED PLANET

func _on_tab_container_tab_selected(tab: int) -> void:
	if tab == 1:
		lbl_star_probe_travel_dist.text = str(star_probe_travel_dist) + " LIGHTYEARS"
		lbl_star_probe_replication_attempt_rate.text = str(star_probe_replication_attempt_rate) + " / SECOND"
		lbl_star_probe_replication_success_rate.text = str(star_probe_replication_success_rate * 100) + "%"


var add_star_probe_val = 0
func _on_btn_replicate_probe_button_down() -> void:
	if selected_star.star_probes == 0:
		return
	add_star_probe_val += 3
	prgBar_add_interstellar_probe.value = add_star_probe_val
	if add_star_probe_val >= 100:
		selected_star.add_star_probes(1)
		add_star_probe_val = 0
		selected_star.add_log("Manually replicated 1 star")
		










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




















func Island_Killer_9000() -> void:
	var networks = [[]]
	networks.append([])
	networks.append([])
	#RUN THROUGH EVERY STAR
	for current_star in stars.size():
		var adjacent_stars = []
		#FIND ALL STARS WITHIN SOME RANGE
		for adjacent_star in stars.size():
			var dist = stars[current_star].position.distance_squared_to(stars[adjacent_star].position)
			if dist > 0 and dist < 500:
				adjacent_stars.append(stars[adjacent_star])
		#FOR EACH STAR WITHIN RANGE
		for a in adjacent_stars.size():
			#ADD ADJACENCY WITH CURRENT STAR
			stars[current_star].add_adjacent(adjacent_stars[a])
			var n0 = 0
			var n1 = 0
			while n0 < networks.size():
				while n1 < networks.size():
					if n0 == n1:
						continue
					print(networks.size())
					var n0_has_current = networks[n0].has(stars[current_star])
					var n1_has_current = networks[n1].has(stars[current_star])
					var n0_has_adj = networks[n0].has(adjacent_stars[a])
					var n1_has_adj = networks[n1].has(adjacent_stars[a])
					#CHECK IF CURRENT STAR AND ADJACENT STAR ARE IN TWO DIFFERENT NETWORKS
					if (n0_has_current and n1_has_adj) or (n1_has_current and n0_has_adj):
						#IF TRUE, COMBINE THOSE NETWORKS
						for s in range(networks[n1].size()-1,-1,-1):
							networks[n0].append(adjacent_stars[s])
							networks[n1].remove_at(s)
						
					#ELSE, CHECK IF ANY EXISTING NETWORK CONTAINS EITHER STAR
						#IF TRUE, ADD OTHER STAR TO THAT NETWORK
					elif n0_has_current:
						networks[n0].append(adjacent_stars[a])
					elif n1_has_current:
						networks[n1].append(adjacent_stars[a])
					elif n0_has_adj:
						networks[n0].append(stars[current_star])
					elif n1_has_adj:
						networks[n1].append(stars[current_star])
					else:
						#ADD BOTH STARS TO NEW NETWORK
						var new_network = []
						new_network.append(stars[current_star])
						new_network.append(adjacent_stars[a])
						networks.append(new_network)
					n1 += 1
				n0 += 1
	#CULL ALL BUT LARGEST NETWORK
	var largest_network_index = 0
	var largest_network_size = 0
	for n in networks.size():
		if networks[n].size() > largest_network_size:
			largest_network_size = networks[n].size()
			largest_network_index = n
	for n in networks.size():
		if n == largest_network_index:
			continue
		for s in networks[n].size():
			networks[n][s].free()
			
	for s in range(stars.size()-1,-1,-1):
		if not networks[largest_network_index].has(stars[s]):
			stars[s].queue_free()
