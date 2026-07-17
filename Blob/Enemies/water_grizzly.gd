extends Node2D

enum {
	IDLE,
	AGGRESSION, 
	WALKING, 
	CHARGE_RUN,
	RUN,
	#CHARGE_SWIPE,
	#SWIPE,
	#CHARGE_DASH,
	#DASH,
	STUN, 
	DEAD
}
var state = IDLE

var PlayerRef : Node2D
var TargetRef : Node2D
var playerTarget : bool = false

@onready var Inner = $InnerNode
@onready var AnimPlay = $AnimationPlayer

var ID : int = -100

@export var max_health: float = 100
@onready var health = max_health
var difficulty = 0
@export var base_damage : float = 1

@export var charge_time : float = 100

@export var swipe_length : float = 100
@export var swing_speed : float = 1.0
var direction_angle: float = 1.0

@export var turning_speed : float = 1.0
var turning_direction : float = 0
const max_turn_angle : float = 3 * PI / 4
@export var acceleration : float = 20
var velocity : Vector2 = Vector2.ZERO
@export var friction : float = 0.25
@export var max_velocity : float = 200
var run_charge_speed : float = 1.0
@export var run_charge_speed_base : float = 1.0

var swipe_array: Array = [false, false, false, false, false, false]
var swipe_rng = RandomNumberGenerator.new()

var MapULBound: Vector2
var MapDRBound: Vector2
var homepos : Vector2

var move_tween
var ear_tween
var health_mod_tween

var current_attack : int = 0
var phase : int = 1

var swipe_count = 0
const swipe_max = 5

var dash_count = 0
const dash_max = 3
@export var dash_length = 2000

const follow_range_squared_base = 4000000 
var follow_range_squared = 4000000 

#dot (poison)
var dot_remaining
var dot_pow
enum{
	NONE, VIRUS, POISON
} 
var dot_type = NONE
var dot_tween

func setParams(TopLeftBound : Vector2, BotRightBound : Vector2, origin = Vector2.ZERO, diff = 0, boss_count = 0) -> void:
	MapULBound = TopLeftBound
	MapDRBound = BotRightBound
	homepos = origin
	difficulty = diff
	ID = -(1+boss_count)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	"""
	match state:
		RUN:
			print("run")
		CHARGE_RUN:
			print("cr")
		IDLE:
			print("idle")
		AGGRESSION:
			print("agr")
		WALKING:
			print("walk")
	"""
	if state == RUN:
		var friction_delta = pow(friction, delta)
		
		velocity += turning_direction * acceleration * delta * Vector2.from_angle(direction_angle)
		#turning_direction = _getTargetDirection() - direction_angle
		Inner.position += velocity * delta
		velocity *= friction_delta
		#direction_angle += turning_speed * delta * sign(turning_direction)
		
		var end_angle = log(direction_angle+1) if direction_angle >= 0 else -log(-direction_angle+1)
		#Inner.rotation = end_angle
	#Inner.rotation = 0
	$Polygon2D.rotation = direction_angle

func _chooseNextAttack() -> void:
	
	if playerTarget:
		#0: Run, 1: Swipe, 2: Dash

		match current_attack:
			0:
				_runStart()
			1:
				_swipeStart()
			2:
				_dashStart()
	else:
		_swipeStart()
		
#Set run speed scale to 1.25x
#Set run charge to 1.5x for first attack in phase 2. Either that or make a shorter duration version
func _runStart() -> void:
	state = CHARGE_RUN
	AnimPlay.play("RunCharge", -1, run_charge_speed)
	run_charge_speed = run_charge_speed_base
	
	direction_angle = _getTargetDirection()

	
	
func _running() -> void:
	state = RUN
	
	AnimPlay.play("Run")
	if ear_tween:
		ear_tween.kill()

	ear_tween = create_tween().set_loops(28)
	ear_tween.tween_callback(_refreshRunDirection).set_delay(0.5)
	ear_tween.finished.connect(_runEnd)

func _runEnd() -> void:
	AnimPlay.play("RunBreak", 0.5)
	turning_direction = 0
	

