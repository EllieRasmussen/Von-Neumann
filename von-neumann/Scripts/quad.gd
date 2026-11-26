extends Node2D
class_name Quad
var size
var lvl
var stars = []
var children = []
var root

var outline: Line2D
func draw_outline() -> void:
	outline = Line2D.new()
	outline.default_color = Color.RED
	outline.width = 100
	outline.add_point(position)
	outline.add_point(position + Vector2(size,0))
	outline.add_point(position + Vector2(size,size))
	outline.add_point(position + Vector2(0,size))
	outline.closed = true
	Globals.viewport_stars.add_child(outline)

#I WISH TO KILL PX AND PY AND ARISE POSITION IN ITS WAKE, BUT OH MY GOD HOW THE FUCK DOES THIS THING WORK? I MADE THIS IN LIKE APRIL. 
func set_quad(px,py,pSize,plvl,pRoot) -> void:
	position = Vector2(px,py)
	size = pSize
	lvl = plvl
	root = pRoot

func get_leaf_at(pos: Vector2) -> Quad:
	#TOP LEFT
	if pos.x < position.x + size / 2 and pos.y < position.y + size / 2:
		if children[0].children.size() == 0:
			return children[0]
		else:
			return children[0].get_leaf_at(pos)
	#TOP RIGHT
	elif pos.x > position.x + size / 2 and pos.y < position.y + size / 2:
		if children[1].children.size() == 0:
			return children[1]
		else:
			return children[1].get_leaf_at(pos)
	#BOTTOM LEFT
	elif pos.x < position.x + size / 2 and pos.y > position.y + size / 2:
		if children[2].children.size() == 0:
			return children[2]
		else:
			return children[2].get_leaf_at(pos)
	else:
		if children[3].children.size() == 0:
			return children[3]
		else:
			return children[3].get_leaf_at(pos)

func is_in_quad(pStar: Star) -> bool:
	return pStar.position.x >= position.x and pStar.position.x <= position.x + size and pStar.position.y >= position.y and pStar.position.y <= position.y + size

func add_star(pStar: Star, pRoot: Node2D) -> void:
	if len(children) != 0:
		for q in len(children):
			if children[q].is_in_quad(pStar):
					children[q].add_star(pStar,root)
					
	elif len(stars) < 10 or lvl == 20:
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
