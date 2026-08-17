extends Node2D

#Ngl I don't give a shit about optimizing this
#Let's just disable the ones we don't need and call it a day

@export var parentRef : Node2D
@onready var timer_ref = $SearchDelay

@export var tentacle_total = 9
@export var tentacleLength:int = 8
#I have no idea what this means but I'm keeping it for now ig...
@export var tentacleAlphaAmount:int = 0
#@export var tentacle_scene : PackedScene

@onready var tentacle_list = [$Tentacle0, $Tentacle1, $Tentacle2, $Tentacle3, $Tentacle4, $Tentacle5, $Tentacle6, $Tentacle7, $Tentacle8]
var tentacle_tween
var shader_update : bool = false #_tween 
var shader_update_tween 

var chargeTentacleSpin : float = 0.0
var reverseTentacleSpin : float = 0.0

#signal orb_collection(value, orbpos, enemy_drop, currency_type)

func collect(value : int, orbpos : Vector2, enemy_drop : bool, currency_type = 0) -> void:
	#orb_collection.emit(value, orbpos, enemy_drop, currency_type)
	parentRef.collect(value, orbpos, enemy_drop, currency_type)

func getID() -> int:
	return parentRef.getID()

#These variables all go into the Area2D collision. 
func getParent() -> Node2D:
	return parentRef

#Change this to the position of the tip.
#Or the movement object
func getPosition() -> Vector2:
	return position + parentRef.getPosition() 

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if shader_update:
		updateTentacleShader()
	
	
"""
func createTentacle(count : int) -> void:
	var tempTentacle = tentacle_scene.instantiate()
	tentacle_list.append(tempTentacle)
	add_child(tempTentacle)
"""

func shaderNewDirection(new_dir : int) -> void:
	if new_dir == 0 and shader_update:
		if shader_update_tween:
			shader_update_tween.kill()
		shader_update_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_LINEAR)
		shader_update_tween.tween_property(self, "chargeTentacleSpin", 0.0, 0.5)
		shader_update_tween.finished.connect(_cancelShaderTween)
	else:
		shader_update = true
		if shader_update_tween:
			shader_update_tween.kill()
		if abs(chargeTentacleSpin) > 0:
			shader_update_tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_LINEAR)
			shader_update_tween.tween_property(self, "chargeTentacleSpin", -0.8 * new_dir, 0.4)
		else:
			shader_update_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_LINEAR)
			shader_update_tween.tween_property(self, "chargeTentacleSpin", -0.8 * new_dir, 0.25)

func updateTentacles(upgraded = false) -> void:
	match tentacle_total:
		1:
			$Tentacle4.enable()
		2:
			if upgraded:
				$Tentacle4.disable()
			$Tentacle2.enable()
			$Tentacle6.enable()
		3:
			if upgraded:
				$Tentacle2.disable()
				$Tentacle6.disable()
			$Tentacle1.enable()
			$Tentacle4.enable()
			$Tentacle7.enable()
		4:
			if upgraded:
				$Tentacle4.disable()
			else:
				$Tentacle1.enable()
				$Tentacle7.enable()
			$Tentacle3.enable()
			$Tentacle5.enable()
		5:
			if upgraded:
				$Tentacle3.disable()
				$Tentacle5.disable()
			else:
				$Tentacle1.enable()
				$Tentacle7.enable()
			$Tentacle2.enable()
			$Tentacle4.enable()
			$Tentacle6.enable()
		6:
			if upgraded:
				$Tentacle2.disable()
				$Tentacle4.disable()
				$Tentacle6.disable()
			else:
				$Tentacle1.enable()
				$Tentacle7.enable()
			$Tentacle3.enable()
			$Tentacle5.enable()
			$Tentacle0.enable()
			$Tentacle8.enable()
		7:
			if upgraded:
				$Tentacle3.disable()
				$Tentacle5.disable()
			else:
				$Tentacle1.enable()
				$Tentacle7.enable()
				$Tentacle0.enable()
				$Tentacle8.enable()
			$Tentacle2.enable()
			$Tentacle4.enable()
			$Tentacle6.enable()
		8:
			if upgraded:
				$Tentacle4.disable()
			else:
				$Tentacle1.enable()
				$Tentacle7.enable()
				$Tentacle0.enable()
				$Tentacle8.enable()
				$Tentacle2.enable()
				$Tentacle6.enable()
			$Tentacle3.enable()
			$Tentacle5.enable()
		9:
			if not upgraded:
				$Tentacle1.enable()
				$Tentacle7.enable()
				$Tentacle0.enable()
				$Tentacle8.enable()
				$Tentacle2.enable()
				$Tentacle6.enable()
				$Tentacle3.enable()
				$Tentacle5.enable()
			$Tentacle4.enable()

