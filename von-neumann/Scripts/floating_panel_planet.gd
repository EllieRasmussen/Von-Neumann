extends FloatingPanel
class_name FloatingPanelPlanet

@export var texture_planet_sprite: TextureRect
@export var lbl_solids: Label
@export var lbl_liquids: Label
@export var lbl_gasses: Label

@export var prg_drill_solids: ProgressBar
@export var prg_drill_liquids: ProgressBar
@export var prg_drill_gasses: ProgressBar

@export var lbl_planet_extractors: Label
@export var progbar_planet_next_extraction: ProgressBar

var planet: Planet:
	set(new_planet):
		planet = new_planet
		#planet.added_extractor.connect(update_planet_window)
		closed.connect(planet.deselect)
		update_resource()
		

var manual_drill: Vector3 = Vector3.ZERO
func _process(delta: float) -> void:
	super(delta)
	if planet != null:
		progbar_planet_next_extraction.value = planet.get_extraction_progress() * 100.0
		if manual_drill[0] > 0.0:
			manual_drill[0] -= delta * 2
		if manual_drill[1] > 0.0:
			manual_drill[1] -= delta * 2
		if manual_drill[2] > 0.0:
			manual_drill[2] -= delta * 2
		prg_drill_solids.value = manual_drill[0]
		prg_drill_liquids.value = manual_drill[1]
		prg_drill_gasses.value = manual_drill[2]

func update_resource() -> void:
	if planet == null:
		return
	
	lbl_solids.text = "Solids: x" + str("%.2f" % planet.solids)
	lbl_liquids.text = "Liquids: x" + str("%.2f" % planet.liquids)
	lbl_gasses.text = "Gasses: x" + str("%.2f" % planet.gasses)
	

func update_drills() -> void:
	lbl_planet_extractors.text = "DRILLS: " + str(planet.extractors)


func _on_btn_drill_solids_button_down() -> void:
	manual_drill[0] += Globals.percentage_added_on_manual_extraction
	if manual_drill[0] > 100:
		manual_drill[0] -= 100
		planet.drill_solids()


func _on_btn_drill_liquids_button_down() -> void:
	manual_drill[1] += Globals.percentage_added_on_manual_extraction
	if manual_drill[1] > 100:
		manual_drill[1] -= 100
		planet.drill_liquids()


func _on_btn_drill_gasses_button_down() -> void:
	manual_drill[2] += Globals.percentage_added_on_manual_extraction
	if manual_drill[2] > 100:
		manual_drill[2] -= 100
		planet.drill_gasses()
