extends "res://Blob/base_evo_dmg.gd"

var targetRef : Node2D = null
#var targetFound : bool = false
@export var detection_range : float = 250 

var movement_tween
var mimi_tween
#@onready var mimi_rng = RandomNumberGenerator.new()
@export var shoot_cooldown : float = 1.0
@export var cooldown : float = 20.0

@onready var Sprite = $Pivot/Sprite2D
@onready var detectNode = $DetectionRange

#const bullets_max = 10
var bullets_inactive = [true, true, true, true, true, true, true, true, true, true]
var shoot_queued : int = 0
@export var bullet_size : float = 1.0
@export var attack_speed : float = 1.0

@export var base_ammo : int = 8
@onready var remaining_ammo : int = 8

#const bullet_id = 1021

func _ready() -> void:
	super()
	$CooldownTimer.start(cooldown)

# Called when the node enters the scene tree for the first time.
func _setSize() -> void:
	var newShape = CircleShape2D.new()
	newShape.radius = detection_range
	$DetectionRange/CollisionShape2D.set_deferred("shape", newShape)

func changeRot(newangle : float) -> void:
	$Pivot.rotation = newangle

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
		var mimiPos = getPosition() + 52 * Vector2.from_angle($Pivot.rotation + PI/2)
		if mimiPos.distance_squared_to(targetPos) <= detection_range * detection_range * 2.25:
			_startShoot()
			return
		targetRef = null
	
	if (detectNode.has_overlapping_areas() or detectNode.has_overlapping_bodies()):
		var localAreas = detectNode.get_overlapping_areas()
		for a in localAreas:
			_on_detection_range_area_entered(a)
		
		var localBodies = detectNode.get_overlapping_bodies()
		for b in localBodies:
			_on_detection_range_body_entered(b)

func _startShoot() -> void:
	if shoot_queued == -1:
		shoot_queued = 0
		
		remaining_ammo = ceil(base_ammo * attack_speed)

		#if mimi_tween:
		#	mimi_tween.kill()
		#mimi_tween = create_tween().set_loops(remaining_ammo)
		#mimi_tween.tween_callback(_shootLogic)
		_shootLogic()
		
	else:
		#if mimi_tween:
		#	mimi_tween.kill()
		#mimi_tween = create_tween().set_loops(remaining_ammo)
		#mimi_tween.tween_callback(_shootLogic).set_delay()
		_shootLogic()

func _shootLogic() -> void:
	if targetRef.isDead():
		targetRef = null
		#if mimi_tween:
		#	mimi_tween.kill()
		_detectionCheck()
		return
	
	var targetPos = targetRef.getPosition()
	var mimiPos = getPosition() + 52 * Vector2.from_angle($Pivot.rotation + PI/2)
	var targetAngle = mimiPos.angle_to_point(targetPos)
	
	if mimiPos.distance_squared_to(targetPos) > detection_range * detection_range * 2.25:
		targetRef = null
		#if mimi_tween:
		#	mimi_tween.kill()
		_detectionCheck()	
		return
		
	var mimiRot = $Pivot.rotation + Sprite.rotation + PI/2
	var angle_diff = -angle_difference(targetAngle, mimiRot)
	var delay = max(1.0 * abs(angle_diff) / PI, 0.5) / attack_speed 
	var short_delay = max(0.075 / attack_speed, 0.05)
	
	#Sprite.position.y = 0
	if movement_tween:
		movement_tween.kill()
	movement_tween = create_tween()
	movement_tween.tween_property(Sprite, "rotation", angle_diff, delay).as_relative()
	movement_tween.tween_property(Sprite, "position:y", -3, short_delay).as_relative()
	movement_tween.tween_callback(_shootProj)
	movement_tween.tween_property(Sprite, "position:y", 6, short_delay*2.0).as_relative()
	movement_tween.tween_property(Sprite, "position:y", -6, short_delay*2.0).as_relative()
	movement_tween.tween_property(Sprite, "position:y", 3, short_delay).as_relative()
	movement_tween.tween_interval(shoot_cooldown/attack_speed)
	movement_tween.finished.connect(_shootLogic)

func freeBullet(_bullet_id : int) -> void:
	bullets_inactive[_bullet_id] = true
	if shoot_queued > 0:
		shoot_queued -= 1
		_startShoot()

func _shootProj() -> void:
	if remaining_ammo > 0:
		const offset = 20 
		var pivotRot = $Pivot.rotation + PI/2
		var mimiPos = getPosition() + (52) * Vector2.from_angle(pivotRot) + offset * Vector2.from_angle(pivotRot + Sprite.rotation)
		
		var bullet_used : Area2D = null
		for i in range(bullets_max):
			if bullets_inactive[i]:
				bullet_used = children_list[i]
				bullets_inactive[i] = false
				break
		if not bullet_used:
			shoot_queued += 1
			return
		remaining_ammo -= 1
		bullet_used.updateParams(damage, knockback, bullet_size)
		bullet_used.initBullet(mimiPos, Sprite.rotation + PI/2, 10.0)	
	else:
		shoot_queued = 0
		_outOfAmmo()

func _outOfAmmo() -> void:
	#Sprite.position.y = 0
	if movement_tween:
		movement_tween.kill()
	movement_tween = create_tween()
	movement_tween.tween_property(Sprite, "position:y", -3, 0.1).as_relative()
	movement_tween.tween_property(Sprite, "position:y", 6, 0.2).as_relative()
	movement_tween.tween_property(Sprite, "position:y", -6, 0.2).as_relative()
	movement_tween.tween_property(Sprite, "position:y", 3, 0.1).as_relative()
	movement_tween.tween_property(Sprite, "position:y", -6, 0.2).as_relative()
	movement_tween.tween_property(Sprite, "position:y", 6, 0.2).as_relative()
	movement_tween.finished.connect(_finished)

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "Retract" and $CooldownTimer.is_stopped():
		print("START TIME")
		detectNode.set_deferred("monitoring", true)
		shoot_queued = -1
		targetRef = null
	
func _finished() -> void:
	detectNode.set_deferred("monitoring", false)
	$AnimationPlayer.play("Retract")
	$CooldownTimer.start(cooldown)


func _on_cooldown_timer_timeout() -> void:
	$AnimationPlayer.play_backwards("Retract", 0.5)
