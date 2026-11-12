extends Node

#STARS
var star_adjacency_max = 2500
var max_planets_per_star = 7



#FACTORIES
var starting_resource_in_factroy: float = 20.0
var max_resource_stored_in_factory: int = 100
var factory_funding_interval: float = 1.0 # HOW OFTEN TO FACTORIES FUND THEIR PROJECTS
var factory_funding_amount: float = 1.0 # WHEN FACTORIES FUND THEIR PROJECTS, HOW MUCH RESOURCE DO THEY ADD
var factory_orbital_radius: float = 5000
var factory_orbital_focus_dist: float = sqrt(5000 * 5000 + 5000 * 5000)



#EXTRACTORS:
var percentage_added_on_manual_extraction: float = 1.0 # 10.0
var resource_to_make_extractor: float = 10 # 10
var max_extractors_per_planet: int = 1



#PROBES
var resource_to_make_probe: int = 10
var probe_speed = 50



#UTILITY
var split_container_offset_min: int = 0
var split_container_offset_max: int #SET IN game_manager._ready(), DEPENDS ON GET_VIEWPORT_RECT()
var split_container_offset_star_viewer_open: int #SET IN game_manager._ready(), DEPENDS ON GET_VIEWPORT_RECT()
var split_container_offset_planet_viewer_open: int #SET IN game_manager._ready(), DEPENDS ON GET_VIEWPORT_RECT()
var deltaTime: float = 0.0
func _process(delta: float) -> void:
	deltaTime = delta
