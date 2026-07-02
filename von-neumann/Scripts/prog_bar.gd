extends Line2D

var length = 100
var fill: Line2D

var value: float
var max_value: float

func _ready():
	fill = Line2D.new()
	fill.add_point(Vector2.ZERO)
	fill.add_point(Vector2.ZERO)
	fill.width = width
	add_child(fill)
	
	add_point(Vector2.ZERO)
	add_point(Vector2(length,0))

func set_bar_width(pWidth):
	width = pWidth
	fill.width = pWidth

func set_bar_length(pLength):
	length = pLength
	points[1] = Vector2(length,0)
	fill.points[1] = Vector2((value/max_value)*length,0)
	
func set_bg_color(pColor):
	default_color = pColor
	
func set_fg_color(pColor):
	fill.default_color = pColor

func set_value(pVal):
	value = pVal
	fill.points[1] = Vector2((value/max_value)*length,0)

func set_max_value(pMax):
	max_value = pMax
