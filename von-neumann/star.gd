extends Sprite2D

const Planet = preload("res://planet.gd")

var planets: Array[Planet]

var star_viewer: SubViewport

var selected = false
var hover = false
var adj = []

func set_star_viewer_viewport(pViewport) -> void:
	star_viewer = pViewport

func _ready() -> void:
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
		

func _process(delta: float) -> void:
	pass
		

	if Input.is_action_just_pressed("Click"):
		if hover and not selected:
			select()
		elif not hover and selected:
			deselect()

func _draw() -> void:
	if hover or selected:
		draw_circle(Vector2(0,0), 15,Color.GREEN,false)
	pass

func _on_hover(): 
	hover = true
	queue_redraw()
	
func _exit_hover():
	hover = false
	queue_redraw()
	
func select():
	selected = true
	for p in planets.size():
		planets[p].visible = true
		star_viewer.add_child(planets[p])
		planets[p].position = Vector2(p * 100 + 50, 500)
		
func deselect():
	selected = false
	for p in planets.size():
		planets[p].visible = false
		
func add_adjacent(pStar) -> void:
	if not(adj.has(pStar)):
		var line = Line2D.new()
		line.default_color = Color.AQUA
		line.points = []
		line.points.append(Vector2(0,0))
		line.points.append(Vector2(pStar.position))
		add_child(line)
		adj.append(pStar)