#Skid logic here
#An option is for to instant flip turn around to player. We'd have to make everything else a flip though.
#Need to also align angles with visual. Not sure if this looks very good.
#Add the little bounces as well too
#Nevermind, removed this. Keeping it incase I want to try it somewhere else.
func _runSkid() -> void:
	pass
	"""
	direction_angle = _getTargetDirection()
	var end_angle = log(direction_angle+1) if direction_angle >= 0 else -log(-direction_angle+1)
	#Inner.rotation = end_angle
	Inner.scale.x = -1 * Inner.scale.x
	$InnerNode/Polygon2D.visible = true
	if move_tween:
		move_tween.kill()
	move_tween = create_tween()
	
	while velocity > 10:
		velocity /= 2.0
		
		var perpAngle = direction_angle + PI/2 if direction_angle < PI/2 and direction_angle > -PI/2 else direction_angle - PI/2
		
		var swipeEndLoc : Vector2 = -0.1 * velocity * Vector2.from_angle(direction_angle)
		var swipePerpLoc : Vector2 = 0.02 * velocity * Vector2.from_angle(perpAngle)
		print("swipe end", swipeEndLoc)
		move_tween.set_ease(Tween.EASE_IN)
		move_tween.tween_property(Inner, "position", swipeEndLoc+swipePerpLoc, 0.2).as_relative().set_trans(Tween.TRANS_QUAD)
		move_tween.set_ease(Tween.EASE_OUT)
		move_tween.tween_property(Inner, "position", swipeEndLoc-swipePerpLoc, 0.2).as_relative().set_trans(Tween.TRANS_QUAD)
	var perpAngle = direction_angle + PI/2 if direction_angle < PI/2 and direction_angle > -PI/2 else direction_angle - PI/2
		
	var swipeEndLoc : Vector2 = -0.1 * velocity * Vector2.from_angle(direction_angle)
	var swipePerpLoc : Vector2 = 0.02 * velocity * Vector2.from_angle(perpAngle)
	print("swipe end", swipeEndLoc)
	move_tween.set_ease(Tween.EASE_IN)
	move_tween.tween_property(Inner, "position", swipeEndLoc+swipePerpLoc, 0.2).as_relative().set_trans(Tween.TRANS_QUAD)
	move_tween.set_ease(Tween.EASE_OUT)
	move_tween.tween_property(Inner, "position", swipeEndLoc-swipePerpLoc, 0.2).as_relative().set_trans(Tween.TRANS_QUAD)	
	move_tween.finished.connect(_runRealEnd)
	"""
	
func _runRealEnd() -> void:	
	$InnerNode/Polygon2D.visible = false
	
	if phase == 1 or swipe_count == 0:
		current_attack = 1
		_walkTransition()
	else:
		current_attack = 2
		swipe_count = 0
		_chooseNextAttack()

func _walkTransition() -> void:
	#print("Walk Trans")
	state = WALKING
	#Determine the left right swipes good night
	var swipes = swipe_rng.randi_range(0, 31)

	swipe_array[4] = swipes > 15
	swipe_array[3] = (swipes % 16) > 7
	swipe_array[2] = (swipes % 8) > 3
	swipe_array[1] = (swipes % 4) > 1
	swipe_array[0] = (swipes % 2) == 1
	
	AnimPlay.play("Walk", 0.5)
	if move_tween:
		move_tween.kill()
	move_tween = create_tween()
	
	move_tween.tween_interval(0.5)
	_walkToPlayer(7)
	
	if ear_tween:
		ear_tween.kill()
	ear_tween = create_tween()
	
	ear_tween.tween_interval(1.0)
	_earMove(swipe_array[0])
	ear_tween.tween_interval(0.5)
	_earMove(swipe_array[1])
	ear_tween.tween_interval(0.5)
	_earMove(swipe_array[2])
	ear_tween.tween_interval(0.5)
	_earMove(swipe_array[3])
	ear_tween.tween_interval(0.5)
	_earMove(swipe_array[4])
	
