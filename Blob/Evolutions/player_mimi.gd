extends "res://Blob/base_evo_dmg.gd"

var targetRef : Node2D
var targetFound : bool = false
@export var detection_range : float = 250 

var movement_tween
var mimi_tween
@onready var mimi_rng = RandomNumberGenerator.new()
@export var shoot_cooldown : float = 1.0
var min_delay = 0.75

@onready var Sprite = $Node2D/Sprite2D

var bullet_list = []
var bullets_inactive = [true, true, true]
var shoot_queued : bool = false
@export var bullet_size : float = 0.0
@export var attack_speed : float = 1.0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var newShape = CircleShape2D.new()
	newShape.radius = detection_range
	$InnerNode/DetectionRange/CollisionShape2D.set_deferred("shape", newShape)

func _on_detection_range_area_entered(area: Area2D) -> void:
	if not targetRef and area.getID() != 0:
		targetRef = area.getParent()
		_startShoot()

func _on_detection_range_body_entered(body: Node2D) -> void:
	if not targetRef and body.getID() != 0:
		targetRef = body
		_startShoot()

func _detectionCheck() -> void:
	if targetRef:	
		var targetPos = targetRef.getPosition()
		if getPosition().distance_squared_to(targetPos) <= detection_range * detection_range * 2.25:
			_startShoot()
			return
		targetRef = null
	min_delay = 0.75
	var detectNode = $InnerNode/DetectionRange
	if (detectNode.has_overlapping_areas() or detectNode.has_overlapping_bodies()):
		var localAreas = detectNode.get_overlapping_areas()
		for a in localAreas:
			_on_detection_range_area_entered(a)
		
		var localBodies = detectNode.get_overlapping_bodies()
		for b in localBodies:
			_on_detection_range_body_entered(b)

func _startShoot() -> void:
	if targetRef.isDead():
		targetRef = null
		_detectionCheck()
		return
	
	var targetPos = targetRef.getPosition()
	var targetAngle = getPosition().angle_to_point(targetPos)
	
	if getPosition().distance_squared_to(targetPos) > detection_range * detection_range * 2.25:
		targetRef = null
		min_delay = 0.75
		if mimi_tween:
			mimi_tween.kill()
		return
	
	var angle_diff = -angle_difference(targetAngle, rotation + PI/2)
	var delay = max(1.5 * abs(angle_diff) / PI, min_delay) 

	Sprite.position.y = 0
	if movement_tween:
		movement_tween.kill()
	movement_tween = create_tween()
	movement_tween.tween_property(Sprite, "position:y", -3, 0.1).as_relative().set_delay(delay)
	movement_tween.tween_property(Sprite, "position:y", 6, 0.2).as_relative()
	movement_tween.tween_property(Sprite, "position:y", -6, 0.2).as_relative()
	movement_tween.tween_property(Sprite, "position:y", 3, 0.1).as_relative()
	movement_tween.tween_property(Sprite, "position:y", -3, 0.1).as_relative()
	movement_tween.tween_property(Sprite, "position:y", 6, 0.2).as_relative()
	movement_tween.tween_property(Sprite, "position:y", -6, 0.2).as_relative()
	movement_tween.tween_property(Sprite, "position:y", 3, 0.1).as_relative()
	
	
	
	if mimi_tween:
		mimi_tween.kill()
	mimi_tween = create_tween()
	mimi_tween.tween_property(self, "rotation", angle_diff, delay).as_relative()
	mimi_tween.parallel().tween_callback(_shootProj).set_delay(delay)
	for i in range(5):
		mimi_tween.tween_callback(_shootProj).set_delay(0.2)
	$AnimationPlayer.play("reload", -1, shoot_cooldown)

func _freeBullet(bullet_id : int) -> void:
	bullets_inactive[bullet_id] = true
	if shoot_queued:
		shoot_queued = false
		_shootProj()

func _shootProj() -> void:
	#var rand_angle = mimi_rng.randf_range(-0.1, 0.1)
	var offset = 20 * Vector2.from_angle(rotation+PI/2)
	
	var bullet_used : Area2D = null
	for i in range(3):
		if bullets_inactive[i]:
			bullet_used = bullet_list[i]
			break
	if not bullet_used:
		shoot_queued = true
		return
	
	bullet_used.updateParams(damage, knockback, bullet_size)
	bullet_used.initBullet(getPosition() + offset, Sprite.rotation, 10.0)
	"""
	if spawnerRef:
		var bullet = spawnerRef.spawnEntity(bullet_id, -1, getPosition()+offset)
		bullet.setParams(damage, self, size, bullet_id)
		bullet.initBullet(Inner.rotation + rand_angle + PI/2, 5.0)
		_addConnectBullet(bullet)
	else:
		var bullet = test_bullet.instantiate()
		bullet.position = getPosition()+offset 
		bullet.setParams(base_damage, self, size, bullet_id)
		bullet.initBullet(Inner.rotation + rand_angle + PI/2, 5.0)
		_addConnectBullet(bullet)
	"""
	
func _stopAnims() -> void:
	if movement_tween:
		movement_tween.kill()
	if mimi_tween:
		mimi_tween.kill()
	if $AnimationPlayer.is_playing():
		$AnimationPlayer.play("RESET", 0.5)

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "reload":
		min_delay = 0.5
		_startShoot()
	
func _OnDeath(pos = Vector2.ZERO, kb = 1.0, _kwargs = []) -> void:
	$InnerNode/DetectionRange.set_deferred("monitoring", false)
