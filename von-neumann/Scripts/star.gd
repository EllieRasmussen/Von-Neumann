extends Sprite2D

const Star = preload("res://Scripts/star.gd")
const Planet = preload("res://Scripts/planet.gd")
const ProgBar = preload("res://Scripts/prog_bar.gd")
const Probe = preload("res://Scripts/probe.gd")

var time: float

var star_viewer_img: Sprite2D
var planets: Array[Planet]

var star_probes = 0
var max_star_probes = 100
var travelling_star_probes = []

var viewport_star: SubViewport
var lbl_star_probes: Label

var bar_total_star_probes: ProgBar
var bar_next_star_probe: ProgBar
var time_since_last_star_probe: float
var time_per_star_probe_replication: float

var activity_log = []

signal star_selected
signal star_deselected
signal log_added
signal star_probe_replicate_attempt
signal star_probe_count_changed

var selected = false
var hover = false
var spr_selected
var spr_hover

var adj = []


func set_star_viewer_viewport(pViewport) -> void:
	viewport_star = pViewport
	
func set_star_interstellar_probes_label(pLabel) -> void:
	lbl_star_probes = pLabel

func _ready() -> void:
	time = 0
	time_since_last_star_probe = 0
	
	#SET TEXTURE
	var star_imgs = []
	star_imgs.append(load("res://Images/Star_0.png"))
	star_imgs.append(load("res://Images/Star_1.png"))
	star_imgs.append(load("res://Images/Star_2.png"))
	star_imgs.append(load("res://Images/Star_3.png"))
	self.texture = star_imgs[randi()%len(star_imgs)]
	
	spr_selected = Sprite2D.new()
	spr_selected.texture = load("res://Images/circle_selected.png")
	spr_selected.scale = Vector2.ONE * 0.25
	spr_selected.z_index = -1
	spr_selected.visible = false
	add_child(spr_selected)
	
	spr_hover = Sprite2D.new()
	spr_hover.texture = load("res://Images/circle_hover.png")
	spr_hover.scale = Vector2.ONE * 0.25
	spr_hover.z_index = -2
	spr_hover.visible = false
	add_child(spr_hover)
	
	star_viewer_img = Sprite2D.new()
	star_viewer_img.scale = Vector2(0.3,0.3)
	star_viewer_img.texture = load("res://Images/star.png")
	viewport_star.add_child(star_viewer_img)
	star_viewer_img.position = Vector2(375,375)
	star_viewer_img.visible = false
	
	var num_planets = randi_range(1,5)
	for i in num_planets:
		var p = Planet.new()
		p.centered = true
		p.visible = false
		p.scale = Vector2(0.05,0.05)
		planets.append(p)
		
	bar_total_star_probes = ProgBar.new()
	add_child(bar_total_star_probes)
	bar_total_star_probes.position = Vector2(-25,15)
	bar_total_star_probes.set_bar_width(5)
	bar_total_star_probes.set_bar_length(50)
	bar_total_star_probes.set_bg_color(Color.SLATE_GRAY)
	bar_total_star_probes.set_fg_color(Color.BLUE)
	bar_total_star_probes.set_value(star_probes)
	bar_total_star_probes.set_max_value(max_star_probes)
	
	
	bar_next_star_probe = ProgBar.new()
	add_child(bar_next_star_probe)
	bar_next_star_probe.position = Vector2(-25,20)
	bar_next_star_probe.set_bar_width(2)
	bar_next_star_probe.set_bar_length(50)
	bar_next_star_probe.set_bg_color(Color.DARK_SLATE_GRAY)
	bar_next_star_probe.set_fg_color(Color.AQUA)
	bar_next_star_probe.set_value(0)
	bar_next_star_probe.set_max_value(time_per_star_probe_replication)
	
	if star_probes == 0:
		bar_total_star_probes.visible = false
		bar_next_star_probe.visible = false