func resetCharge() -> void:#distance:float, angle:float) -> void:
	for t in tentacle_list:
		t.tentConfig()
	

#I HATE THIS I WANT THIS TO LOOK BETTER THIS IS DISGUSTING DISGUSTING 
#Oh well another time when I'm better at coding 
#hopefully I can smooth it out in testing
#Let's keep this one this way since this might be called every frame. 
#If we find a better way of doing that (I have one in my brain)
#We can change it to the more visually pleasing way

func startTentacleShader() -> void:
	shader_update = true
	#if not shader_update_tween:
	#	shader_update_tween = create_tween().set_loops()
	#	shader_update_tween.tween_callback(updateTentacleShader).set_delay(0.02)

#I think let's just screw efficiency
#At the end of the day, if 9 tentacles is causing a notable issue, you already have a big issue.
#Just tween all of them at all times, so that it looks consistent when you buy new ones.
func handleTentacleShader(cTS : float) -> void:
	chargeTentacleSpin = cTS
	
	"""
	match tentacle_total:
		1:
			tentacle_list[4].setDirection(chargeTentacleSpin)
		2:
			tentacle_list[2].setDirection(chargeTentacleSpin)
			tentacle_list[6].setDirection(chargeTentacleSpin)
		3:
			tentacle_list[1].setDirection(chargeTentacleSpin+reverseTentacleSpin)
			tentacle_list[4].setDirection(chargeTentacleSpin)
			tentacle_list[7].setDirection(chargeTentacleSpin-reverseTentacleSpin)
		4:
			tentacle_list[1].setDirection(chargeTentacleSpin+reverseTentacleSpin)
			tentacle_list[3].setDirection(chargeTentacleSpin+reverseTentacleSpin*2)
			tentacle_list[5].setDirection(chargeTentacleSpin-reverseTentacleSpin*2)
			tentacle_list[7].setDirection(chargeTentacleSpin-reverseTentacleSpin)
		5:
			tentacle_list[1].setDirection(chargeTentacleSpin+reverseTentacleSpin)
			tentacle_list[2].setDirection(chargeTentacleSpin+reverseTentacleSpin*2)
			
			tentacle_list[4].setDirection(chargeTentacleSpin)
			
			tentacle_list[6].setDirection(chargeTentacleSpin-reverseTentacleSpin*2)
			tentacle_list[7].setDirection(chargeTentacleSpin-reverseTentacleSpin)
		6:
			tentacle_list[0].setDirection(chargeTentacleSpin+reverseTentacleSpin)
			tentacle_list[1].setDirection(chargeTentacleSpin+reverseTentacleSpin*2)
			tentacle_list[3].setDirection(chargeTentacleSpin+reverseTentacleSpin*3)
						
			tentacle_list[5].setDirection(chargeTentacleSpin-reverseTentacleSpin*3)
			tentacle_list[7].setDirection(chargeTentacleSpin-reverseTentacleSpin*2)
			tentacle_list[8].setDirection(chargeTentacleSpin-reverseTentacleSpin)
		7:
			tentacle_list[0].setDirection(chargeTentacleSpin+reverseTentacleSpin)
			tentacle_list[1].setDirection(chargeTentacleSpin+reverseTentacleSpin*2)
			tentacle_list[2].setDirection(chargeTentacleSpin+reverseTentacleSpin*3)
			
			tentacle_list[4].setDirection(chargeTentacleSpin)
			
			tentacle_list[6].setDirection(chargeTentacleSpin-reverseTentacleSpin*3)
			tentacle_list[7].setDirection(chargeTentacleSpin-reverseTentacleSpin*2)
			tentacle_list[8].setDirection(chargeTentacleSpin-reverseTentacleSpin)
		8:
			tentacle_list[0].setDirection(chargeTentacleSpin+reverseTentacleSpin)
			tentacle_list[1].setDirection(chargeTentacleSpin+reverseTentacleSpin*2)
			tentacle_list[2].setDirection(chargeTentacleSpin+reverseTentacleSpin*3)
			tentacle_list[3].setDirection(chargeTentacleSpin+reverseTentacleSpin*4)
						
			tentacle_list[5].setDirection(chargeTentacleSpin-reverseTentacleSpin*4)
			tentacle_list[6].setDirection(chargeTentacleSpin-reverseTentacleSpin*3)
			tentacle_list[7].setDirection(chargeTentacleSpin-reverseTentacleSpin*2)
			tentacle_list[8].setDirection(chargeTentacleSpin-reverseTentacleSpin)
		9:
	"""

