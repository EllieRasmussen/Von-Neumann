extends PathFollow2D

var banked_progress: float = 0.0

func process_on_screen(delta_progress: float) -> void:
	progress_ratio += delta_progress

func process_off_screen(delta_progress: float) -> void:
	banked_progress += delta_progress

func bank_progress() -> void:
	banked_progress += progress_ratio

func update() -> void:
	progress_ratio = banked_progress
	banked_progress = 0.0

func get_real_progress() -> float:
	return progress_ratio + banked_progress


var print_progress: bool = false
