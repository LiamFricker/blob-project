extends base_creature

@export var anim_ref : AnimationPlayer
#@export var spriteRotate : bool = true

var size_log : float = 1.0
var follow_range_max_squard : float = 1000000#2500
var follow_range_max : float = 1000#2500

const base_range : int = 1000
var move_dir : Vector2 = Vector2.ZERO

@export var DetectNode : Node2D

@export var FeedingBox : Node2D 

@export var action_speed : float = 1.0

@export var idling_delay : float = 5.0

#Weakpoint vars
@export var weakpoint : Area2D
var weakpoint_count = 0

var TargetRef : Node2D

@onready var decision_rng = RandomNumberGenerator.new()

var action_state = IDLING
enum {
	IDLING,
	FLEE,
	HUNT,
	FEAST,
	SEARCHING,
	FIGHT, 
	STUN,
	INACTIVE
}

var targetRef : Node2D

func reset() -> void:
	super()
	weakpoint_count = 0

func moveAnimate() -> void:
	if movement_tween:
		movement_tween.kill()
	movement_tween = create_tween()

func getRotation(abs : bool = false) -> float:
	if abs:
		return Inner.rotation + Sprite.rotation
	else:
		return Inner.rotation

func setSize(new_size : float) -> void:
	size = new_size
	size_log = snappedf(log(size * exp(1)), 0.01)

func _idleTrigger() -> void:
	action_state = IDLING
	_toggleAttack(false)
	_idling()
	

func _idling() -> void:
	var targetLen = Inner.position.length()
	var targetAngle = Inner.position.angle()
	var newAngle
	#Angle facing towards spawn
	if targetLen > base_range and decision_rng.randi_range(0, targetLen) > base_range:
		newAngle = (targetAngle + PI) - PI * (-0.5 + decision_rng.randf())
	#Any angle
	else:
		newAngle = TAU * decision_rng.randf()
	#move_dir = Vector2.from_angle(newAngle)
	"""
	if spriteRotate:
		pass

	else:
		if abs(newAngle) < PI/2 or abs(newAngle) > 1.5 * PI: 
			Sprite.scale.x = -1.0 * size
		else:
			Sprite.scale.x = 1.0 * size
	"""
	
	_moveTowards(0, newAngle)
	
	movement_tween.finished.connect(_idling)

func _walk(dir_ang : float, base_len : float = 2.0) -> void:
	var walk_time = (base_len) * size_log
	move_dir = Vector2.from_angle(dir_ang)
	var distance = base_len * move_dir * 50.0
	var angle_diff = -angle_difference(dir_ang, Inner.rotation + PI/2)
	
	moveAnimate()	
	movement_tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
	movement_tween.tween_property(Inner, "position", distance, walk_time).as_relative()
	movement_tween.parallel().tween_property(Inner, "rotation", angle_diff, walk_time*0.25)#.as_relative()
	$AnimationPlayer.play("Walk", 0.2, size_log)

func _run(dir_ang : float, base_len : float = 1.0) -> void:
	var run_time = (base_len) * size_log
	move_dir = Vector2.from_angle(dir_ang)
	var distance = base_len * move_dir * 100.0
	var angle_diff = -angle_difference(dir_ang, Inner.rotation + PI/2)
	
	moveAnimate()	
	movement_tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
	movement_tween.tween_property(Inner, "position", distance, run_time).as_relative()
	movement_tween.parallel().tween_property(Inner, "rotation", angle_diff, run_time*0.5)
	$AnimationPlayer.play("Run", 0.2, size_log)

func _chase(dir_ang : float, total_len : float = 250.0, dura : float = 0.1) -> void:
	if total_len < 250.0 * dura:
		dura = max(total_len / 250.0, 0.05)
	
	
	var angle_diff = -min(angle_difference(dir_ang, Inner.rotation + PI/2), PI * dura)
	move_dir = Vector2.from_angle(Inner.rotation + PI/2 + angle_diff)
	var distance = move_dir * 250.0 * dura
	var run_time = (dura) * size_log
	
	moveAnimate()	
	movement_tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
	movement_tween.tween_property(Inner, "position", distance, run_time).as_relative()
	movement_tween.parallel().tween_property(Inner, "rotation", angle_diff, run_time)
	$AnimationPlayer.play("Run", 0.2, size_log)

