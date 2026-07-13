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

var stars: Array[Sprite2D] = []
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
	#if selected_star == pStar:
		#lbl_num_star_probes.text = "INTERSTELLAR PROBES:   " + str(pStar.star_probes) + " / " + str(pStar.max_star_probes)

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
		pStar.add_star_probes(num_probes_added)
		pStar.add_log(str("Replicated ",num_probes_added, " interstellar probes."))
	else:
		pStar.add_log(str("No interstellar probes replicated."))
		
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
		
