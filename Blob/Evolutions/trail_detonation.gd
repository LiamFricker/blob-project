extends "res://Blob/base_player_attack.gd"

var lineArray : PackedVector2Array
var state = 0
#This shouldn't be here but w/e idc
var min = 0
var rectState = 0
var storedLen = 0
var storedWid = 0

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
	min = size
	
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
		angleR = lineArray[i-1].angle_to_point(lineArray[i])# + PI
		angleAvg = lerp_angle(angleL, angleR, 0.5)
		pointUp = lineArray[i] + size * Vector2.from_angle(angleAvg + PI/2)
		pointDown = lineArray[i] + size * Vector2.from_angle(angleAvg - PI/2)
		pointArr[2*i] = pointUp
		pointArr[2*i+1] = pointDown
		var uvAmt : float = i / (points - 1.0)
		uvArr[2*i] = Vector2(uvAmt, 0)
		uvArr[2*i+1] = Vector2(uvAmt, 1)
		_createCollisionShape(lineArray[i-1].distance_to(lineArray[i]), angleR, angleL, lineArray[i])
		
	
	angleR = lineArray[points-2].angle_to_point(lineArray[points-1])# + PI
	pointUp = lineArray[points - 1] + size * Vector2.from_angle(angleR + PI/2)
	pointDown = lineArray[points - 1] + size * Vector2.from_angle(angleR - PI/2)
	pointArr[points_max-1] = pointUp
	pointArr[points_max] = pointDown
	uvArr[points_max-1] = Vector2(1, 0)
	uvArr[points_max] = Vector2(1, 1)
	_createFinalShape(lineArray[points-2].distance_to(lineArray[points-1]), angleR, lineArray[points-1])
	
	print((points_max))
	
	var arr_mesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = pointArr
	arrays[Mesh.ARRAY_TEX_UV] = uvArr
	
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLE_STRIP, arrays)
	
	$Meshes/MeshInstance2D.mesh = arr_mesh

func _createCollisionShape(disLen : float, angleBef : float, angleAft : float, currPos : Vector2):
	match rectState:
		0:
			#IF the diff is too small for a new collision shape
			if disLen < min:
				min -= size * 0.5
			#If the diff is too long for a circle to be affordable	
			elif disLen > 2.25 * size:
				min = size
				var angleDiff = abs(angle_difference(angleBef, angleAft))
				var minAngle = 0.1*(2.25 * size) / disLen
				var offset = disLen
				#If the angle is small enough to use one big rect
				#Skip this one and make a big rect next time.
				if angleDiff < minAngle:
					rectState = 1
					storedLen += disLen
					storedWid += size * 0.1 * angleDiff / minAngle 
					return
				#If the path retreads over itself
				#Make this rect and skip over the next one.
				elif angleDiff > PI - minAngle:
					rectState = 2
					storedLen += disLen
				#Adjusting the size to account for extra collision space	
				else:
					offset += 0.5 * size * angleDiff / PI
					
				var tempCol = CollisionShape2D.new()
				var tempShape = RectangleShape2D.new()
				tempShape.size = Vector2(offset, size+storedWid)
				tempCol.shape = tempShape
				#Place at the midpoint
				tempCol.position = currPos - disLen * 0.5 * Vector2.from_angle(angleBef)
				call_deferred("add_child", tempCol)
				storedWid = 0
			#If the diff is too small for a rectangle to be affordable. Max sep with mins is ~2.75*size
			else:
				min = size * 1.5 + storedWid
				var tempCol = CollisionShape2D.new()
				var tempShape = CircleShape2D.new()
				tempShape.radius = 1.5 * size + storedWid
				tempCol.shape = tempShape
				tempCol.position = currPos
				call_deferred("add_child", tempCol)
				storedWid = 0
					
		1:
			var angleDiff = abs(angle_difference(angleBef, angleAft))
			var minAngle = 0.1*(2.25 * size) / disLen
			var offset = disLen + storedLen
			if angleDiff < minAngle:
				rectState = 1
				storedLen += disLen
				storedWid += size * 0.1 * angleDiff / minAngle 
				return
			#If the path retreads over itself
			#Make this rect and skip over the next one.
			elif angleDiff > PI - minAngle:
				rectState = 2
			#Adjusting the size to account for extra collision space	
			else:
				offset += 0.5 * size * angleDiff / PI
				rectState = 0
				storedLen = 0
				
			var tempCol = CollisionShape2D.new()
			var tempShape = RectangleShape2D.new()
			tempShape.size = Vector2(offset, size+storedWid)
			tempCol.shape = tempShape
			#Place at the midpoint
			tempCol.position = currPos - disLen * 0.5 * Vector2.from_angle(angleBef)
			call_deferred("add_child", tempCol)
			storedWid = 0
		2:
			var angleDiff = abs(angle_difference(angleBef, angleAft))
			var minAngle = 0.1*(2.25 * size) / disLen
			
			#If currentLen longer than the previous rectangle, make a tiny rect
			if disLen > storedLen:
				var tempCol = CollisionShape2D.new()
				var tempShape = RectangleShape2D.new()
				#Make a tiny rect with the length of the difference
				tempShape.size = Vector2(disLen-storedLen, size+storedWid)
				tempCol.shape = tempShape
				#Place at just behind the previous rect
				tempCol.position = currPos - (disLen+storedLen) * 0.5 * Vector2.from_angle(angleBef)
				call_deferred("add_child", tempCol)
				storedWid = 0
				storedLen = 0
				rectState = 0
			#If in the same direction, skip over the next one too, shorten the total len
			elif angleDiff < minAngle:
				rectState = 2
				storedLen -= disLen
				storedWid += size * 0.1 * angleDiff / minAngle 
			#If the path retreads over itself again, set the storedlen to this rect's len
			elif angleDiff > PI - minAngle:
				storedLen = disLen
				rectState = 2
				storedWid += size * 0.1 * angleDiff / minAngle 
			#Let the next shape be normal
			else:
				storedLen = 0
				rectState = 0