func _swipeStart() -> void:
	
	#Maybe in Phase 3 have a mechanic where the ear wags do actually matter with larger dirctional hitbox.
	#Maybe in Phase 3 also add in feints too. You can reverse the animation to do so.
	AnimPlay.speed_scale = swing_speed
	var animName = "LeftSwingStart" if swipe_array[swipe_count] else "RightSwingStart" #swipe_array[swipe_count]
	var arm = $InnerNode/Sprite/RArm if swipe_array[swipe_count] else $InnerNode/Sprite/LArm #swipe_array[swipe_count]
	var armSign = 1.0 if swipe_count % 2 == 0 else -1.0
	match swipe_count:
		0:
			AnimPlay.play(animName, 0.25)
		swipe_max:
			swipe_count = -1
			current_attack = 0
			AnimPlay.speed_scale = 1.0
			_chooseNextAttack()
			return
		_:
			AnimPlay.play(animName)
	
	if move_tween:
		move_tween.kill()
	move_tween = create_tween()
	var temp_angle = _getTargetDirection()
	var end_angle = log((temp_angle - PI/2)+1) if (temp_angle - PI/2) >= 0 else -log(-(temp_angle - PI/2)+1)
	move_tween.tween_property(arm, "rotation", armSign * end_angle, 1.0 / swing_speed).as_relative()
	move_tween.parallel().tween_property(arm, "position", Vector2(-5 * armSign, -10), 1.0 / swing_speed).as_relative()
	direction_angle = temp_angle
	
func _swipeRelease(isLeft : bool) -> void:
	var angleOffset : float 
	if isLeft:
		angleOffset = -PI/12
		AnimPlay.play("LeftSwingEnd")
	else:
		angleOffset = PI/12
		AnimPlay.play("RightSwingEnd")
	
	swipe_count += 1
	
	var swipeEndLoc : Vector2 = Inner.position + swipe_length * Vector2.from_angle(direction_angle+angleOffset)#getPosition()
	
	if move_tween:
		move_tween.kill()
	move_tween = create_tween()
	move_tween.tween_property(Inner, "position", swipeEndLoc, 0.4 / swing_speed)
	
func _dashStart() -> void:
	if dash_count >= dash_max:
		current_attack = 0
		run_charge_speed = 1.5 * run_charge_speed_base
		follow_range_squared = follow_range_squared_base
		dash_count = 0
		_chooseNextAttack()
	else:
		$InnerNode/Polygon2D.visible = true
		$InnerNode/Polygon2D.rotation = _getTargetDirection()
		follow_range_squared = follow_range_squared_base * 2.25
			
		AnimPlay.play("DashCharge")
		
		if move_tween:
			move_tween.kill()
		move_tween = create_tween().set_loops(11)
		move_tween.tween_callback(_updateRotationAug.bind(0.1)).set_delay(0.1)
	
func _dashEnd() -> void:
	$InnerNode/Polygon2D.visible = false
	if move_tween:
		move_tween.kill()
	move_tween = create_tween()
	
	AnimPlay.play("Dashing")
	dash_count += 1
	var swipeEndLoc : Vector2 = dash_length * Vector2.from_angle(direction_angle)
	move_tween.set_ease(Tween.EASE_OUT)
	move_tween.tween_property(Inner, "position", swipeEndLoc, 1.5).as_relative().set_trans(Tween.TRANS_QUAD)
	

func _phaseChange() -> void:
	match phase:
		1:
			#IF there is phase 3, heal the grizzly back to full health 
			#actually don't, just edit the code incase we want damage bars.
			phase = 2
			swipe_count = 0
			current_attack = 2
			AnimPlay.stop()
			AnimPlay.speed_scale = 1.0
			move_tween.kill()
			ear_tween.kill()
			$InnerNode/Polygon2D.visible = false
			state = STUN
			_stunned()
			AnimPlay.queue("RunBreak")
		2:
			phase = 3

func _stunned() -> void:
	AnimPlay.play("Stun")

func _getTargetDirection() -> float:
	var targetPos : Vector2 = TargetRef.getPosition()
	var tempAng = getPosition().angle_to_point(targetPos)
	return tempAng

func _aggressionTrigger(playerFound : bool) -> void:
	if playerFound:
		state = AGGRESSION
		_chooseNextAttack()
	else:
		_findClosestTarget()

#unused now
"""
func _updateRotation(rotTime : float) -> void:
	direction_angle = _getTargetDirection()
	
	var end_angle = log(direction_angle+1) if direction_angle >= 0 else -log(-direction_angle+1)
	if ear_tween:
		ear_tween.kill()
	ear_tween = create_tween()
	ear_tween.tween_property(Inner, "rotation", end_angle, rotTime)
"""

