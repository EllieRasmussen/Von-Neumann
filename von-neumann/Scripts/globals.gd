extends Node

var max_resource_stored_in_factory: int = 100


var time_factory_make_extractor: float = 10.0 #PROBABLY GONNA WANT TO CHANGE THE NAMING SCHEME HERE, JUST EXTRECTING TO HAVE A TON OF VARIABLES
var resource_to_make_extractor: int = 10

var time_factory_make_probe: float = 60.0
var resource_to_make_probe: int = 100


var deltaTime: float = 0.0

func _process(delta: float) -> void:
	deltaTime = delta
