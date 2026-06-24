extends Node2D

var star_adj_max = 10

@export var cam: Camera2D
@export var cam_speed: float
var cam_pos: Vector2

var quad_tree_root

var star_imgs: Array

var galaxy_size = 10000.0
var max_quad_lvl = 0

var map_pos = Vector2(-galaxy_size,-galaxy_size)
var map_scale = 15 #ratio between map and galaxy --- map_scale:galaxy_size
var cam_zoom_swap = 0.1
var cam_on_map = false

var num_stars = 1000

var stars: Array[Sprite2D] = []

var left_click = false

func _ready() -> void:
	star_imgs.append(load("res://Images/Star_0.png"))
	star_imgs.append(load("res://Images/Star_1.png"))
	star_imgs.append(load("res://Images/Star_2.png"))
	star_imgs.append(load("res://Images/Star_3.png"))
	
	cam.position = Vector2(galaxy_size/2 - get_viewport_rect().size.x,galaxy_size/2 + get_viewport_rect().size.y)
	cam_pos = cam.position	
	quad_tree_root = Quad.new()
	quad_tree_root.set_quad(0,0,galaxy_size,0,quad_tree_root)
	for s in num_stars:
		var new_star = Star.new()
		new_star.texture = star_imgs[randi()%len(star_imgs)]
		new_star.scale = Vector2(5,5)
		var theta = randf() * 6.283
		var radius = (galaxy_size / 2) * randf()
		new_star.position = Vector2((galaxy_size/2)+(cos(theta) * radius),(galaxy_size/2)+(sin(theta) * radius))
		add_child(new_star)
		quad_tree_root.add_star(new_star,self)
		
	quad_tree_root.set_star_adjacency_map(star_adj_max)
	add_child(quad_tree_root)
	max_quad_lvl = get_max_quad_lvl(quad_tree_root)
	generate_map(quad_tree_root)
	

func _process(delta: float) -> void:
	if Input.is_action_pressed("Up"):
		cam_pos.y -= cam_speed * delta
	if Input.is_action_pressed("Down"):
		cam_pos.y += cam_speed * delta
	if Input.is_action_pressed("Left"):
		cam_pos.x -= cam_speed * delta
	if Input.is_action_pressed("Right"):
		cam_pos.x += cam_speed * delta
		
	if Input.is_action_just_pressed("Scroll Up"):
		cam.zoom += Vector2(0.01,0.01)
		if cam.zoom.x > 1:
			cam.zoom = Vector2(1, 1)
		#if cam.zoom.x > cam_zoom_swap and cam_on_map:
			#cam_pos = Vector2((cam.position.x + galaxy_size)*map_scale,(cam.position.y + galaxy_size)*map_scale)
			#print(cam_pos)
			#cam_speed *= map_scale
			#cam_on_map = false
		
	if Input.is_action_just_pressed("Scroll Down"):
		cam.zoom -= Vector2(0.01,0.01)
		if cam.zoom.x < 0.015:
			cam.zoom = Vector2(0.015, 0.015)
		#if cam.zoom.x < cam_zoom_swap and not(cam_on_map):
			#cam_pos = Vector2((cam.position.x / galaxy_size) * (galaxy_size / map_scale) - galaxy_size, (cam.position.y / galaxy_size) * (galaxy_size / map_scale) - galaxy_size)
			#print(cam_pos)
			#cam_speed /= map_scale
			#cam_on_map = true
		
			
	if Input.is_action_pressed("Click"):
		left_click = true
	else:
		left_click = false
	
	cam.position = cam_pos
	
	
func _draw() -> void:
	pass

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and left_click:
		cam_pos -= event.relative * cam.zoom * 10

func generate_map(quad: Quad) -> void:
	if len(quad.children) > 0:
		for q in len(quad.children):
			generate_map(quad.children[q])
	elif quad.lvl > 3:
		var rect = ColorRect.new()
		rect.position = map_pos + (quad.position / map_scale)
		rect.size = Vector2(quad.size/map_scale,quad.size/map_scale)
		rect.color = Color(0.98 * (randf()+0.5),0.98 * (randf()+0.5),0.98 * (randf()+0.5),float(quad.lvl - 1) / float(max_quad_lvl) * randf())
		add_child(rect)

func get_max_quad_lvl(quad: Quad) -> int:
	var max_lvl = quad.lvl
	if len(quad.children) != 0:
		for q in 4:
			var child_max_lvl = get_max_quad_lvl(quad.children[q])
			if child_max_lvl > max_lvl:
				max_lvl = child_max_lvl
	return max_lvl





class Star extends Sprite2D:
	var adj = []
	func _draw() -> void:
		for s in len(adj):
			if position.x < adj[s].position.x:
				draw_line(Vector2(0,0),(adj[s].position - position) * (1/scale.x),Color.WEB_GRAY,1)
		pass
	func add_adjacent(pStar: Star) -> void:
		if not(adj.has(pStar)):
			adj.append(pStar)