func _updateRotationAug(rotTime : float) -> void:
	direction_angle = _getTargetDirection()
	
	if ear_tween:
		ear_tween.kill()
	ear_tween = create_tween()
	ear_tween.tween_property($InnerNode/Polygon2D, "rotation", direction_angle, rotTime)
	
func _refreshRunDirection() -> void:
	direction_angle = _getTargetDirection()
	#if abs(velocity.angle_to(Vector2.from_angle(direction_angle))) >  PI / 1.0:
	if turning_direction <= 0.50:
		turning_direction = turning_speed
	else:	
		turning_direction -= 0.25
	
	#Fuck I forgot about this code, hopefully comemnting it out won't break it
	"""
	if abs(turning_direction) < PI / 18:
		turning_direction =  0
		return
	if turning_direction > PI:
		turning_direction = 2 * PI - turning_direction
	elif turning_direction < -PI:
		turning_direction = 2 * PI + turning_direction
	"""
		
func _earMove(isLeft : bool) -> void:
	
	if isLeft:
		var tempEarRef = $InnerNode/Sprite/Neck/WaterGrizzlyEarL
		ear_tween.tween_property(tempEarRef, "position", Vector2(-25, -26), 0.1)
		ear_tween.parallel().tween_property(tempEarRef, "scale", Vector2(-1, -1), 0.035).set_delay(0.035)
		ear_tween.tween_property(tempEarRef, "position", Vector2(-25, -34), 0.1).set_delay(0.065)
		ear_tween.parallel().tween_property(tempEarRef, "scale", Vector2(1, 1), 0.035).set_delay(0.1)
	else:
		var tempEarRef = $InnerNode/Sprite/Neck/WaterGrizzlyEarR
		ear_tween.tween_property(tempEarRef, "position", Vector2(21, -25), 0.1)
		ear_tween.parallel().tween_property(tempEarRef, "scale", Vector2(-1, -1), 0.035).set_delay(0.035)
		ear_tween.tween_property(tempEarRef, "position", Vector2(22, -35), 0.1).set_delay(0.065)
		ear_tween.parallel().tween_property(tempEarRef, "scale", Vector2(1, 1), 0.035).set_delay(0.1)
	
func _walkToPlayer(count : int) -> void:
	if count <= 0:
		_chooseNextAttack()
		return
	var temp_angle = _getTargetDirection()
	var walkEndPos : Vector2 = Inner.position + 100 * Vector2.from_angle(temp_angle)
	
	if move_tween:
		move_tween.kill()
	move_tween = create_tween()
	move_tween.tween_property(Inner, "position", walkEndPos, 0.8)
	move_tween.tween_callback(_walkToPlayer.bind(count-1))
	
#Use the 
func _findClosestTarget() -> void:
	var DetectionNode = $InnerNode/BroadDetectionRadius
	DetectionNode.monitoring = true
	if not (DetectionNode.has_overlapping_areas() or DetectionNode.has_overlapping_bodies()):
		TargetRef = null
		state = IDLE
		DetectionNode.set_deferred("monitoring", false)
		if move_tween:	
			move_tween.kill()
		if ear_tween:
			ear_tween.kill()
	else:	
		var localAreas = DetectionNode.get_overlapping_areas()
		#Could probably do a mapped lambda function here but I'm lazy
		
		var minDistance = follow_range_squared
		var tempPos = getPosition()
		var currDist = 0
		var closestNodeRef
		for a in localAreas:
			var mainbody = a.getParent()
			if mainbody.ID == ID:
				continue
			currDist = tempPos.distance_squared_to(mainbody.getPosition()) 
			if currDist < minDistance:
				minDistance = currDist
				closestNodeRef = mainbody
		
		var localBodies = DetectionNode.get_overlapping_bodies()
		
		for b in localBodies:
			if b.ID == ID:
				continue
			currDist = tempPos.distance_squared_to(b.getPosition()) 
			if currDist < minDistance:
				minDistance = currDist
				closestNodeRef = b
		
		TargetRef = closestNodeRef
		state = AGGRESSION
		DetectionNode.monitoring = false
	
