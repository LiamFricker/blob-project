extends "res://base_child_collect.gd"

@export var size = 1.0
#const spawner_id = 7
var color_tween
var rot_speed : float = 0
var dir : Vector2 = Vector2.ZERO

func _ready() -> void:
	$Inner/Sprite.scale = size * Vector2(1,1)
	var tempCirc = CircleShape2D.new()
	tempCirc.radius = 29.14 * size
	$Inner/Hurtbox/CollisionShape2D.set_deferred("shape", tempCirc)
	if color_tween:
		color_tween.kill()
	color_tween = create_tween()
	color_tween.tween_property($Inner/Sprite/Top, "scale:x", 1.0, 2.0)
	color_tween.parallel().tween_property($Inner/Sprite/Bot, "scale:x", 1.0, 2.0)
	color_tween.finished.connect(toggleHurtbox.bind(true))
	
	if oscillate_tween:
		oscillate_tween.kill()
	oscillate_tween = create_tween()
	oscillate_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	oscillate_tween.tween_property(Inner, "position", dir, 5.0).as_relative()
	oscillate_tween.parallel().tween_property($Inner/Sprite, "rotation", rot_speed, 5.0).as_relative()

func setParams(rot : float, rotSpeed : float, direction : Vector2, parRef : Node2D, siz = 1.0) -> void:
	$Inner.rotation = rot
	rot_speed = rotSpeed
	dir = direction
	size = siz
	parentRef = parRef
