extends Sprite2D

const Planet = preload("res://Scripts/planet.gd")
const ProgBar = preload("res://Scripts/prog_bar.gd")

var planets: Array[Planet]

var interstellar_probes = 0
var max_interstellar_probes = 100

var star_viewer: SubViewport
var lbl_star_interstellar_probes: Label

var total_probes_bar: ProgBar
var next_probe_bar: ProgBar
var next_probe_tracker: float
var next_probe_max: float

signal interstellar_probe_replicate_attempt

var selected = false
var hover = false
var adj = []

func set_star_viewer_viewport(pViewport) -> void:
	star_viewer = pViewport
	
func set_star_interstellar_probes_label(pLabel) -> void:
	lbl_star_interstellar_probes = pLabel

func _ready() -> void:
	next_probe_tracker = 0
	
	#SET TEXTURE
	var star_imgs = []
	star_imgs.append(load("res://Images/Star_0.png"))
	star_imgs.append(load("res://Images/Star_1.png"))
	star_imgs.append(load("res://Images/Star_2.png"))
	star_imgs.append(load("res://Images/Star_3.png"))
	self.texture = star_imgs[randi()%len(star_imgs)]
	
	var num_planets = randi_range(3,10)
	for i in num_planets:
		var p = Planet.new()
		p.visible = false
		p.scale = Vector2(0.05,0.05)
		planets.append(p)
		
	total_probes_bar = ProgBar.new()
	add_child(total_probes_bar)
	total_probes_bar.position = Vector2(-25,15)
	total_probes_bar.set_bar_width(5)
	total_probes_bar.set_bar_length(50)
	total_probes_bar.set_bg_color(Color.SLATE_GRAY)
	total_probes_bar.set_fg_color(Color.BLUE)
	total_probes_bar.set_value(interstellar_probes)
	total_probes_bar.set_max_value(max_interstellar_probes)
	
	
	next_probe_bar = ProgBar.new()
	add_child(next_probe_bar)
	next_probe_bar.position = Vector2(-25,20)
	next_probe_bar.set_bar_width(2)
	next_probe_bar.set_bar_length(50)
	next_probe_bar.set_bg_color(Color.DARK_SLATE_GRAY)
	next_probe_bar.set_fg_color(Color.AQUA)
	next_probe_bar.set_value(0)
	next_probe_bar.set_max_value(next_probe_max)
	
	if interstellar_probes == 0:
		total_probes_bar.visible = false
		next_probe_bar.visible = false

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("Click"):
		if hover and not selected:
			select()
		elif not hover and selected:
			deselect()
			
	if interstellar_probes > 0 and interstellar_probes < max_interstellar_probes:
		next_probe_tracker += delta
		next_probe_bar.set_value(next_probe_tracker)
		if next_probe_tracker >= next_probe_max:
			next_probe_tracker = 0
			interstellar_probe_replicate_attempt.emit()
			if selected:
				update_probes_label()

func _draw() -> void:
	#if hover or selected:
		#draw_circle(Vector2(0,0), 15,Color.GREEN,false)
	pass

func _on_hover(): 
	hover = true
	queue_redraw()
	
func _exit_hover():
	hover = false
	queue_redraw()
	
func select():
	selected = true
	update_probes_label()
	for p in planets.size():
		planets[p].visible = true
		star_viewer.add_child(planets[p])
		planets[p].position = Vector2(p * 100 + 50, 500)
	queue_redraw()
		
func deselect():
	selected = false
	hover = false
	clear_probes_label()
	for p in planets.size():
		planets[p].visible = false
		star_viewer.remove_child(planets[p])
	queue_redraw()
	
func update_probes_label():
	lbl_star_interstellar_probes.text = "INTERSTELLAR PROBES:   " + str(interstellar_probes) + " / " + str(max_interstellar_probes)

func clear_probes_label():
	lbl_star_interstellar_probes.text = ""
		
func add_adjacent(pStar) -> void:
	if not(adj.has(pStar)):
		var line = Line2D.new()
		line.default_color = Color.DIM_GRAY
		line.width = 0.5
		line.add_point(Vector2(0,0))
		line.add_point(Vector2(pStar.position - position))
		line.z_index = -1
		add_child(line)
		adj.append(pStar)
		
func add_interstellar_probes(pNumProbes) -> void:
	interstellar_probes += pNumProbes
	if interstellar_probes > max_interstellar_probes:
		interstellar_probes = max_interstellar_probes
	total_probes_bar.set_value(interstellar_probes)
	if not total_probes_bar.visible:
		total_probes_bar.visible = true
		next_probe_bar.visible = true
		
func set_replication_rate(pRate) -> void:
	next_probe_max = 1.0 / pRate
