extends Node

var star_adjacency_max = 2500

var max_planets_per_star = 7

var percentage_added_on_manual_extraction: float = 50.0 # 10.0


var starting_resource_in_factroy: int = 10
var max_resource_stored_in_factory: int = 100


var time_factory_make_extractor: float = 0.1#10.0 #PROBABLY GONNA WANT TO CHANGE THE NAMING SCHEME HERE, JUST EXTRECTING TO HAVE A TON OF VARIABLES
var resource_to_make_extractor: int = 1 #10

var max_extractors_per_planet: int = 10

var time_factory_make_probe: float = 10
var resource_to_make_probe: int = 100


var deltaTime: float = 0.0

func _process(delta: float) -> void:
	deltaTime = delta
