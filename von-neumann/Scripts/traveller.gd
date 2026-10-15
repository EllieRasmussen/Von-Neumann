extends Node2D

class_name Traveller

var sprite: Sprite2D

var onscreen: bool = true
var frames_until_next_update: int = 1 #FOR FUTURE BATCHING, DON'T USE YET

var speed = 1000 #1000 feels actually good
var target: Orbiter

signal arrived

func _init() -> void:
	sprite = Sprite2D.new()
	sprite.scale = Vector2.ONE * 10
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(sprite)

func _ready() -> void:
	pass

func set_target(pTarget: Orbiter) -> void:
	target = pTarget
	
	#LAUNCH IN RANDOM DIRECTION
	var dir = Vector2(
		cos(randf() * 6.2832),
		sin(randf() * 6.2832)
	)
	var initial_velocity = randf_range(100.0,200.0)
	sprite.look_at(position + dir)
	while initial_velocity > 1:
		position += dir * initial_velocity
		initial_velocity *= 0.9
		await Engine.get_main_loop().process_frame
	
	#ROTATE TOWARDS TARGET
	var start_angle = sprite.rotation
	var target_angle = position.angle_to_point(target.position)
	var lerp_val = 0.0
	while lerp_val < 1.0:
		lerp_val += Globals.deltaTime
		sprite.rotation = lerp_angle(start_angle,target_angle,lerp_val)
		await Engine.get_main_loop().process_frame
	
	#TRAVEL TO TARGET
	while(true):
		update_position(Globals.deltaTime)
		await Engine.get_main_loop().process_frame
	
	
func update_position(delta: float) -> void:
	var dir = (target.position - position).normalized()
	position += dir * speed * delta
	sprite.look_at(target.position)
	if position.distance_squared_to(target.position) < 2500:
		arrived.emit()
