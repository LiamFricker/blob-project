extends Line2D

var point_array : PackedVector2Array = [Vector2.ZERO]
var size = 1
var max_size = 5
var decay_time 

func changeWidth(newWidth : float) -> void:
	width = newWidth

func start() -> void:
	points = point_array
	show()

func addPosition(newPos : Vector2) -> void:
	if size >= max_size:
		point_array.remove_at(max_size - 1)
	for v in point_array:
		v += newPos
	point_array.insert(1, newPos)
	size += 1
	points = point_array

func beginDecay() -> void:
	if size >= 1:
		point_array.remove_at(max_size - 1)
		points = point_array
		$DecayTimer.start()
	else:
		hide()
	
