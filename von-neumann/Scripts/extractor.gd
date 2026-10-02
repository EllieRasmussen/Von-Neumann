extends Sprite2D

const Planet = preload("res://Scripts/planet.gd")

enum EXTRACTOR_STATE {IDLE, TRAVELLING, EXTRACTING}
var state: EXTRACTOR_STATE

var speed = 500
var target_planet: Planet
var target_planet_follower: PathFollow2D

func _ready() -> void:
	self.texture = preload("res://Images/extractor.png")
	scale = Vector2.ONE
	
	
var extraction_timer = 0.0
var time_per_extraction = 1.0


func _process(delta: float) -> void:
	if state == EXTRACTOR_STATE.TRAVELLING:
		var target_pos = get_target_position()
		var dir = (target_pos - position).normalized()
		position += dir * speed * delta
		if position.distance_squared_to(target_pos) < 2500:
			target_planet.num_extractors += 1
			var planet_offset = Vector2(
				cos(float(target_planet.num_extractors) / float(target_planet.max_extractors)) * target_planet.scale.x, 
				sin(float(target_planet.num_extractors) / float(target_planet.max_extractors)) * target_planet.scale.y
			)
			self.reparent(target_planet)
			position = planet_offset
			state = EXTRACTOR_STATE.EXTRACTING
	
	if state == EXTRACTOR_STATE.EXTRACTING:
		extraction_timer += delta
		if extraction_timer >= time_per_extraction:
			extraction_timer = 0
			extract()
			
func unselected_process(delta: float) -> void:
	if state == EXTRACTOR_STATE.TRAVELLING:
		var target_pos = get_target_position()
		var dir = (target_pos - position).normalized()
		position += dir * speed * delta
		if position.distance_squared_to(target_pos) < 2500:
			target_planet.num_extractors += 1
			var planet_offset = Vector2(
				cos(float(target_planet.num_extractors) / float(target_planet.max_extractors)) * target_planet.scale.x, 
				sin(float(target_planet.num_extractors) / float(target_planet.max_extractors)) * target_planet.scale.y
			)
			self.reparent(target_planet)
			position = planet_offset
			state = EXTRACTOR_STATE.EXTRACTING
	
	if state == EXTRACTOR_STATE.EXTRACTING:
		extraction_timer += delta
		if extraction_timer >= time_per_extraction:
			extraction_timer = 0
			extract()




func go_to_planet(pTarget: Planet, pFollower: PathFollow2D) -> void:
	state = EXTRACTOR_STATE.TRAVELLING
	target_planet = pTarget
	target_planet_follower = pFollower
	
func get_target_position() -> Vector2:
	var angle = 6.283 * target_planet_follower.progress_ratio
	var pos = Vector2(
		cos(angle) * target_planet.orbital_radius,
		sin(angle) * target_planet.orbital_radius
	)
	pos += target_planet.orbital_offset
	return pos
	


func extract():
	print("EXTRACTED!")
