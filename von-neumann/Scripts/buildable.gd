@tool extends VBoxContainer
class_name Buildable

@export var buildable_type: int = 0
@export var sprite: Texture2D:
	set(new_value):
		sprite = new_value
		texture_rect.texture = sprite
@export var buildable_name: String:
	set(new_value):
		buildable_name = new_value
		lbl_name.text = buildable_name

@export var uses_solids: bool = true:
	set(new_val):
		uses_solids = new_val
		if uses_solids:
			icon_solids.visible = true
			icon_solids_small.visible = true
			prg_solids.visible = true
		else:
			icon_solids.visible = false
			icon_solids_small.visible = false
			prg_solids.visible = false

@export var uses_liquids: bool = true:
	set(new_val):
		uses_liquids = new_val
		if uses_liquids:
			icon_liquids.visible = true
			icon_liquids_small.visible = true
			prg_liquids.visible = true
		else:
			icon_liquids.visible = false
			icon_liquids_small.visible = false
			prg_liquids.visible = false
			

@export var uses_gasses: bool = true:
	set(new_val):
		uses_gasses = new_val
		if uses_gasses:
			icon_gasses.visible = true
			icon_gasses_small.visible = true
			prg_gasses.visible = true
		else:
			icon_gasses.visible = false
			icon_gasses_small.visible = false
			prg_gasses.visible = false

@export var lbl_name: Label
@export var panel: Panel
@export var texture_rect: TextureRect
@export var resources: Container
@export var progress_bars: Control

@export var icon_solids: TextureRect
@export var icon_solids_small: TextureRect
@export var icon_liquids: TextureRect
@export var icon_liquids_small: TextureRect
@export var icon_gasses: TextureRect
@export var icon_gasses_small: TextureRect

@export var prg_solids: ProgressBar
@export var prg_liquids: ProgressBar
@export var prg_gasses: ProgressBar

@export var dim: ColorRect

signal changed_active
@export var active: bool = true:
	set(new_value):
		active = new_value
		if active:
			progress_bars.visible = true
			panel.custom_minimum_size = Vector2(128,128)
			resources.visible = true
			texture_rect.size = Vector2(64,64)
			texture_rect.position = Vector2(0,-16)
			dim.visible = false
		else:
			progress_bars.visible = false
			panel.custom_minimum_size = Vector2(64,64)
			resources.visible = false
			texture_rect.size = Vector2(48,48)
			texture_rect.position = Vector2(40,40)
		changed_active.emit()



func update_prg_solids(pAmount: float) -> void:
	if pAmount == 0:
		prg_solids.value = 0
		return
	prg_solids.value += pAmount
func prg_solids_set_max(pMax: Vector3) -> void:
	prg_solids.max_value = pMax[0]

func update_prg_liquids(pAmount: float) -> void:
	if pAmount == 0:
		prg_liquids.value = 0
		return
	prg_liquids.value += pAmount
func prg_liquids_set_max(pMax: Vector3) -> void:
	prg_liquids.max_value = pMax[1]

func update_prg_gasses(pAmount: float) -> void:
	if pAmount == 0:
		prg_gasses.value = 0
		return
	prg_gasses.value += pAmount
func prg_gasses_set_max(pMax: Vector3) -> void:
	prg_gasses.max_value = pMax[2]



func _on_panel_gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("Click"):
		active = not active


func _on_panel_mouse_entered() -> void:
	if not active:
		dim.visible = true


func _on_panel_mouse_exited() -> void:
	dim.visible = false
