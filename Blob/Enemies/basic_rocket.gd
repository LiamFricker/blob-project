extends "res://Blob/base_enemy_bullet.gd"

var targetRef : Node2D
var speed : float = 1.0
const angle_max_diff : float = 0.04
#var angle_min_diff : float = 0.005

var timer_tween 

func _ready() -> void:
	if size > 0:
		var tempShape = CircleShape2D.new()
		tempShape.radius = size * 0.35
		$CollisionShape2D.set_deferred("shape", tempShape)
		tempShape = CircleShape2D.new()
		tempShape.radius = size * 0.55
		$CollisionShape2D.set_deferred("shape", tempShape)
		if hurtboxRef:
			tempShape = CircleShape2D.new()
			tempShape.radius = size #22
			$CollisionShape2D.set_deferred("shape", tempShape)

func initBullet(rot : float, sd : float, tF : Node2D) -> void:
	rotation = rot
	speed = sd
	targetRef = tF
	_turnRocket()
	
func _turnRocket() -> void:
	var targetPos : Vector2
	if not targetRef or targetRef.isDead():
		targetRef = null
		targetPos = position
	else:
		targetPos = targetRef.getPosition()
	var targetAngle = getPosition().angle_to_point(targetPos)
	var angle_diff = -angle_difference(targetAngle, rotation)
	
	const max_speed_time = 0.1
	var speed_time = max_speed_time
	var total_diff = angle_max_diff * speed
	
	if abs(angle_diff) > total_diff:
		angle_diff = sign(angle_diff) * total_diff
	else:
		speed_time = max(max_speed_time * angle_diff / total_diff, 0.1 * speed_time)
	"""
	elif abs(angle_diff) < angle_min_diff:
		if movement_tween:
			movement_tween.kill()
		movement_tween = create_tween()
		movement_tween.tween_interval(max_speed_time)
		movement_tween.finished.connect(_turnRocket)
		return
	"""
	
	if movement_tween:
		movement_tween.kill()
	movement_tween = create_tween()
	if angle_diff != 0.0:
		movement_tween.tween_property(self, "rotation", angle_diff, speed_time).as_relative()
		movement_tween.tween_interval(max_speed_time-speed_time)
	else:
		movement_tween.tween_interval(max_speed_time)
	movement_tween.finished.connect(_turnRocket)

func orphan(_pos : Vector2) -> void:
	get_tree().create_timer(6.0).timeout.connect(_explode)

func _process(delta : float) -> void:
	position += 10 * speed * delta * Vector2.from_angle(rotation)

func _on_area_entered(_area: Area2D) -> void:
	if speed != 0:
	#if area.getID() != ID:
		_explode()

func _on_body_entered(_body: Node2D) -> void:
	if speed != 0:
		#if body.getID() != ID:
		_explode()

func _takeDamage() -> void:
	if SpriteRef:
		if oscillate_tween:
			oscillate_tween.kill()
		oscillate_tween = create_tween()
		SpriteRef.position = Vector2.ZERO
		oscillate_tween.tween_property(SpriteRef, "position", Vector2(0, -2), 0.1).as_relative()
		oscillate_tween.tween_property(SpriteRef, "position", Vector2(-2, 1), 0.1).as_relative()
		oscillate_tween.tween_property(SpriteRef, "position", Vector2(3, 2), 0.1).as_relative()
		oscillate_tween.tween_property(SpriteRef, "position", Vector2(-1, -1), 0.1).as_relative()
	
	health -= 1
	#Just in case the health is set to 0 somehow
	if health <= 0:
		#toggle(false)
		_explode()

func _explode() -> void:
	$CollisionShape2D3.set_deferred("disabled", false)
	speed = 0
	$Sprite.hide()
	#$AnimatedSprite2D.show()
	$AnimatedSprite2D.position = Vector2.ZERO
	$AnimatedSprite2D.play("default")
	if movement_tween:
		movement_tween.kill()
	movement_tween = create_tween()
	movement_tween.tween_interval(0.4)
	movement_tween.tween_property($AnimatedSprite2D, "modulate:v", 0.0, 0.75)
	movement_tween.parallel().tween_property($AnimatedSprite2D, "modulate:a", 0.0, 0.35).set_delay(0.45)
	movement_tween.finished.connect(_OnDeath)


func _on_timer_timeout() -> void:
	timer_tween = create_tween()
	timer_tween.tween_property($Sprite/Polygon2D, "modulate:v", 0.8, 0.25).as_relative()
	timer_tween.tween_property($Sprite/Polygon2D, "modulate:v", -0.8, 0.25).as_relative()
	timer_tween.tween_property($Sprite/Polygon2D, "modulate:v", 0.8, 0.25).as_relative()
	timer_tween.tween_property($Sprite/Polygon2D, "modulate:v", -0.8, 0.25).as_relative()
	timer_tween.tween_property($Sprite/Polygon2D, "modulate:v", 0.8, 0.25).as_relative()
	timer_tween.tween_property($Sprite/Polygon2D, "modulate:v", -0.8, 0.25).as_relative()
	timer_tween.tween_property($Sprite/Polygon2D, "modulate:v", 0.8, 0.25).as_relative()
	timer_tween.tween_property($Sprite/Polygon2D, "modulate:v", -0.8, 0.25).as_relative()
	timer_tween.finished.connect(_explode)
