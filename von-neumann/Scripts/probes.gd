extends Node2D

const Star = preload("res://Scripts/star.gd")
@export var star_viewer_viewport: SubViewport
@export var lbl_star_viewer_probe: Label

@export var lbl_interstellar_probe_travel_dist: Label
@export var lbl_interstellar_probe_replication_attempt_rate: Label
@export var lbl_interstellar_probe_replication_chance: Label

var stars: Array[Sprite2D] = []

var interstellar_probe_travel_dist = 10
var interstellar_probe_replication_attempt_rate = 0.25
var interstellar_probe_replication_chance = 0.1

func _ready() -> void:
	#GENERATE STARS + ADJACENCY
	for i in 10:
		var s = Star.new()
		s.position = Vector2((randf() * 780) + 30, (randf() * 1020) + 30)
		s.set_star_viewer_viewport(star_viewer_viewport)
		s.set_star_interstellar_probes_label(lbl_star_viewer_probe)
		s.interstellar_probe_replicate_attempt.connect(attempt_interstellar_probe_replication.bind(s))
		s.set_replication_rate(interstellar_probe_replication_attempt_rate)
		stars.append(s)
		add_child(s)
		
	for i in stars.size():
		for j in stars.size():
			var dist_between = stars[i].position.distance_squared_to(stars[j].position)
			if stars[i] != stars[j] and dist_between < 100000:
				stars[i].add_adjacent(stars[j])
	
	#POPULATE FIRST STAR WITH 1 INTERSTELLAR PROBE
	stars[0].add_interstellar_probes(1)
	
func _process(delta: float) -> void:
	for s in stars.size():
		var dist_to_mouse = get_global_mouse_position().distance_squared_to(stars[s].position)
		if dist_to_mouse < 225:
			enter_hover_star(stars[s])
		elif stars[s].hover:
			exit_hover_star(stars[s])
	
	queue_redraw()
			
func _draw(): 
	for s in stars.size():
		if stars[s].hover or stars[s].selected:
			draw_circle(stars[s].position, 15,Color.GREEN,false)
		if stars[s].interstellar_probes > 0:
			draw_circle(stars[s].position, interstellar_probe_travel_dist, Color.DIM_GRAY, false)

func enter_hover_star(pStar: Star) -> void:
	pStar._on_hover()
	
func exit_hover_star(pStar: Star) -> void:
	pStar._exit_hover()

func attempt_interstellar_probe_replication(pStar: Star):
	var rnd = RandomNumberGenerator.new()
	var num_probes_added = 0
	print("attempting to replicate ", pStar.interstellar_probes, " probes...")
	for i in pStar.interstellar_probes:
		var randNum = rnd.randf()
		print(randNum," VS ", interstellar_probe_replication_chance)
		if randNum <= interstellar_probe_replication_chance:
			num_probes_added += 1
			print("REPLICATED")
		rnd.seed = randNum * 100000
	if num_probes_added > 0:
		pStar.add_interstellar_probes(num_probes_added)
	for i in 3:
		print()

#INTERSTELLAR PROBES AT STARS DUPLICATE AND SEND COPY TO NEAREST NEIGHBOR

#INTERSTELLAR PROBES AT STARS PRODUCE PLANETARY PROBES

#PLANETARY PROBES TRAVEL TO NEAREST UNPOPULATED PLANET

#IF ALL PLANETS ARE POPULATED, PLANETARY PROBES TRAVEL TO LEAST-POPULATED PLANET

func _on_tab_container_tab_selected(tab: int) -> void:
	if tab == 1:
		lbl_interstellar_probe_travel_dist.text = str(interstellar_probe_travel_dist) + " LIGHTYEARS"
		lbl_interstellar_probe_replication_attempt_rate.text = str(interstellar_probe_replication_attempt_rate) + " / SECOND"
		lbl_interstellar_probe_replication_chance.text = str(interstellar_probe_replication_chance * 100) + "%"
