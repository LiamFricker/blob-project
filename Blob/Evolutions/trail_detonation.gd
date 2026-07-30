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
	if lineArray.size() > 1:
		createShape()
	else:
		print("trail too smol")

func createShape() -> void:
	var points : int = lineArray.size()
	var pointArr = PackedVector2Array()
	pointArr.resize(points*2)
	var points_max = points*2-1
	
	var angleL = lineArray[0].angle_to_point(lineArray[1])
	var angleR = angleL
	var angleAvg = lerp_angle(angleL, angleR, 0.5)
	var pointUp = lineArray[0] + size * Vector2.from_angle(angleAvg + PI/2)
	var pointDown = lineArray[0] + size * Vector2.from_angle(angleAvg - PI/2)
	pointArr[0] = pointUp
	pointArr[points_max] = pointDown
	print(angleAvg)
	
	for i in range(1, points - 1, 1):
		angleL = lineArray[i].angle_to_point(lineArray[i+1])
		angleR = lineArray[i].angle_to_point(lineArray[i-1]) + PI
		angleAvg = lerp_angle(angleL, angleR, 0.5)
		pointUp = lineArray[i] + size * Vector2.from_angle(angleAvg + PI/2)
		pointDown = lineArray[i] + size * Vector2.from_angle(angleAvg - PI/2)
		pointArr[i] = pointUp
		pointArr[points_max-i] = pointDown
		print(angleL)
		print(angleR)
		print(angleAvg)
	
	angleR = lineArray[points-1].angle_to_point(lineArray[points-2]) + PI
	#angleL = angleR
	#angleAvg = lerp_angle(angleL, angleR, 0.5)
	print(angleR)
	pointUp = lineArray[points - 1] + size * Vector2.from_angle(angleR + PI/2)
	pointDown = lineArray[points - 1] + size * Vector2.from_angle(angleR - PI/2)
	pointArr[points - 1] = pointUp
	pointArr[points] = pointDown
	
	var tempShape = CollisionPolygon2D.new()
	tempShape.set_deferred("polygon", pointArr)	
	print("og ", lineArray)
	print(pointArr)
	add_child(tempShape)

func _delete() -> void:
	parentRef.removeChild(self)
	call_deferred("queue_free")
	
#There'll be an animation for this later
func _on_change_timer_timeout() -> void:
	if state == 0:
		state = 1
		size *= 1.5
		get_child(1).call_deferred("queue_free")
		call_deferred("set_collision_layer_value", 4, false)
		createShape()
	else:
		_delete()
