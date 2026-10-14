extends AnimatedSprite2D

func _ready() -> void:
	sprite_frames = preload("res://Images/anim_test/test_sprite_frames.tres")
	scale = Vector2.ONE * 100
	position = Vector2(300,300)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func _process(delta: float) -> void:
	
	frame = randi_range(0,15)
