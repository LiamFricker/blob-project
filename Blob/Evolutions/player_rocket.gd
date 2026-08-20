extends "res://Blob/base_spawned_bullet.gd"

var movement_tween

func _setSize() -> void:
	var tempShape = RectangleShape2D.new()
	tempShape.size = Vector2(size*12, 10*size)
	$CollisionShape2D.set_deferred("shape", tempShape)
	$Sprite.scale = size * Vector2(1,1)
		
func initBullet(start_pos : Vector2, rot : float, speed : float) -> void:
	set_deferred("process_mode", PROCESS_MODE_INHERIT)
	show()
	
	position = start_pos
	rotation = rot
	if movement_tween:
		movement_tween.kill()
	movement_tween = create_tween()
	var dirVect = speed * 100 * Vector2.from_angle(rot)
	var duration = 25.0 / speed
	movement_tween.tween_property(self, "position", dirVect, duration).as_relative()
	movement_tween.finished.connect(_OnDeath)

func _OnDeath() -> void:
	super()
	set_deferred("process_mode", PROCESS_MODE_DISABLED)
	hide()
	if movement_tween:
		movement_tween.kill()
	
