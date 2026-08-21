extends "res://Blob/base_spawned_bullet.gd"

var movement_tween
const piercing : int = 1
var health : int = piercing

func _setSize() -> void:
	var tempShape = CircleShape2D.new()
	tempShape.radius = size * 10
	$CollisionShape2D.set_deferred("shape", tempShape)
	$Sprite.scale = size * Vector2(1,1)
		
func initBullet(start_pos : Vector2, rot : float, speed : float) -> void:
	health = piercing
	
	set_deferred("process_mode", PROCESS_MODE_INHERIT)
	show()
	
	$Sprite.modulate = Color.WHITE
	
	position = start_pos
	rotation = rot
	if movement_tween:
		movement_tween.kill()
	movement_tween = create_tween()
	var dirVect = speed * 100 * Vector2.from_angle(rot)
	var duration = 25.0 / speed
	movement_tween.tween_property(self, "position", dirVect, duration).as_relative()
	movement_tween.finished.connect(_OnDeath)

func _on_area_entered(_area: Area2D) -> void:
	print("ENTER: ", health)
	if health == 0:
		_explode()
	health -= 1

func _on_body_entered(_body: Node2D) -> void:
	if health == 0:
		_explode()
	health -= 1
	
func _explode() -> void:
	if movement_tween:
		movement_tween.kill()
	movement_tween = create_tween()
	movement_tween.tween_property($Sprite, "modulate:v", 0.0, 0.4)
	movement_tween.parallel().tween_property($Sprite, "modulate:a", 0.0, 0.4)
	movement_tween.finished.connect(_OnDeath)

func _OnDeath() -> void:
	super()
	set_deferred("process_mode", PROCESS_MODE_DISABLED)
	hide()
	if movement_tween:
		movement_tween.kill()
	