func _process(delta: float) -> void:
	time += delta
	planet_time += delta
	if Input.is_action_just_pressed("Click") and get_global_mouse_position().x < 840:
		if hover and not selected:
			select()
		elif not hover and selected:
			deselect()
			
	handle_interstellar_probe_replication(delta)
	
	for t in travelling_star_probes.size():
		var at_destination = travelling_star_probes[t].process_travel(delta)
		if at_destination:
			travelling_star_probes[t].queue_free()
			travelling_star_probes.remove_at(t)
	
	if hover and not spr_hover.visible:
		spr_hover.visible = true
	elif not hover and spr_hover.visible:
		spr_hover.visible = false
	
	if selected:
		if not spr_selected.visible:
			spr_selected.visible = true
		for p in planets.size():
			var dist_to_mouse = viewport_star.get_mouse_position().distance_squared_to(planets[p].position)
			if dist_to_mouse < 300 and not planets[p].hover:
				enter_hover_planet(planets[p])
			elif planets[p].hover:
				exit_hover_planet(planets[p])
	elif not selected and spr_selected.visible:
		spr_selected.visible = false

func _draw():
	for a in adj.size():
		draw_line(Vector2.ZERO,adj[a].position - position,Color.DIM_GRAY,2,false)

func add_adjacent(pStar: Star) -> void:
	if not adj.has(pStar):
		adj.append(pStar)
	if not pStar.adj.has(self):
		pStar.adj.append(self)
	
func handle_interstellar_probe_replication(delta: float) -> void:
	if star_probes > 0 and star_probes < max_star_probes:
		time_since_last_star_probe += delta
		bar_next_star_probe.set_value(time_since_last_star_probe)
		if time_since_last_star_probe >= time_per_star_probe_replication:
			time_since_last_star_probe = 0
			star_probe_replicate_attempt.emit()

func add_log(pLog: String):
	activity_log.push_front(pLog)
	log_added.emit()
	
var planet_time: float
func orbit_planets():
	star_viewer_img.visible = true
	while selected:
		for p in planets.size():
			var x = cos(planet_time + planets[p].orbital_offset) * planets[p].orbital_radius + 375
			var y = sin(planet_time + planets[p].orbital_offset) * planets[p].orbital_radius + 375
			planets[p].position = Vector2(x,y)
			planets[p].rotate(planets[p].rotational_velocity)
		await get_tree().process_frame

func _on_hover(): 
	hover = true
	queue_redraw()
	
func _exit_hover():
	hover = false
	queue_redraw()
	
func enter_hover_planet(pPlanet: Planet) -> void:
	pPlanet.on_hover()
	
func exit_hover_planet(pPlanet: Planet) -> void:
	pPlanet.exit_hover()
	
func select():
	selected = true
	star_probe_count_changed.emit() #DON'T LOVE THIS BUT IF IT WORKS IT WORKS
	orbit_planets()
	for p in planets.size():
		planets[p].visible = true
		viewport_star.add_child(planets[p])
		planets[p].position = Vector2(p * 100 + 50, 500)
	queue_redraw()
	star_selected.emit()
		
func deselect():
	selected = false
	hover = false
	star_viewer_img.visible = false
	clear_probes_label()
	for p in planets.size():
		planets[p].visible = false
		viewport_star.remove_child(planets[p])
	queue_redraw()
	star_deselected.emit()

func clear_probes_label():
	lbl_star_probes.text = ""

func add_star_probes(pNumProbes) -> void:
	star_probes += pNumProbes
	if star_probes > max_star_probes:
		var overflow = star_probes - max_star_probes
		star_probes = max_star_probes
		var target = adj[0]
		for p in overflow:
			var new_travelling_probe = Probe.new()
			new_travelling_probe.set_target(target)
			travelling_star_probes.append(new_travelling_probe)
		
	bar_total_star_probes.set_value(star_probes)
	if not bar_total_star_probes.visible:
		bar_total_star_probes.visible = true
		bar_next_star_probe.visible = true
	star_probe_count_changed.emit()
		
func set_replication_rate(pRate) -> void:
	time_per_star_probe_replication = 1.0 / pRate
