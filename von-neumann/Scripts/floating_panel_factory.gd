extends FloatingPanel
class_name FloatingPanelFactory

@export var lbl_factory_total_resource: Label
@export var btn_factory_make_extractors: TextureButton
@export var btn_factory_make_probes: TextureButton
@export var lbl_factory_making_extractors: Label
@export var lbl_factory_making_probes: Label
@export var progbar_fund: ProgressBar
@export var lbl_fund: Label
@export var progbar_next_extractor: ProgressBar
@export var lbl_progbar_next_extractor: Label
@export var progbar_next_probe: ProgressBar
@export var lbl_progbar_next_probe: Label
@export var factory_window_sprite: TextureRect

var factory: Factory:
	set(new_factory):
		factory = new_factory
		factory.update_funding_timer.connect(update_fund_timer)
		factory.changed_resource_main.connect(update_resource_main)
		factory.changed_resource_next_extractor.connect(update_next_extractor)
		factory.changed_resource_next_probe.connect(update_next_probe)
		update_factory_panel()


func _ready() -> void:
	lbl_progbar_next_extractor.text = "0/" + str(Globals.resource_to_make_extractor)
	lbl_progbar_next_probe.text = "0/" + str(Globals.resource_to_make_probe)


func update_factory_panel() -> void:
	
	lbl_fund.text = "Allocating " + str("%.2f"%Globals.factory_funding_amount)+" every "+str("%.2f"%Globals.factory_funding_interval)+" seconds"
	
	btn_factory_make_extractors.button_pressed = factory.making_extractors
	if factory.making_extractors:
		lbl_factory_making_extractors.text = "MAKING EXTRACTORS"
	else:
		lbl_factory_making_extractors.text = "MAKE EXTRACTORS"
		
	btn_factory_make_probes.button_pressed = factory.making_probes
	if factory.making_probes:
		lbl_factory_making_probes.text = "MAKING PROBES"
	else:
		lbl_factory_making_probes.text = "MAKE PROBES"
	
	lbl_factory_total_resource.text = "TOTAL RESOURCE: " + str("%.2f" % factory.resource_pool_main)
	
func update_resource_main(pResource: float) -> void:
	factory_window_sprite.texture = factory.anim_sprite.sprite_frames.get_frame_texture("default",factory.anim_sprite.frame)
	lbl_factory_total_resource.text = "TOTAL RESOURCE: " + str("%.2f" % pResource)
	
	
func update_next_extractor(pResource: float) -> void:
	lbl_progbar_next_extractor.text = str("%.2f" % pResource) + "/" + str(str("%.2f" % Globals.resource_to_make_extractor))
	progbar_next_extractor.max_value = Globals.resource_to_make_extractor
	progbar_next_extractor.value = pResource

func update_next_probe(pResource: float) -> void:
	lbl_progbar_next_probe.text = str("%.2f" % pResource) + "/" + str("%.2f" % Globals.resource_to_make_probe)
	progbar_next_probe.max_value = Globals.resource_to_make_probe
	progbar_next_probe.value = pResource

func update_fund_timer(pProgress: float) -> void:
	progbar_fund.max_value = Globals.factory_funding_interval
	progbar_fund.value = pProgress
	

func _on_btn_make_drills_toggled(toggled_on: bool) -> void:
	if factory != null:
		factory.making_extractors = toggled_on
		update_factory_panel()

func _on_btn_make_probes_toggled(toggled_on: bool) -> void:
	if factory != null:
		factory.making_probes = toggled_on
		update_factory_panel()
