# THIS CLASS HANDLES THE UI BEHAVIOR OF UPGRADE BUTTONS, FOR BUTTON BEHAVIOR SEE UPGRADE_MANAGER
@tool 
extends HBoxContainer

@export var property_to_alter: String:
	set(new_val):
		property_to_alter = new_val
		
var sample_delta: float = 0.1
@export var max_upgrades: int = 1

@export var curve: Curve

@export var property_name: String:
	set(new_val):
		property_name = new_val
		lbl_property.text = new_val + ": "
		
var current_sample: float = 0:
	set(new_val):
		current_sample = new_val
		if is_int:
			lbl_value.text = str(int(round(curve.sample(current_sample)))) + " "
		else:
			lbl_value.text = str("%.2f" % curve.sample(current_sample)) + " "
		
var next_sample: float = 1:
	set(new_val):
		next_sample = new_val
		if is_int:
			lbl_next.text = "+" + str(int(round(curve.sample(next_sample))-round(curve.sample(current_sample))))
		else:
			lbl_next.text = "+" + str("%.2f" % (curve.sample(next_sample)-curve.sample(current_sample)))
		
@export var unit: String:
	set(new_val):
		unit = new_val
		lbl_unit.text = new_val + " "

@export var is_int: bool = false:
	set(new_val):
		is_int = new_val
		if is_int:
			lbl_value.text = str(int(curve.sample(current_sample))) + " "
		else:
			lbl_value.text = str("%.2f" % curve.sample(current_sample)) + " "

@export var lbl_property: Label
@export var lbl_value: Label
@export var lbl_unit: Label
@export var lbl_next: Label

func _ready() -> void:
	sample_delta = curve.max_domain / max_upgrades
	next_sample = sample_delta

func _on_btn_purchase_mouse_entered() -> void:
	lbl_next.visible = true


func _on_btn_purchase_mouse_exited() -> void:
	lbl_next.visible = false


func _on_btn_purchase_button_down() -> void:
	Globals.set(property_to_alter,curve.sample(next_sample))
	current_sample = next_sample
	next_sample += sample_delta