func updateTentacleShader() -> void:
	tentacle_list[0].setDirection(chargeTentacleSpin+reverseTentacleSpin)
	tentacle_list[1].setDirection(chargeTentacleSpin+reverseTentacleSpin*2)
	tentacle_list[2].setDirection(chargeTentacleSpin+reverseTentacleSpin*3)
	tentacle_list[3].setDirection(chargeTentacleSpin+reverseTentacleSpin*4)
	
	tentacle_list[4].setDirection(chargeTentacleSpin)
	
	tentacle_list[5].setDirection(chargeTentacleSpin-reverseTentacleSpin*4)
	tentacle_list[6].setDirection(chargeTentacleSpin-reverseTentacleSpin*3)
	tentacle_list[7].setDirection(chargeTentacleSpin-reverseTentacleSpin*2)
	tentacle_list[8].setDirection(chargeTentacleSpin-reverseTentacleSpin)

"""
	Tentacle Amounts:
	0:
	1: 4
	2: 26
	3: 147
	4: 1357
	5: 12467
	6: 013578
	7: 0124678
	8: 01235678
	9: 012345678
	4: 1,3,7,9
	26: 2,5,7,8,9
	35: 4,6,8,9
	17: 3+
	08: 6+
"""

func _cancelShaderTween() -> void:
	#if shader_update_tween:	
	#	shader_update_tween.kill()
	shader_update = false
	reverseTentacleSpin = 0.0
	chargeTentacleSpin = 0.0
	updateTentacleShader()
	
func handleTentacleSqueeze(charge_max : float):
	if tentacle_tween:
		tentacle_tween.kill()
	tentacle_tween = create_tween().set_parallel()
	#Don't bother making this efficient, just make it readable please.
	#if tentacle_total >= 6: 
	tentacle_tween.tween_property(tentacle_list[0], "position", Vector2(4, -2), charge_max)
	tentacle_tween.tween_property(tentacle_list[8], "position", Vector2(-4, -2), charge_max)
		
	#if tentacle_total >= 7 or tentacle_total == 2 or tentacle_total == 5:
	tentacle_tween.tween_property(tentacle_list[2], "position", Vector2(4, 2), charge_max)
	tentacle_tween.tween_property(tentacle_list[6], "position", Vector2(-4, 2), charge_max)
	
	#if tentacle_total >= 8 or tentacle_total == 4 or tentacle_total == 9:
	tentacle_tween.tween_property(tentacle_list[3], "position", Vector2(2, 2), charge_max)
	tentacle_tween.tween_property(tentacle_list[5], "position", Vector2(-2, 2), charge_max)
	
	#if tentacle_total % 2 == 1 and tentacle_total != 5:
	tentacle_tween.tween_property(tentacle_list[4], "position", Vector2(0, 2), charge_max)

