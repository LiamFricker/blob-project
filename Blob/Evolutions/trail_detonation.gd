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
		createMesh()
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
	
	#var tempShape = Polygon2D.new()
	#tempShape.set_deferred("polygon", pointArr)	
	print("og ", lineArray)
	print(pointArr)
	var tempShape = CollisionPolygon2D.new()
	tempShape.set_deferred("polygon", pointArr)	
	add_child(tempShape)
	
func createMesh() -> void:
	var points : int = lineArray.size()
	var pointArr = PackedVector2Array()
	pointArr.resize(points*2)
	var uvArr = PackedVector2Array()
	uvArr.resize(points*2)
	var points_max = points*2-1
	
	var angleL = lineArray[0].angle_to_point(lineArray[1])
	var angleR = angleL
	var angleAvg = lerp_angle(angleL, angleR, 0.5)
	var pointUp = lineArray[0] + size * Vector2.from_angle(angleAvg + PI/2)
	var pointDown = lineArray[0] + size * Vector2.from_angle(angleAvg - PI/2)
	pointArr[0] = pointUp
	pointArr[1] = pointDown
	uvArr[0] = Vector2(0, 0)
	uvArr[1] = Vector2(0, 1)
	
	for i in range(1, points - 1, 1):
		angleL = lineArray[i].angle_to_point(lineArray[i+1])
		angleR = lineArray[i].angle_to_point(lineArray[i-1]) + PI
		angleAvg = lerp_angle(angleL, angleR, 0.5)
		pointUp = lineArray[i] + size * Vector2.from_angle(angleAvg + PI/2)
		pointDown = lineArray[i] + size * Vector2.from_angle(angleAvg - PI/2)
		pointArr[2*i] = pointUp
		pointArr[2*i+1] = pointDown
		var uvAmt : float = i / (points - 1.0)
		uvArr[2*i] = Vector2(uvAmt, 0)
		uvArr[2*i+1] = Vector2(uvAmt, 1)
		
	
	angleR = lineArray[points-1].angle_to_point(lineArray[points-2]) + PI
	#angleL = angleR
	#angleAvg = lerp_angle(angleL, angleR, 0.5)
	pointUp = lineArray[points - 1] + size * Vector2.from_angle(angleR + PI/2)
	pointDown = lineArray[points - 1] + size * Vector2.from_angle(angleR - PI/2)
	pointArr[points_max-1] = pointUp
	pointArr[points_max] = pointDown
	uvArr[points_max-1] = Vector2(1, 0)
	uvArr[points_max] = Vector2(1, 1)
	
	print((points_max))
	
	"""
	var meshPoints : PackedVector2Array = []
	meshPoints.resize(3 * (points_max - 1))
	for i in range(0, points_max - 1, 1):
		meshPoints[3 * i] = pointArr[i]
		meshPoints[3 * i+1] = pointArr[i+1]
		meshPoints[3 * i+2] = pointArr[i+2]
	"""
	
	
	"""
	= PackedVector2Array([
		Vector2(0, 0),
		Vector2(10, 0),
		Vector2(0, 10),
		Vector2(10, 0),
		Vector2(0, 10),
		Vector2(10, 10),
	])
	"""
	var arr_mesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = pointArr
	arrays[Mesh.ARRAY_TEX_UV] = uvArr
	
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLE_STRIP, arrays)
	
	#var tempShape = MeshInstance2D.new()
	var tempShape = $Meshes/MeshInstance2D
	tempShape.mesh = arr_mesh
	#tempShape.texture = load("res://Art/Cell/Evolutions/SpeedBoostCrystal.png")
	#add_child(tempShape)

func _delete() -> void:
	parentRef.removeChild(self)
	call_deferred("queue_free")
	
#There'll be an animation for this later
func _on_change_timer_timeout() -> void:
	if state == 0:
		state = 1
		size *= 1.5
		#get_child(1).call_deferred("queue_free")
		#call_deferred("set_collision_layer_value", 4, false)
		createMesh()
	else:
		_delete()