class Quad extends Node2D:
	var size
	var lvl
	var stars = []
	var children = []
	var root
	
	func _draw() -> void:
		pass
		#draw_rect(Rect2(0,0,size,size),Color.RED,false,10)
		

	func set_quad(px,py,pSize,plvl,pRoot) -> void:
		position = Vector2(px,py)
		size = pSize
		lvl = plvl
		root = pRoot
	
	func is_in_quad(pStar: Star) -> bool:
		return pStar.position.x >= position.x and pStar.position.x <= position.x + size and pStar.position.y >= position.y and pStar.position.y <= position.y + size
	
	func add_star(pStar: Star, pRoot: Node2D) -> void:
		if len(children) != 0:
			for q in len(children):
				if children[q].is_in_quad(pStar):
						children[q].add_star(pStar,root)
						
		elif len(stars) < 100 or lvl == 20:
			stars.append(pStar)
			
		
		else:
			var top_left = Quad.new()
			var top_right = Quad.new()
			var bottom_left = Quad.new()
			var bottom_right = Quad.new()
			top_left.set_quad(position.x,position.y,size/2,lvl+1,root)
			top_right.set_quad(position.x+size/2,position.y,size/2,lvl+1,root)
			bottom_left.set_quad(position.x,position.y+size/2,size/2,lvl+1,root)
			bottom_right.set_quad(position.x+size/2,position.y+size/2,size/2,lvl+1,root)
			children.append(top_left)
			children.append(top_right)
			children.append(bottom_left)
			children.append(bottom_right)
			pRoot.add_child(top_left)
			pRoot.add_child(top_right)
			pRoot.add_child(bottom_left)
			pRoot.add_child(bottom_right)
			
			stars.append(pStar)
			
			for s in len(stars):
				for q in len(children):
					if children[q].is_in_quad(stars[s]):
						children[q].add_star(stars[s],root)
			
						
	func set_star_adjacency_map(p_adjacenty_limit: float) -> void:
		if len(children) > 0:
			for q in len(children):
				children[q].set_star_adjacency_map(p_adjacenty_limit)
		else:
			pass
			
			var adj_limit = (size / 5) * (randf() + 1)
			
			for s0 in len(stars):
				for s1 in len(stars):
					var dist_between = pow((stars[s0].position.x-stars[s1].position.x),2) + pow((stars[s0].position.y-stars[s1].position.y),2)
					if dist_between <= pow(adj_limit,2) and dist_between != 0:
						stars[s0].add_adjacent(stars[s1])
						stars[s1].add_adjacent(stars[s0])
			var adj_quads = root.get_leafs_adjacent_to(self)
			
			#var print_str = "["+str(position.x) +","+ str(position.y) +"]: " +"LVL="+str(lvl)+" -- ADJ TO:"+ str(len(adj_quads))
			#for q in len(adj_quads):
				#print_str += "[" + str(adj_quads[q].position.x) + "," + str(adj_quads[q].position.y) + "]-----"
			#print(print_str)
			
			
			for q in len(adj_quads):
				for s0 in len(stars):
					for s1 in len(adj_quads[q].stars):
						var dist_between = pow((stars[s0].position.x-adj_quads[q].stars[s1].position.x),2) + pow((stars[s0].position.y-adj_quads[q].stars[s1].position.y),2)
						if dist_between <= pow(adj_limit,2) and dist_between != 0:
							stars[s0].add_adjacent(adj_quads[q].stars[s1])
							adj_quads[q].stars[s1].add_adjacent(stars[s0])
							
							
	func get_leafs_adjacent_to(pQuad: Quad) -> Array[Quad]:
		var adj_quads: Array[Quad]
		
		#IF THIS QUAD IS ADJACENT AND A LEAF, RETURN THIS QUAD
		if len(children) == 0:
			#RIGHT
			if position.x == pQuad.position.x + pQuad.size:
				#RIGHT EDGE
				if (position.y >= pQuad.position.y and position.y <= pQuad.position.y + pQuad.size) or (pQuad.position.y >= position.y and pQuad.position.y <= position.y + size):
					adj_quads.append(self)
				#BOTTOM RIGHT
				elif position.y == pQuad.position.y + pQuad.size:
					adj_quads.append(self)
			#BOTTOM EDGE
			elif position.y == pQuad.position.y + pQuad.size:
				if (position.x >= pQuad.position.x and position.x <= pQuad.position.x + pQuad.size) or (pQuad.position.x >= position.x and pQuad.position.x <= position.x+size):
					adj_quads.append(self)
		
		#ELSE, CALL THIS FUNCTION ON CHILDREN THAT COULD CONTAIN ADJACENT QUADS, APPEND RETURN VAL, RETURN LIST
		else:
			for i in range(4):
				var branch_quads = children[i].get_leafs_adjacent_to(pQuad)
				for j in len(branch_quads):
					adj_quads.append(branch_quads[j])
		
		return adj_quads