func handleTentacleChargeSwipe(temp : float, charge_cd : float) -> void:
	var swipePos : float = min(0.08 * charge_cd, 0.2)
	var retPos : float = min(0.3 * charge_cd, 0.4)
	var retRot : float = min(0.6 * charge_cd, 0.8)
	
	if tentacle_tween:
		tentacle_tween.kill()
	tentacle_tween = create_tween().set_parallel()
	
	#Shader tweens
	tentacle_tween.tween_property(self, "reverseTentacleSpin", 1.0, swipePos)
	tentacle_tween.tween_property(self, "chargeTentacleSpin", 0.0, 2 * swipePos)
	tentacle_tween.tween_property(self, "reverseTentacleSpin", 0.0, retPos).set_delay(swipePos)
	tentacle_tween.tween_callback(_cancelShaderTween).set_delay(swipePos+retPos)
	
	#if not shader_update_tween:
	#	shader_update_tween = create_tween().set_loops()
	#	shader_update_tween.tween_callback(updateTentacleShader).set_delay(0.02)
	shader_update = true
	
	#if tentacle_total >= 6: 
	tentacle_tween.tween_property(tentacle_list[0], "position", Vector2(4, -4-3.6*temp), swipePos)
	tentacle_tween.tween_property(tentacle_list[8], "position", Vector2(-4, -4-3.6*temp), swipePos)
	
	tentacle_tween.tween_property(tentacle_list[0], "rotation", PI/2, retPos)
	tentacle_tween.tween_property(tentacle_list[8], "rotation", PI/2, retPos)
	
	tentacle_tween.tween_property(tentacle_list[0], "position", Vector2(4, -4), retPos).set_delay(swipePos)
	tentacle_tween.tween_property(tentacle_list[8], "position", Vector2(-4, -4), retPos).set_delay(swipePos)
	
	tentacle_tween.tween_property(tentacle_list[0], "rotation", -PI/4, retRot).set_delay(retPos)
	tentacle_tween.tween_property(tentacle_list[8], "rotation", 5*PI/4, retRot).set_delay(retPos)
	
	#if tentacle_total >= 3:
	tentacle_tween.tween_property(tentacle_list[1], "position", Vector2(6, -3.6*temp), swipePos)
	tentacle_tween.tween_property(tentacle_list[7], "position", Vector2(-6, -3.6*temp), swipePos)
	
	tentacle_tween.tween_property(tentacle_list[1], "rotation", PI/2, retPos)
	tentacle_tween.tween_property(tentacle_list[7], "rotation", PI/2, retPos)
	
	tentacle_tween.tween_property(tentacle_list[1], "position", Vector2(8, 0), retPos).set_delay(swipePos)
	tentacle_tween.tween_property(tentacle_list[7], "position", Vector2(-8, 0), retPos).set_delay(swipePos)
	
	tentacle_tween.tween_property(tentacle_list[1], "rotation", 0, retRot).set_delay(retPos)
	tentacle_tween.tween_property(tentacle_list[7], "rotation", PI, retRot).set_delay(retPos)
		
	#if tentacle_total >= 7 or tentacle_total == 2 or tentacle_total == 5:
	tentacle_tween.tween_property(tentacle_list[2], "position", Vector2(4, 4-3.6*temp), swipePos)
	tentacle_tween.tween_property(tentacle_list[6], "position", Vector2(-4, 4-3.6*temp), swipePos)
	
	tentacle_tween.tween_property(tentacle_list[2], "rotation", PI/2, retPos)
	tentacle_tween.tween_property(tentacle_list[6], "rotation", PI/2, retPos)
	
	tentacle_tween.tween_property(tentacle_list[2], "position", Vector2(4, 4), retPos).set_delay(swipePos)
	tentacle_tween.tween_property(tentacle_list[6], "position", Vector2(-4, 4), retPos).set_delay(swipePos)
	
	tentacle_tween.tween_property(tentacle_list[2], "rotation", PI/4, retRot).set_delay(retPos)
	tentacle_tween.tween_property(tentacle_list[6], "rotation", 3*PI/4, retRot).set_delay(retPos)
		
	#if tentacle_total >= 8 or tentacle_total == 4 or tentacle_total == 9:
	tentacle_tween.tween_property(tentacle_list[3], "position", Vector2(2, 6-3.6*temp), swipePos)
	tentacle_tween.tween_property(tentacle_list[5], "position", Vector2(-2, 6-3.6*temp), swipePos)
	
	tentacle_tween.tween_property(tentacle_list[3], "rotation", PI/2, retPos)
	tentacle_tween.tween_property(tentacle_list[5], "rotation", PI/2, retPos)
	
	tentacle_tween.tween_property(tentacle_list[3], "position", Vector2(2, 6), retPos).set_delay(swipePos)
	tentacle_tween.tween_property(tentacle_list[5], "position", Vector2(-2, 6), retPos).set_delay(swipePos)
	
	tentacle_tween.tween_property(tentacle_list[3], "rotation", 3*PI/8, retRot).set_delay(retPos)
	tentacle_tween.tween_property(tentacle_list[5], "rotation", 5*PI/8, retRot).set_delay(retPos)
	
	#if tentacle_total % 2 == 1 and tentacle_total != 5:
	tentacle_tween.tween_property(tentacle_list[4], "position", Vector2(0, 8-3.6*temp), swipePos)	
	
	tentacle_tween.tween_property(tentacle_list[4], "position", Vector2(0, 8), retPos).set_delay(swipePos).set_delay(retPos)

