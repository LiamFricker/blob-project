extends base_creature

@export var anim_ref : AnimationPlayer

var size_log : float = 1.0
var follow_range_max : float = 1000000#2500

@export var DetectNode : Node2D

@export var action_speed : float = 1.0

#Weakpoint vars
@export var weakpoint : Area2D
var weakpoint_count = 0

var TargetRef : Node2D


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
	size_log = snappedf(log(size + 3.0), 0.01)

func _idleTrigger() -> void:
	pass

func _idling() -> void:
	pass

func _huntStart() -> void:
	pass
	
func _aggressionTrigger(type : int = 0) -> void:
	pass

func _fleeStart() -> void:
	pass

func _weakpointHit(dir_pos : Vector2) -> void:
	var dir_ang = getPosition().angle_to(dir_pos)
	_weakpointToggle(false)
	if weakpoint_count < 2:
		moveAnimate()
		movement_tween.tween_property(Sprite, "position:y", -5*size, 0.15*size_log).as_relative()
		movement_tween.tween_property(Sprite, "position:y", 5*size, 0.15*size_log).as_relative()
		movement_tween.finished.connect(_scanTowards.bind(dir_ang))
		#_scanTowards(dir_ang)
		weakpoint_count += 1
	else:
		_aggressionTrigger() 

func _weakpointToggle(toggle : bool) -> void:
	if weakpoint:
		if toggle:
			weakpoint.show()
		else:	
			weakpoint.hide()
		weakpoint.set_deferred("monitoring", toggle)

func _scanTowards(dir_ang : float) -> void:
	action_state = SEARCHING
	
	moveAnimate()
	var ang_diff = angle_difference(getRotation(), dir_ang)	
	var sign_ang = sign(ang_diff)
	var duration = size_log * max(ang_diff/PI, 0.1)
	var mini_dura = 0.25 * size_log
	
	movement_tween.tween_property(Inner, "rotation", ang_diff, duration).as_relative()
	movement_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	movement_tween.tween_property(Inner, "rotation", sign_ang*-PI/3, mini_dura).as_relative()
	movement_tween.tween_property(Inner, "rotation", sign_ang* 2*PI/3, 2*mini_dura).as_relative()
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
