extends "res://Blob/base_player_attack.gd"

var lineArray : PackedVector2Array
var state = 0

#Remove the functionality of ready
func _ready() -> void:
	pass

func setParams(dmg : float, kb : float, pR : Node2D, sz = 0.0) -> void:
	super(dmg, kb, pR, sz)

func initLines(positions : PackedVector2Array) -> void:
	lineArray = positions
	createShape()

func createShape() -> void:
	var points : int = lineArray.size()
	var pointArr = PackedVector2Array()
	pointArr.resize(points*2)
	var points_max = points*2-1
	
	var angleL = lineArray[0].angle_to_point(lineArray[1])
	var angleR = angleL
	var angleAvg = lerp_angle(angleL, angleR, 0.5)
	var pointUp = size * Vector2.from_angle(angleAvg + PI/2)
	var pointDown = size * Vector2.from_angle(angleAvg - PI/2)
	pointArr[0] = pointUp
	pointArr[points_max] = pointDown
	
	for i in range(1, points - 1, 1):
		angleL = lineArray[i].angle_to_point(lineArray[i+1])
		angleR = -lineArray[i].angle_to_point(lineArray[i-1])
		angleAvg = lerp_angle(angleL, angleR, 0.5)
		pointUp = size * Vector2.from_angle(angleAvg + PI/2)
		pointDown = size * Vector2.from_angle(angleAvg - PI/2)
		pointArr[i] = pointUp
		pointArr[points_max-i] = pointDown
	
	angleR = -lineArray[points-1].angle_to_point(lineArray[points-2])
	angleL = angleR
	angleAvg = lerp_angle(angleL, angleR, 0.5)
	pointUp = size * Vector2.from_angle(angleAvg + PI/2)
	pointDown = size * Vector2.from_angle(angleAvg - PI/2)
	pointArr[points - 1] = pointUp
	pointArr[points] = pointDown
	
	var tempShape = Polygon2D.new()
	tempShape.set_deferred("polygon", pointArr)	

func _delete() -> void:
	parentRef.removeChild(self)
	call_deferred("queue_free")
	
#There'll be an animation for this later
func _on_change_timer_timeout() -> void:
	if state == 0:
		state = 1
		size *= 1.5
		call_deferred("set_collision_layer_value", 4, false)
		createShape()
	else:
		_delete()
