extends "res://Blob/base_spawned_bullet.gd"

var detection_range = 250
var movement_tween
@onready var detectNode = $DetectionRange
@onready var Sprite = $Sprite
@onready var Explosion = $Sprite/AnimatedSprite2D

var targetRef : Node2D
var playerFollow : bool = true
var speed : float = 1.0
const angle_max_diff : float = 0.6
const max_speed_time = 0.1

var timer_tween 

func _setSize() -> void:
	var tempShape = CircleShape2D.new()
	tempShape.size = 24 * size
	$CollisionShape2D.set_deferred("shape", tempShape)
	Sprite.scale = size * Vector2(1,1)
	
	var newShape = CircleShape2D.new()
	newShape.radius = detection_range
	$DetectionRange/CollisionShape2D.set_deferred("shape", newShape)
		
func initBullet(start_pos : Vector2, rot : float, speed : float) -> void:
	set_deferred("process_mode", PROCESS_MODE_INHERIT)
	show()
	
	position = start_pos
	Sprite.rotation = rot
	speed = speed
	targetRef = null
	playerFollow = true
	$DetectionRange.set_deferred("monitoring", true)
	Explosion.position = Vector2(-7, 0)
	Explosion.modulate = Color.WHITE
	
	_startPlayerFollow()
	

func _on_detection_range_area_entered(area: Area2D) -> void:
	if (not targetRef or playerFollow) and area.getID() != 0:
		targetRef = area.getParent()
		playerFollow = false
		_startFollow()

func _on_detection_range_body_entered(body: Node2D) -> void:
	if (not targetRef or playerFollow) and body.getID() != 0:
		targetRef = body
		playerFollow = false
		_startFollow()

func _detectionCheck() -> void:
	if targetRef:	
		var targetPos = targetRef.getPosition()
		if getPosition().distance_squared_to(targetPos) <= detection_range * detection_range * 2.25:
			_startFollow()
			return
		targetRef = null
	if (detectNode.has_overlapping_areas() or detectNode.has_overlapping_bodies()):
		var localAreas = detectNode.get_overlapping_areas()
		for a in localAreas:
			_on_detection_range_area_entered(a)
		
		var localBodies = detectNode.get_overlapping_bodies()
		for b in localBodies:
			_on_detection_range_body_entered(b)
	playerFollow = true
	_startPlayerFollow()

#If too far from the player, just die
func _startPlayerFollow() -> void:
	var targetPos : Vector2 = parentRef.getPosition()
	var targ_distance : float = getPosition().distance_to(targetPos)
	
	if targ_distance > detection_range * 6:
		_explode()
		return
	elif targ_distance < detection_range / 4.0:
		if movement_tween:
			movement_tween.kill()
		movement_tween = create_tween()
		movement_tween.tween_interval(max_speed_time)
		movement_tween.finished.connect(_startPlayerFollow)
		return
	_turnRocket(targetPos)
	movement_tween.finished.connect(_startPlayerFollow)

func _startFollow() -> void:
	var targetPos : Vector2
	if not targetRef or targetRef.isDead():
		targetRef = null
		_detectionCheck()
		return
	else:
		targetPos = targetRef.getPosition()
	
	var targ_distance : float = getPosition().distance_to(targetPos)
	if targ_distance > detection_range * 6:
		targetRef = null
		_detectionCheck()
		return
	
	_turnRocket(targetPos)
	movement_tween.finished.connect(_startFollow)

func _turnRocket(targetPos : Vector2) -> void: 
	var targetAngle = getPosition().angle_to_point(targetPos)
	var angle_diff = -angle_difference(targetAngle, rotation)
	
	var speed_time = max_speed_time
	var total_diff = angle_max_diff * speed
	
	if abs(angle_diff) > total_diff:
		angle_diff = sign(angle_diff) * total_diff
	else:
		speed_time = max(max_speed_time * angle_diff / total_diff, 0.1 * speed_time)
	
	if movement_tween:
		movement_tween.kill()
	movement_tween = create_tween()
	if angle_diff != 0.0:
		movement_tween.tween_property(self, "rotation", angle_diff, speed_time).as_relative()
		movement_tween.tween_interval(max_speed_time-speed_time)
	else:
		movement_tween.tween_interval(max_speed_time)

func _process(delta : float) -> void:
	position += 10 * speed * delta * Vector2.from_angle(Sprite.rotation)

func _on_area_entered(area: Area2D) -> void:
	_explode()

func _on_body_entered(body: Node2D) -> void:
	_explode()

func _explode() -> void:
	$DetectionRange.set_deferred("monitoring", false)
	targetRef = parentRef
	playerFollow = false
	speed = 0
	Sprite.hide()
	Explosion.position = Vector2.ZERO
	Explosion.play("default")
	if movement_tween:
		movement_tween.kill()
	movement_tween = create_tween()
	movement_tween.tween_interval(0.4)
	movement_tween.tween_property(Explosion, "modulate:v", 0.0, 0.75)
	movement_tween.parallel().tween_property(Explosion, "modulate:a", 0.0, 0.35).set_delay(0.45)
	movement_tween.finished.connect(_OnDeath)

func _OnDeath() -> void:
	super()
	set_deferred("process_mode", PROCESS_MODE_DISABLED)
	hide()