func _dash(dir_ang : float, base_len : float = 0.5) -> void:
	var dash_time = (base_len) * size_log
	move_dir = Vector2.from_angle(dir_ang)
	var distance = base_len * move_dir * 200.0
	var angle_diff = -angle_difference(dir_ang, Inner.rotation + PI/2)
	
	moveAnimate()	
	movement_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	movement_tween.tween_property(Inner, "position", distance, dash_time).as_relative()
	movement_tween.parallel().tween_property(Inner, "rotation", angle_diff, dash_time*0.75).as_relative()
	$AnimationPlayer.play("Dash", 0.2, size_log)

func _huntStart() -> void:
	var targetPos = TargetRef.getPosition()
	var currentPos = getPosition()
	var dir_ang = currentPos.angle_to(targetPos)
	var dir_dist = currentPos.distance_to(targetPos)
	
	if dir_dist > follow_range_max:
		_idleTrigger()
	else:
	
		state = HUNT
		$AnimationPlayer.play("Charge", 0.2, size_log)
		moveAnimate()
		var angle_diff = -angle_difference(dir_ang, Inner.rotation + PI/2)
		movement_tween.parallel().tween_property(Inner, "rotation", angle_diff, 1.0 * size_log)
		movement_tween.tween_interval(0.5 * size)
		movement_tween.finished.connect(_hunt.bind(dir_ang, dir_dist))

func _hunt(dir_ang : float, dir_dist : float) -> void:
	_toggleAttack(true)
	var distance_travel = (dir_dist + 50.0) / 200.0
	_moveTowards(2, dir_ang, distance_travel)
	#movement_tween.finished.connect(_scanTowards.bind(Inner.rotation))
	movement_tween.finished.connect(_huntEnd)

func _huntEnd() -> void:
	_toggleAttack(false)
	if targetRef.isDead():
		var targetPos = TargetRef.getPosition()
		var currentPos = getPosition()
		var dir_ang = currentPos.angle_to(targetPos)
		var dir_dist = currentPos.distance_to(targetPos)
		var distance_travel = (dir_dist) / 50.0
		
		_moveTowards(0, dir_ang, distance_travel)
		movement_tween.finished.connect(_feast)
	else:
		_huntStart()

func _toggleAttack(_toggle : bool) -> void:
	pass
	
func _feast() -> void:
	FeedingBox.set_deferred("monitorable", true)
	
	action_state = FEAST
	moveAnimate()	
	$AnimationPlayer.play("Feast", 0.2, size_log)
	var basePos = Vector2.ZERO
	for i in range(9):
		var j : int = int(((i+5) % 9) / 3)
		var newPos = basePos + size * Vector2(-25.0 + (25.0 * ((i+2) % 3)), -25.0 + 25.0 * j)
		movement_tween.tween_callback(_feedBoxTranslate.bind(newPos)).set_delay(0.25*size_log)
	movement_tween.finished.connect(_idleTrigger)

func _feedBoxTranslate(new_pos : Vector2) -> void:
	FeedingBox.set_deferred("position", new_pos)
	
func _aggressionTrigger(type : int = 0) -> void:
	action_state = FIGHT
	var targetPos = TargetRef.getPosition()
	var currentPos = getPosition()
	var dir_ang = currentPos.angle_to(targetPos)
	var dir_dist = currentPos.distance_to(targetPos)
	
	if dir_dist > follow_range_max:
		_idleTrigger()
	else:
		_chase(dir_ang, dir_dist, 0.1)
		movement_tween.finished.connect(_aggressionTrigger)

func _fleeStart(damage_direction : float) -> void:
	action_state = FLEE
	moveAnimate()
	_moveTowards(1, damage_direction + PI, 3.0)
	movement_tween.finished.connect(_fleeUpdate.bind(damage_direction))

func _fleeUpdate(dmg_dir : float) -> void:
	anim_ref.play("Recovery", 0.2)
	_scanTowards(dmg_dir, 2)

func _detected() -> void:
	match action_state:
		IDLE:
			_huntStart()
		SEARCHING:
			_toggleAttack(true)
			_aggressionTrigger()
		FLEE:
			var targetPos = TargetRef.getPosition()
			var dir_ang = getPosition().angle_to(targetPos)
			TargetRef = null
			_fleeStart(dir_ang)
		HUNT:
			_huntStart()
		_:
			pass

