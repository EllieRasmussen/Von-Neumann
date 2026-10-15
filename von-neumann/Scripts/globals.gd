extends Node

var max_planets_per_star = 7

var percentage_added_on_manual_extraction: float = 50.0 # 10.0



var max_resource_stored_in_factory: int = 100


var time_factory_make_extractor: float = 10.0 #10.0 #PROBABLY GONNA WANT TO CHANGE THE NAMING SCHEME HERE, JUST EXTRECTING TO HAVE A TON OF VARIABLES
var resource_to_make_extractor: int = 10 #10

var time_factory_make_probe: float = 1
var resource_to_make_probe: int = 1 


var deltaTime: float = 0.0

func _process(delta: float) -> void:
	deltaTime = delta