func _createFinalShape(disLen : float, angleBef : float, currPos : Vector2):
	match rectState:
		0:
			#If the diff is too long for a circle to be affordable	
			if disLen > 2.25 * size:					
				var tempCol = CollisionShape2D.new()
				var tempShape = RectangleShape2D.new()
				tempShape.size = Vector2(disLen, size+storedWid)
				tempCol.shape = tempShape
				#Place at the midpoint
				tempCol.position = currPos - disLen * 0.5 * Vector2.from_angle(angleBef)
				call_deferred("add_child", tempCol)
			#If the diff is too small for a rectangle to be affordable. Max sep with mins is ~2.75*size
			elif disLen >= min:
				var tempCol = CollisionShape2D.new()
				var tempShape = CircleShape2D.new()
				tempShape.radius = 1.5 * size + storedWid
				tempCol.shape = tempShape
				tempCol.position = currPos
				call_deferred("add_child", tempCol)
			storedWid = 0
		1:	
			var tempCol = CollisionShape2D.new()
			var tempShape = RectangleShape2D.new()
			tempShape.size = Vector2(disLen + storedLen, size+storedWid)
			tempCol.shape = tempShape
			#Place at the midpoint
			tempCol.position = currPos - disLen * 0.5 * Vector2.from_angle(angleBef)
			call_deferred("add_child", tempCol)
			storedWid = 0
			rectState = 0
		2:
			#If currentLen longer than the previous rectangle, make a tiny rect
			if disLen > storedLen:
				var tempCol = CollisionShape2D.new()
				var tempShape = RectangleShape2D.new()
				#Make a tiny rect with the length of the difference
				tempShape.size = Vector2(disLen-storedLen, size+storedWid)
				tempCol.shape = tempShape
				#Place at just behind the previous rect
				tempCol.position = currPos - (disLen+storedLen) * 0.5 * Vector2.from_angle(angleBef)
				call_deferred("add_child", tempCol)
			storedWid = 0
			storedLen = 0
			rectState = 0

func _delete() -> void:
	parentRef.removeChild(self)
	call_deferred("queue_free")
	
#There'll be an animation for this later
func _on_change_timer_timeout() -> void:
	if state == 0:
		state = 1
		#size *= 1.5
		#get_child(1).call_deferred("queue_free")
		#call_deferred("set_collision_layer_value", 4, false)
		#createMesh()
	else:
		_delete()