func _moveTowards(move_speed : int = 0, dir_ang : float = -10.0, base_len : float = -1.0) -> void:
	if dir_ang <= -10.0:
		dir_ang = getRotation() if dir_ang == -10 else getRotation(true)
		_moveMachine(move_speed, dir_ang, base_len)

func _moveMachine(move_speed : int, dir_ang : float, base_len : float) -> void:
	if base_len == -1.0:
		match move_speed:
			0:
				_walk(dir_ang)
			1:
				_run(dir_ang)
			2:
				_dash(dir_ang)
	else:
		match move_speed:
			0:
				_walk(dir_ang, base_len)
			1:
				_run(dir_ang, base_len)
			2:
				_dash(dir_ang, base_len)

func _weakpointHit(dir_pos : Vector2) -> void:
	var dir_ang = getPosition().angle_to(dir_pos)
	_weakpointToggle(false)
	TargetRef = null
	if weakpoint_count < 2:
		action_state = SEARCHING
		moveAnimate()
		movement_tween.tween_property(Sprite, "position:y", -5*size, 0.15*size_log).as_relative()
		movement_tween.tween_property(Sprite, "position:y", 5*size, 0.15*size_log).as_relative()
		movement_tween.finished.connect(_scanTowards.bind(dir_ang))
		#_scanTowards(dir_ang)
		weakpoint_count += 1
	else:
		action_state = SEARCHING
		_scanTowards(dir_ang, 2, 2.0)

func _weakpointToggle(toggle : bool) -> void:
	if weakpoint:
		if toggle:
			weakpoint.show()
		else:	
			weakpoint.hide()
		weakpoint.set_deferred("monitoring", toggle)

func _scanTowards(dir_ang : float, checks : int = 1, scan_speed : float = 1.0) -> void:
	moveAnimate()
	var ang_diff = angle_difference(getRotation()+PI/2, dir_ang)	
	var sign_ang = sign(ang_diff)
	var duration = size_log * max(ang_diff/PI, 0.1) / scan_speed
	var mini_dura = 0.25 * size_log / scan_speed
	
	movement_tween.tween_property(Inner, "rotation", ang_diff, duration).as_relative()
	movement_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	for i in range(checks):
		movement_tween.tween_property(Inner, "rotation", sign_ang*-PI/3, mini_dura).as_relative()
		movement_tween.tween_property(Inner, "rotation", sign_ang* 2*PI/3, 2*mini_dura).as_relative().set_delay(mini_dura/2.0)
		if i != checks:
			movement_tween.tween_property(Inner, "rotation", sign_ang* PI/3, mini_dura).as_relative().set_delay(mini_dura)
			movement_tween.tween_interval(mini_dura*2)
		else:
			movement_tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_LINEAR)
			movement_tween.tween_property(Inner, "rotation", sign_ang* PI/3, 2.5*mini_dura).as_relative().set_delay(mini_dura)
	movement_tween.finished.connect(_idleTrigger)

func movementCancel() -> void:
	if movement_tween:
		movement_tween.kill()
	if anim_ref:
		anim_ref.play("RESET", 0.5)
	
	pass

func _on_detection_body_entered(body: Node2D) -> void:
	if body.isDead():
		return
	
	var bID = body.getID()
	if not TargetRef:
		if bID == 0:	
			_onPlayerDetection(body)
		elif bID != ID:
			#DetectNode.set_deferred("monitoring", false)
			TargetRef = body
			$PlayerDistanceCheck.start()
			_aggressionTrigger(1)

func _on_detection_area_entered(area: Area2D) -> void:
	
	if not TargetRef and area.getID() != ID:
		TargetRef = area.getParent()
		if TargetRef.isDead():
			TargetRef = null
		else:
			#Disable the detection radius
			#DetectNode.set_deferred("monitoring", false)
			_aggressionTrigger(1)

func _detectionCheck() -> void:
	if targetRef:	
		var targetPos = targetRef.getPosition()
		
		if getPosition().distance_squared_to(targetPos) <= 1000000:
			#_jump_start()
			return
		targetRef = null

	var detectNode = $InnerNode/DetectionRange
	if (detectNode.has_overlapping_areas() or detectNode.has_overlapping_bodies()):
		var localAreas = detectNode.get_overlapping_areas()
		for a in localAreas:
			_on_detection_area_entered(a)
		
		var localBodies = detectNode.get_overlapping_bodies()
		for b in localBodies:
			_on_detection_body_entered(b)
			
func _onPlayerDetection(player_ref : Node2D) -> void:
	pass
