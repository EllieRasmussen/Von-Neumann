extends Node2D

const AnimTest = preload("res://Images/anim_test/anim_test.gd")

var anim_test: AnimTest

func _ready() -> void:
	anim_test = AnimTest.new()
	add_child(anim_test)
