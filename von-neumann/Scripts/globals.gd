extends Node

var viewport_stars: SubViewport #IF THIS IS STILL IN THE GAME AT LAUNCH THEN YOU HAVE THE RIGHT TO KILL ME

var world_bound: float = 50000


# NOT A BIG FAN OF THIS BUT WE NEED A WAY TO STORE THE ARBITRARY DATA OF WHICH BUILDABLES COST WHAT AMOUNT OF WHICH RESOURCES
# ECAH VECTOR3 REPRESENTS A COST AS (SOLIDS, LIQUIDS, GASSES)
# [0] -> DRILLS
# [1] -> SCANNERS
# [2] -> FACTORIES
var build_costs: Array[Vector3] = [
	Vector3(1,1,0),
	Vector3(1,0,1),
	Vector3(1,1,1)
]

signal cost_drill_changed
func set_cost_drill(pCost: Vector3) -> void:
	build_costs[0] = pCost
	cost_drill_changed.emit(build_costs[0])

signal cost_scanner_changed
func set_cost_scanner(pCost: Vector3) -> void:
	build_costs[1] = pCost
	cost_scanner_changed.emit(build_costs[1])

signal cost_factory_changed
func set_cost_factory(pCost: Vector3) -> void:
	build_costs[2] = pCost
	cost_factory_changed.emit(build_costs[2])

func _ready():
	set_cost_drill(Vector3(10,10,0))
	set_cost_scanner(Vector3(10,0,10))
	set_cost_factory(Vector3(10,10,10))

#STARS
var star_adjacency_max = 2500
var max_planets_per_star = 7




#DRILLS:
var percentage_added_on_manual_extraction: float = 1.0 # 10.0
var max_extractors_per_planet: int = 1



#SCANNERS
var scanner_probe_speed: float = 50
var scanner_probe_travel_dist: float = 100000 # LIGHTYEARS



#FACTORIES
var factory_probe_speed: float = 50
var factory_probe_travel_dist: float = 50

var starting_resource_in_factroy: float = 0
var max_solids: float = 10
var max_liquids: float = 10
var max_gasses: float = 10
var factory_funding_interval: float = 1.0 # HOW OFTEN TO FACTORIES FUND THEIR PROJECTS
var factory_funding_amount: float = 1.0 # WHEN FACTORIES FUND THEIR PROJECTS, HOW MUCH RESOURCE DO THEY ADD
var factory_orbital_radius: float = 5000
var factory_orbital_focus_dist: float = sqrt(5000 * 5000 + 5000 * 5000)











#UTILITY
var split_container_offset_min: int = 0
var split_container_offset_max: int #SET IN game_manager._ready(), DEPENDS ON GET_VIEWPORT_RECT()
var split_container_offset_star_viewer_open: int #SET IN game_manager._ready(), DEPENDS ON GET_VIEWPORT_RECT()
var split_container_offset_planet_viewer_open: int #SET IN game_manager._ready(), DEPENDS ON GET_VIEWPORT_RECT()
var deltaTime: float = 0.0
func _process(delta: float) -> void:
	deltaTime = delta
