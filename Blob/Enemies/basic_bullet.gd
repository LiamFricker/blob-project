extends "res://Blob/base_enemy_bullet.gd"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if size > 0:
		var tempShape = RectangleShape2D.new()
		tempShape.size = Vector2(size*3, size)
		$CollisionShape2D.set_deferred("shape", tempShape)
		
		var biggertempShape = RectangleShape2D.new()
		tempShape.size = Vector2(size*4, size*2)
		$Hurtbox/CollisionShape2D.set_deferred("shape", biggertempShape)

func initBullet(rot : float, speed : float) -> void:
	rotation = rot
	if movement_tween:
		movement_tween.kill()
	movement_tween = create_tween()
	var dirVect = speed * 100 * Vector2.from_angle(rot)
	movement_tween.tween_property(self, "position", dirVect, 5).as_relative()
	movement_tween.finished.connect(_OnDeath)
