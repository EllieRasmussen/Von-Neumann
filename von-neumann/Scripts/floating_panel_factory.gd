extends FloatingPanel
class_name FloatingPanelFactory

@export var prg_solids: ProgressBar
@export var prg_liquids: ProgressBar
@export var prg_gasses: ProgressBar

@export var prg_fund_solids: ProgressBar
@export var prg_fund_liquids: ProgressBar
@export var prg_fund_gasses: ProgressBar

@export var lbl_solids: Label
@export var lbl_liquids: Label
@export var lbl_gasses: Label

@export var lbl_fund: Label
@export var factory_sprite: TextureRect

@export var grid_active_buildables: GridContainer
@export var grid_inactive_buildables: GridContainer
@export var buildables: Array[Buildable]

var factory: Factory:
	set(new_factory):
		factory = new_factory
		
		factory.fund_solids_changed.connect(update_fund_solids)
		factory.fund_liquids_changed.connect(update_fund_liquids)
		factory.fund_gasses_changed.connect(update_fund_gasses)
		
		factory.pool_solids_changed.connect(update_pool_solids)
		factory.pool_liquids_changed.connect(update_pool_liquids)
		factory.pool_gasses_changed.connect(update_pool_gasses)
		update_factory_panel()

func _ready() -> void:
	for b in buildables.size():
		buildables[b].changed_active.connect(toggle_buildable_active.bind(buildables[b]))
		if b == 0:
			Globals.cost_drill_changed.connect(buildables[b].prg_solids_set_max)
			Globals.cost_drill_changed.connect(buildables[b].prg_liquids_set_max)
			Globals.cost_drill_changed.connect(buildables[b].prg_gasses_set_max)
			buildables[b].prg_solids_set_max(Globals.build_costs[0])
			buildables[b].prg_liquids_set_max(Globals.build_costs[0])
			buildables[b].prg_gasses_set_max(Globals.build_costs[0])
		elif b == 1:
			Globals.cost_scanner_changed.connect(buildables[b].prg_solids_set_max)
			Globals.cost_scanner_changed.connect(buildables[b].prg_liquids_set_max)
			Globals.cost_scanner_changed.connect(buildables[b].prg_gasses_set_max)
			buildables[b].prg_solids_set_max(Globals.build_costs[1])
			buildables[b].prg_liquids_set_max(Globals.build_costs[1])
			buildables[b].prg_gasses_set_max(Globals.build_costs[1])
		elif b == 2: 
			Globals.cost_factory_changed.connect(buildables[b].prg_solids_set_max)
			Globals.cost_factory_changed.connect(buildables[b].prg_liquids_set_max)
			Globals.cost_factory_changed.connect(buildables[b].prg_gasses_set_max)
			buildables[b].prg_solids_set_max(Globals.build_costs[2])
			buildables[b].prg_liquids_set_max(Globals.build_costs[2])
			buildables[b].prg_gasses_set_max(Globals.build_costs[2])

func toggle_buildable_active(pBuildable: Buildable) -> void:
	if pBuildable.active and factory != null:
		pBuildable.reparent(grid_active_buildables)
		factory.set_buildable_active(pBuildable.buildable_type)
		factory.funded_solids.connect(pBuildable.update_prg_solids)
		factory.funded_liquids.connect(pBuildable.update_prg_liquids)
		factory.funded_gasses.connect(pBuildable.update_prg_gasses)
			
		if pBuildable.buildable_type == 0:
			factory.created_extractor.connect(pBuildable.update_prg_solids.bind(0))
			factory.created_extractor.connect(pBuildable.update_prg_liquids.bind(0))
			factory.created_extractor.connect(pBuildable.update_prg_gasses.bind(0))
		elif pBuildable.buildable_type == 1:
			factory.created_scanner.connect(pBuildable.update_prg_solids.bind(0))
			factory.created_scanner.connect(pBuildable.update_prg_liquids.bind(0))
			factory.created_scanner.connect(pBuildable.update_prg_gasses.bind(0))
		elif pBuildable.buildable_type == 2:
			factory.created_factory.connect(pBuildable.update_prg_solids.bind(0))
			factory.created_factory.connect(pBuildable.update_prg_liquids.bind(0))
			factory.created_factory.connect(pBuildable.update_prg_gasses.bind(0))
	else:
		pBuildable.reparent(grid_inactive_buildables)
		if factory != null:
			factory.remove_buildable_active(pBuildable.buildable_type)
			factory.funded_solids.disconnect(pBuildable.update_prg_solids)
			factory.funded_liquids.disconnect(pBuildable.update_prg_liquids)
			factory.funded_gasses.disconnect(pBuildable.update_prg_gasses)
			
			if pBuildable.buildable_type == 0:
				factory.created_extractor.disconnect(pBuildable.update_prg_solids)
				factory.created_extractor.disconnect(pBuildable.update_prg_liquids)
				factory.created_extractor.disconnect(pBuildable.update_prg_gasses)
			elif pBuildable.buildable_type == 1:
				factory.created_scanner.disconnect(pBuildable.update_prg_solids)
				factory.created_scanner.disconnect(pBuildable.update_prg_liquids)
				factory.created_scanner.disconnect(pBuildable.update_prg_gasses)
			elif pBuildable.buildable_type == 2:
				factory.created_factory.disconnect(pBuildable.update_prg_solids)
				factory.created_factory.disconnect(pBuildable.update_prg_liquids)
				factory.created_factory.disconnect(pBuildable.update_prg_gasses)

func update_pool_solids() -> void:
	prg_solids.value = factory.pool_solids
	prg_solids.max_value = Globals.max_solids
	lbl_solids.text = str("%.2f" % factory.pool_solids) + " / " + str("%.2f" % Globals.max_solids)

func update_pool_liquids() -> void:
	prg_liquids.value = factory.pool_liquids
	prg_liquids.max_value = Globals.max_liquids
	lbl_liquids.text = str("%.2f" % factory.pool_liquids) + " / " + str("%.2f" % Globals.max_liquids)
	
func update_pool_gasses() -> void:
	prg_gasses.value = factory.pool_gasses
	prg_gasses.max_value = Globals.max_gasses
	lbl_gasses.text = str("%.2f" % factory.pool_gasses) + " / " + str("%.2f" % Globals.max_gasses)

func update_factory_panel() -> void:
	lbl_fund.text = "Allocating " + str("%.2f"%Globals.factory_funding_amount)+" every "+str("%.2f"%Globals.factory_funding_interval)+" seconds"


func update_fund_solids(pProgress: float) -> void:
	prg_fund_solids.max_value = Globals.factory_funding_interval
	prg_fund_solids.value = pProgress
	
func update_fund_liquids(pProgress: float) -> void:
	prg_fund_liquids.max_value = Globals.factory_funding_interval
	prg_fund_liquids.value = pProgress
	
func update_fund_gasses(pProgress: float) -> void:
	prg_fund_gasses.max_value = Globals.factory_funding_interval
	prg_fund_gasses.value = pProgress

func _on_btn_make_drills_toggled(toggled_on: bool) -> void:
	if factory != null:
		factory.making_extractors = toggled_on
		update_factory_panel()

func _on_btn_make_probes_toggled(toggled_on: bool) -> void:
	if factory != null:
		factory.making_probes = toggled_on
		update_factory_panel()


func _on_option_button_item_selected(index: int) -> void:
	factory.set_project_0(index)


func _on_option_button_2_item_selected(index: int) -> void:
	factory.set_project_1(index)
