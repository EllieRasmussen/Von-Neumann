extends Node2D

@export var window_star_viewer: Window

@export var button_slider_star: Node2D
@export var btn_star_viewer: Button


func _on_button_button_down() -> void:
	if window_star_viewer.visible:
		close_star_window()
	else:
		open_star_window()


func _on_window__star_viewer_close_requested() -> void:
	close_star_window()


func open_star_window() -> void:
	window_star_viewer.visible = true
	button_slider_star.position = Vector2(-120,0)

func close_star_window() -> void:
	window_star_viewer.visible = false
	button_slider_star.position = Vector2(0,0)