func tentacleFastMovement(angle : float, move_duration : float, slowRetTime : bool = false) -> void:
	
	if angle > PI:
		angle -= 2 * PI
	
	#Animation looks good ~move_dur >0.35. Looks bad else. Fix this
	var move_amount = min(move_duration / 0.4, 1.0)
	#move_duration *= 4
	
	#shader_update = true
	
	var swipePos : float = max(move_duration * 0.3, 0.1)
	var retPos : float = max(move_duration * 0.6, 0.05)
	var retRot : float = 0.5
	
	if tentacle_tween:
		tentacle_tween.kill()
	tentacle_tween = create_tween().set_parallel()#.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	
	#tentacle_tween.tween_property(self, "reverseTentacleSpin", 1.0, swipePos)
	
	#var posAng : float = PI/2
	#var negAng : float
	#Doesn't solve it but it does proc true
	"""
	if angle >= PI and angle <= 3*PI/2:
		print("TRUE")
		#negAng = angle + PI /2 
		posAng = angle - 3* PI / 2
	else:
		posAng = angle + PI /2 
		#negAng = angle - 3* PI / 2
	print(posAng)
	"""
	
	"""
	PI/2, 
	move_amount *  3*PI/4,
	move_amount * -3*PI/4
	move_amount *    PI/2
	move_amount *   -PI/2
	move_amount *    PI/4
	move_amount *   -PI/4
	move_amount *    PI/8
	move_amount *   -PI/8
	"""
	
	resetCharge()
	
	tentacle_tween.tween_property(self, "rotation", angle, move_amount * 0.5*swipePos)
	#tentacle_tween.tween_property(tentacle_list[4], "rotation", 0, swipePos)
	tentacle_tween.tween_property(tentacle_list[0], "rotation", move_amount *  3*PI/4, swipePos).as_relative()
	tentacle_tween.tween_property(tentacle_list[8], "rotation", move_amount * -3*PI/4, swipePos).as_relative()
	tentacle_tween.tween_property(tentacle_list[1], "rotation", move_amount *    PI/2, swipePos).as_relative()
	tentacle_tween.tween_property(tentacle_list[7], "rotation", move_amount *   -PI/2, swipePos).as_relative()
	tentacle_tween.tween_property(tentacle_list[2], "rotation", move_amount *    PI/4, swipePos).as_relative()
	tentacle_tween.tween_property(tentacle_list[6], "rotation", move_amount *   -PI/4, swipePos).as_relative()
	tentacle_tween.tween_property(tentacle_list[3], "rotation", move_amount *    PI/8, swipePos).as_relative()
	tentacle_tween.tween_property(tentacle_list[5], "rotation", move_amount *   -PI/8, swipePos).as_relative()
	
	tentacle_tween.set_parallel(false)
	
	#tentacle_tween.tween_property(self, "reverseTentacleSpin", -1.0, swipePos).set_delay(retPos)
	
	var rotTime = snappedf(retRot * abs(angle / PI), 0.01)
	if slowRetTime:
		rotTime *= 2.5
	
	if move_amount >= 0.8:
		tentacle_tween.tween_property(tentacle_list[4], "rotation", move_amount * -PI, swipePos).as_relative().set_delay(retPos)
		tentacle_tween.parallel().tween_property(tentacle_list[0], "rotation", move_amount *   -PI/4, swipePos).as_relative().set_delay(retPos)
		tentacle_tween.parallel().tween_property(tentacle_list[8], "rotation", move_amount *    PI/4, swipePos).as_relative().set_delay(retPos)
		tentacle_tween.parallel().tween_property(tentacle_list[1], "rotation", move_amount *   -PI/2, swipePos).as_relative().set_delay(retPos)
		tentacle_tween.parallel().tween_property(tentacle_list[7], "rotation", move_amount *    PI/2, swipePos).as_relative().set_delay(retPos)
		tentacle_tween.parallel().tween_property(tentacle_list[2], "rotation", move_amount * -3*PI/4, swipePos).as_relative().set_delay(retPos)
		tentacle_tween.parallel().tween_property(tentacle_list[6], "rotation", move_amount *  3*PI/4, swipePos).as_relative().set_delay(retPos)
		tentacle_tween.parallel().tween_property(tentacle_list[3], "rotation", move_amount * -7*PI/8, swipePos).as_relative().set_delay(retPos)
		tentacle_tween.parallel().tween_property(tentacle_list[5], "rotation", move_amount *  7*PI/8, swipePos).as_relative().set_delay(retPos)
	
		#tentacle_tween.tween_property(self, "reverseTentacleSpin", 0.0, retRot)
	
		tentacle_tween.tween_property(self, "rotation", 0, rotTime)#.set_delay(swipePos * 0.5)
		tentacle_tween.parallel().tween_property(tentacle_list[4], "rotation", move_amount *      PI, retRot).as_relative()
		tentacle_tween.parallel().tween_property(tentacle_list[0], "rotation", move_amount *    PI/4, retRot).as_relative()
		tentacle_tween.parallel().tween_property(tentacle_list[8], "rotation", move_amount *   -PI/4, retRot).as_relative()
		tentacle_tween.parallel().tween_property(tentacle_list[1], "rotation", move_amount *    PI/2, retRot).as_relative()
		tentacle_tween.parallel().tween_property(tentacle_list[7], "rotation", move_amount *   -PI/2, retRot).as_relative()
		tentacle_tween.parallel().tween_property(tentacle_list[2], "rotation", move_amount *  3*PI/4, retRot).as_relative()
		tentacle_tween.parallel().tween_property(tentacle_list[6], "rotation", move_amount * -3*PI/4, retRot).as_relative()
		tentacle_tween.parallel().tween_property(tentacle_list[3], "rotation", move_amount *  7*PI/8, retRot).as_relative()
		tentacle_tween.parallel().tween_property(tentacle_list[5], "rotation", move_amount * -7*PI/8, retRot).as_relative()
	
	else:
		
		tentacle_tween.tween_property(self, "rotation", 0, rotTime)#.set_delay(swipePos * 0.5)
		tentacle_tween.parallel().tween_property(tentacle_list[0], "rotation", move_amount * -3*PI/4, retRot).as_relative()
		tentacle_tween.parallel().tween_property(tentacle_list[8], "rotation", move_amount *  3*PI/4, retRot).as_relative()
		tentacle_tween.parallel().tween_property(tentacle_list[1], "rotation", move_amount *   -PI/2, retRot).as_relative()
		tentacle_tween.parallel().tween_property(tentacle_list[7], "rotation", move_amount *    PI/2, retRot).as_relative()
		tentacle_tween.parallel().tween_property(tentacle_list[2], "rotation", move_amount *   -PI/4, retRot).as_relative()
		tentacle_tween.parallel().tween_property(tentacle_list[6], "rotation", move_amount *    PI/4, retRot).as_relative()
		tentacle_tween.parallel().tween_property(tentacle_list[3], "rotation", move_amount *   -PI/8, retRot).as_relative()
		tentacle_tween.parallel().tween_property(tentacle_list[5], "rotation", move_amount *    PI/8, retRot).as_relative()
	
	#tentacle_tween.parallel().tween_property(self, "rotation", 0, swipePos*0.5).set_delay(swipePos * 0.5)
	
	tentacle_tween.finished.connect(resetCharge)

func whipTentacles(rev : int = 1) -> void:
	for t in tentacle_list:
		t.whip(rev)

func toggleSearch(toggle : bool) -> void:
	if toggle:
		if timer_ref.is_stopped():
			timer_ref.start()
	else:	
		if not timer_ref.is_stopped():
			timer_ref.stop()
		for t in tentacle_list:
			t.toggleSearch(false)

func _on_timer_timeout() -> void:
	for t in tentacle_list:
		t.toggleSearch(true)