func _onPlayerDetection(PlayRef : Node2D) -> void:
	#Disable the detection radius
	print("Player Detected")
	$InnerNode/DetectionRadius.set_deferred("monitoring", false)
	PlayerRef = PlayRef
	TargetRef = PlayerRef
	playerTarget = true
	$PlayerDistanceCheck.start()
	_aggressionTrigger(true)

func addPosition(addpos : Vector2) -> void:#, dims : Vector2) -> void:
	
	position += addpos  
	#pass
	#for c in children_list:
	#	c.addPosition(addpos)

func increaseVirusLevel(_type : int, _intensity : float, _duration = 2.0) -> void: #ID : int, 
	#Virus immunity
	pass

func applyPoison(intensity : float, duration = 2.0) -> void: #ID : int, 
	var dotLeft = 0
	dot_type = POISON
	if dot_tween:
		dot_tween.kill()
		if dot_remaining == -1:
			dotLeft = dot_remaining * dot_pow
	dot_tween = create_tween()
	dot_tween.tween_method(_dot_tick, 0, int(dotLeft + intensity*duration), duration) #ID, 
	dot_tween.tween_callback(_dot_end.bind(false))
	dot_pow = intensity
	dot_remaining = 0

func _dot_tick(dot_speed : int, type : int = 0) -> void:
	health -= (dot_speed - dot_remaining)
	dot_remaining = dot_speed
	if health <= 0:
		if dot_tween:
			dot_tween.kill()
		_dot_end(true, type)	#ID, 

func _dot_end(death : bool, _type : int = 0) -> void: #ID : int, 
	dot_remaining = -1
	if death:
		_OnDeath()		
		
func takeDamage(amt : float, _kwargs = []) -> void:
	if health_mod_tween:
		health_mod_tween.kill()
	health_mod_tween = create_tween()
	health_mod_tween.tween_property($InnerNode/Sprite, "modulate", Color8(255, 200, 200), 0.1)
	health_mod_tween.tween_property($InnerNode/Sprite, "modulate", Color8(255, 255, 255), 0.1)
	
	if state == IDLE:
		_aggressionTrigger(false)
	health -= amt
	if health <= 0:
		_OnDeath()	
	elif health <= max_health * 0.55:
		_phaseChange()

func _OnDeath() -> void:
	state = DEAD
	visible = false
	toggleHitbox(false)
	toggleHurtbox(false)
	set_process(false)

#Override this if needs be (such as multiple hitboxes)
func toggleHitbox(_toggle : bool) -> void:
	pass
	#if hitboxReference:
	#	hitboxReference.set_deferred("monitoring", toggle)
	#	hitboxReference.set_deferred("monitorable", toggle)
	
#Override this if needs be (such as multiple hurtboxes)
func toggleHurtbox(_toggle : bool) -> void:
	pass
	#if hurtboxReference:
	#	hurtboxReference.set_deferred("monitoring", toggle)
	#	hitboxReference.set_deferred("monitorable", toggle)

#Use this to get the position for the creature
func getPosition() -> Vector2:
	return position + Inner.position


func _on_player_distance_check_timeout() -> void:
	#Might need a null check here
	var playerPos = PlayerRef.getPosition() 
	if getPosition().distance_squared_to(playerPos) > follow_range_squared:
		_findClosestTarget()
		$PlayerDistanceCheck.stop()
		$InnerNode/DetectionRadius.set_deferred("monitoring", true)

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	print(anim_name)
	match anim_name:
		"LeftSwingStart":
			_swipeRelease(true)
		"RightSwingStart":
			_swipeRelease(false)
		"RunCharge":
			_running()
		"DashCharge":
			_dashEnd()
		"Dashing":
			_dashStart()
		#"Stun":
		#	_chooseNextAttack()
		"LeftSwingEnd", "RightSwingEnd":
			_swipeStart()
		"RunBreak":
			if state == STUN:
				_chooseNextAttack()
			else:	
				_runRealEnd()
			
func _on_damage_test_timer_timeout() -> void:
	if state != IDLE:
		takeDamage(2)

func _on_detection_radius_body_entered(body: Node2D) -> void:
	_onPlayerDetection(body)
