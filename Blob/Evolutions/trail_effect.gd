extends Line2D

var point_array : PackedVector2Array = [Vector2.ZERO]
var size = 1
var max_size = 10
var decay_time 

func changeWidth(newWidth : float) -> void:
	width = newWidth

func _ready() -> void:
	start()

func start() -> void:
	#points = point_array
	clear_points()
	show()

func addPosition(newPos : Vector2) -> void:
	
	if size >= max_size:
		#point_array.remove_at(max_size - 1)
		remove_point(0)
	else:
		size += 1
	#for v in point_array:
	#	v += newPos
	#point_array.insert(1, newPos)
	#points = point_array
	add_point(newPos)

func beginDecay() -> void:
	if size >= 1:
		size -= 1
		#point_array.remove_at(size)
		#points = point_array
		remove_point(max_size-1)
		$DecayTimer.start()
	else:
		hide()
	
