extends Sprite2D

const Planet = preload("res://Scripts/planet.gd")

enum EXTRACTOR_STATE {IDLE, TRAVELLING, EXTRACTING}
var state: EXTRACTOR_STATE

var state_: int

var speed = 0.1
var target_planet: Planet

func _ready() -> void:
	self.texture = preload("res://Images/extractor.png")
	scale = Vector2.ONE
	
	
var extraction_timer = 0.0
var time_per_extraction = 1.0


func _process(delta: float) -> void:
	print(state_)
	if state_ == 1:
		var dir = (target_planet.position - position).normalized()
		position += dir * speed
		if position.distance_squared_to(target_planet.position) < 2500:
			target_planet.num_extractors += 1
			var planet_offset = Vector2(cos((float)(target_planet.num_extractors / target_planet.max_extractors)) * target_planet.scale.x, sin((float)(target_planet.num_extractors / target_planet.max_extractors)) * target_planet.scale.y)
			position = target_planet.position + planet_offset
			state_ = 2
	
	
	if state_ == 2:
		extraction_timer += delta
		if extraction_timer >= time_per_extraction:
			extraction_timer = 0
			extract()




func go_to_planet(pTarget: Planet) -> void:
	state_ = 1
	target_planet = pTarget
	print(state_)

func extract():
	print("EXTRACTED!")
