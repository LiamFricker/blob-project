extends "res://Blob/base_enemy_bullet.gd"

var targetRef : Node2D
var speed : float = 1.0
var angle_max_diff : float = 0.6

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if size > 0:
		var tempShape = RectangleShape2D.new()
		tempShape.size = Vector2(size*3, size)
		$CollisionShape2D.set_deferred("shape", tempShape)
		
		var biggertempShape = RectangleShape2D.new()
		tempShape.size = Vector2(size*4, size*2)
		$Hurtbox/CollisionShape2D.set_deferred("shape", biggertempShape)

func initBullet(rot : float, sd : float, tF : Node2D) -> void:
	$Sprite.rotation = rot
	speed = sd
	
	var dirVect = sd * 100 * Vector2.from_angle(rot)
	movement_tween.tween_property(self, "position", dirVect, 5).as_relative()
	movement_tween.finished.connect(_OnDeath)

func _turnRocket() -> void:
	var targetPos = targetRef.getPosition()
	var targetAngle = getPosition().angle_to_point(targetPos)
	var angle_diff = -angle_difference(targetAngle, rotation + PI/2)
	
	const max_speed_time = 0.1
	var speed_time = max_speed_time
	var total_diff = angle_max_diff * speed
	
	if abs(angle_diff) > speed_time:
		angle_diff = sign(angle_diff) * speed_time
	else:
		speed_time = max(max_speed_time * angle_diff / total_diff, 0.1 * speed_time)
	
	if movement_tween:
		movement_tween.kill()
	movement_tween = create_tween()
	movement_tween.tween_property($Sprite, "rotation", angle_diff, speed_time).as_relative()
	if speed_time > 0.0:
		movement_tween.set_delay(max_speed_time-speed_time)
	movement_tween.finished.connect(_turnRocket)

func _process(delta : float) -> void:
	position += 10 * speed * delta * Vector2.from_angle($Sprite.rotation)

func _on_area_entered(area: Area2D) -> void:
	if area.ID != ID:
		_explode()

func _on_body_entered(body: Node2D) -> void:
	if body.ID != ID:
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
	if health == 0:
		toggle(false)
		_explode()

func _explode() -> void:
	speed = 0
	$Sprite.hide()
	$AnimatedSprite2D.show()
	$AnimatedSprite2D.play("default")
	if movement_tween:
		movement_tween.kill()
	movement_tween = create_tween()
	movement_tween.tween_interval(0.4)
	movement_tween.finished.connect(_OnDeath)
