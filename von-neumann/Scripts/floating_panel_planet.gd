extends FloatingPanel
class_name FloatingPanelPlanet

@export var texture_planet_sprite: TextureRect
@export var lbl_planet_resource_multiplier: Label
@export var lbl_planet_extractors: Label
@export var progbar_planet_next_extraction: ProgressBar
@export var progbar_planet_manual_extraction: ProgressBar
@export var btn_manual_extraction: Button

var planet: Planet:
	set(new_planet):
		planet = new_planet
		texture_planet_sprite.texture = planet.sprite.texture
		planet.added_extractor.connect(update_planet_window)
		closed.connect(planet.deselect)
		#btn_manual_extraction.disabled = sel_star == null or sel_star.factory == null
		update_planet_window()
		

var manual_extract_tracker: float = 0
func _process(delta: float) -> void:
	super(delta)
	if planet != null:
		progbar_planet_next_extraction.value = planet.get_extraction_progress() * 100.0
		if manual_extract_tracker > 0.0:
			manual_extract_tracker -= delta * 2
		progbar_planet_manual_extraction.value = manual_extract_tracker

func update_planet_window() -> void:
	if planet == null:
		return
	
	lbl_planet_resource_multiplier.text = "RESOURCE: x" + ("%.2f" % planet.resource_multiplier)
	lbl_planet_extractors.text = "DRILLS: " + str(planet.extractors)


func _on_btn_manual_drill_button_down() -> void:
	manual_extract_tracker += Globals.percentage_added_on_manual_extraction
	if manual_extract_tracker >= 100.0 and planet != null:
		manual_extract_tracker -= 100
		planet.extract_resource(1)
