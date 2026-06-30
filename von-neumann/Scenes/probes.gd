extends Node2D

const Star = preload("res://star.gd")
@export var star_viewer_viewport: SubViewport

var stars: Array[Sprite2D] = []

func _ready() -> void:
	#GENERATE STARS + ADJACENCY
	for i in 10:
		var s = Star.new()
		s.position = Vector2((randf() * 780) + 30, (randf() * 1020) + 30)
		s.set_star_viewer_viewport(star_viewer_viewport)
		stars.append(s)
		add_child(s)
	
func _process(delta: float) -> void:
	for s in stars.size():
		var dist_to_mouse = get_global_mouse_position().distance_squared_to(stars[s].position)
		if dist_to_mouse < 225:
			enter_hover_star(stars[s])
		elif stars[s].hover:
			exit_hover_star(stars[s])

func enter_hover_star(pStar: Star) -> void:
	pStar._on_hover()
	
func exit_hover_star(pStar: Star) -> void:
	pStar._exit_hover()
#POPULATE FIRST STAR WITH 1 INTERSTELLAR PROBE

#INTERSTELLAR PROBES AT STARS DUPLICATE AND SEND COPY TO NEAREST NEIGHBOR

#INTERSTELLAR PROBES AT STARS PRODUCE PLANETARY PROBES

#PLANETARY PROBES TRAVEL TO NEAREST UNPOPULATED PLANET

#IF ALL PLANETS ARE POPULATED, PLANETARY PROBES TRAVEL TO LEAST-POPULATED PLANET
