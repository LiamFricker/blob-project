extends base_creature

@onready var magic_rng = RandomNumberGenerator.new() 

var move_dir : Vector2
const base_range : int = 500
@export var speed : float = 100
var jump_state : int = 0
const detect_range_high = 250
const detect_range_low = 150

var targetRef : Node2D

func _on_detection_range_area_entered(area: Area2D) -> void:
	if not targetRef:
		targetRef = area.getParent()
		_jump_start()

func _on_detection_range_body_entered(body: Node2D) -> void:
	if not targetRef:
		targetRef = body
		_jump_start()

func _detectionCheck() -> void:
	if targetRef:	
		var targetPos = targetRef.getPosition()
		
		if getPosition().distance_squared_to(targetPos) <= detect_range_low * detect_range_low:
			_jump_start()
			return
		targetRef = null

	var detectNode = $InnerNode/DetectionRange
	if (detectNode.has_overlapping_areas() or detectNode.has_overlapping_bodies()):
		var localAreas = detectNode.get_overlapping_areas()
		for a in localAreas:
			_on_detection_range_area_entered(a)
		
		var localBodies = detectNode.get_overlapping_bodies()
		for b in localBodies:
			_on_detection_range_body_entered(b)

func _setNewDetectRange(isHigh : bool) -> void:
	var tempShape = CircleShape2D.new()
	tempShape.radius = detect_range_high if isHigh else detect_range_low
	$InnerNode/DetectionRange/CollisionShape2D.set_deferred("shape", tempShape)

func _ready() -> void:
	_idleStart()

func _jump_start() -> void:
	if targetRef.isDead():
		targetRef = null
		_detectionCheck()
		return
	if jump_state >= 4:
		jump_state = 0
		_setNewDetectRange(true)
	
	var targetPos = targetRef.getPosition()
	#var targetLen = getPosition().distance_to(targetPos)
	var targetAngle = getPosition().angle_to_point(targetPos)
	
	if abs(targetAngle) < PI/2 or abs(targetAngle) > 1.5 * PI: 
		$InnerNode/Sprite/Front.scale.x = 1
		$InnerNode/Sprite/Eye.scale.x = 1
	else:
		$InnerNode/Sprite/Front.scale.x = -1
		$InnerNode/Sprite/Eye.scale.x = -1
		
	move_dir = Vector2.from_angle(targetAngle + PI)
	
	const jump_speed = 1.25
	const jump_offset = 0.25
	var jump_time = (1.25-jump_offset)/jump_speed
	
	match jump_state:
		0:
			if movement_tween:
				movement_tween.kill()
			movement_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
			movement_tween.tween_property(Inner, "position", move_dir * speed * 2.25, jump_time).as_relative().set_delay(jump_offset)
			movement_tween.finished.connect(_jump_start)
			$AnimationPlayer.play("jump1", 0.2, jump_speed)
			_spawnOrbs(1)
		1:
			if movement_tween:
				movement_tween.kill()
			movement_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
			movement_tween.tween_property(Inner, "position", move_dir * speed * 2.25, jump_time).as_relative().set_delay(jump_offset)
			movement_tween.finished.connect(_jump_start)
			$AnimationPlayer.play("jump2", -1, jump_speed)
			_spawnOrbs(1)
		2:
			if movement_tween:
				movement_tween.kill()
			movement_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
			movement_tween.tween_property(Inner, "position", move_dir * speed * 2.25, jump_time).as_relative().set_delay(jump_offset)
			movement_tween.finished.connect(_jump_start)
			$AnimationPlayer.play("jump", -1, jump_speed)
			_spawnOrbs(1)
		3:
			if movement_tween:
				movement_tween.kill()
			movement_tween = create_tween()
			movement_tween.tween_property(Inner, "position", move_dir * speed * 7.5, 5.0).as_relative()
			movement_tween.finished.connect(_breathStart)
			$AnimationPlayer.play("run", 0.2)	
			_spawnOrbs(1)
	jump_state += 1
	

func _breathStart() -> void:
	_setNewDetectRange(false)
	$AnimationPlayer.play("recovery", 0.2)	
	if movement_tween:
		movement_tween.kill()
	movement_tween = create_tween()
	movement_tween.tween_interval(4.5)
	movement_tween.finished.connect(_idleStart)
	
	if targetRef.isDead():
		targetRef = null
	_detectionCheck()

func _idleStart() -> void:
	if jump_state >= 4:
		_setNewDetectRange(true)
		jump_state = 0
		_spawnOrbs(5)
	
	var targetLen = Inner.position.length()
	var targetAngle = Inner.position.angle()
	var newAngle
	#Angle facing towards spawn
	if targetLen > base_range and magic_rng.randi_range(0, targetLen) > base_range:
		newAngle = (targetAngle + PI) - PI * (-0.5 + magic_rng.randf())
	#Any angle
	else:
		newAngle = TAU * magic_rng.randf()
	move_dir = Vector2.from_angle(newAngle)
	if abs(newAngle) < PI/2 or abs(newAngle) > 1.5 * PI: 
		$InnerNode/Sprite/Front.scale.x = -1
		$InnerNode/Sprite/Eye.scale.x = -1
	else:
		$InnerNode/Sprite/Front.scale.x = 1
		$InnerNode/Sprite/Eye.scale.x = 1
	
	if movement_tween:
		movement_tween.kill()
	movement_tween = create_tween()
	movement_tween.tween_property(Inner, "position", move_dir * speed * 3.0, 3.0).as_relative()
	movement_tween.finished.connect(_idleStart)
	$AnimationPlayer.play("run", 0.2, 0.5)	

func _on_hurtbox_area_entered(area: Area2D) -> void:
	area.getParent().collect(orb_reward, getPosition(), true, 0)
	#area.getParent().collect(1, getPosition(), true, 1)
	_deathAnim()

func _on_hurtbox_body_entered(body: Node2D) -> void:
	body.collect(orb_reward, getPosition(), true, 0)
	#body.collect(1, getPosition(), true, 1)
	_deathAnim()

func _deathAnim() -> void:
	toggleHurtbox(false)
	$InnerNode/DetectionRange.set_deferred("monitoring", false)
	
	$InnerNode/Sprite/Eye/MagicSmallEyeClose.show()
	$InnerNode/Sprite/Eye/MagicSmallEye.hide()
	
	if movement_tween:
		movement_tween.kill()
	if $AnimationPlayer.current_animation != "recovery":
		movement_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		movement_tween.tween_property(Inner, "position", move_dir*speed*0.5, 0.4).as_relative()
	
	$AnimationPlayer.play("RESET", 0.4)
	
	if oscillate_tween:
		oscillate_tween.kill()
	oscillate_tween = create_tween()
	oscillate_tween.tween_property(Sprite, "scale", Vector2(0,0), 0.4)
	oscillate_tween.parallel().tween_property(self, "modulate", Color(1.0,1.0,1.0,0.0), 0.4)
	oscillate_tween.finished.connect(_OnDeath)
