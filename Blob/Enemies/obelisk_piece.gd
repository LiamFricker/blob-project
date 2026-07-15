extends Node2D

signal spawnOrbs(amt : int, pos : Vector2)

@onready var Inner : Node2D = $Inner

const spawner_id = 7
const value = 3
var oscillate_tween
var color_tween
var rot_speed : float = 0
var dir : Vector2 = Vector2.ZERO

func _ready() -> void:
	if color_tween:
		color_tween.kill()
	color_tween = create_tween()
	color_tween.tween_property($Top, "modulate", Color(1.0,1.0,1.0,1.0), 0.75)
	color_tween.parallel().tween_property($Bot, "modulate", Color(1.0,1.0,1.0,1.0), 0.75)
	color_tween.finished.connect(_enableHurtbox)
	
	if oscillate_tween:
		oscillate_tween.kill()
	oscillate_tween = create_tween()
	oscillate_tween.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	oscillate_tween.tween_property(Inner, "position", dir, 5.0).as_relative()
	oscillate_tween.parallel().tween_property(Inner, "rotation", rot_speed, 5.0).as_relative()

func _enableHurtbox() -> void:
	$Inner/Hurtbox.set_deferred("monitoring", true)

func setParams(rot : float, rotSpeed : float, direction : Vector2) -> void:
	$Inner.rotation = rot
	rot_speed = rotSpeed
	dir = direction

func getPosition() -> Vector2:
	return position + Inner.position

func _on_detection_area_entered(area: Area2D) -> void:
	#Call the player's collect here too as well with the value from this orb
	area.getParent().collect(value, getPosition(), false) 
	
	call_deferred("queue_free")

func _on_detection_body_entered(body: Node2D) -> void:
	#Call the player's collect here too as well with the value from this orb
	body.collect(value, getPosition(), false)# w/e
	
	call_deferred("queue_free")

func _on_lifetime_timeout() -> void:
	if oscillate_tween:
		oscillate_tween.kill()
	oscillate_tween = create_tween()
	oscillate_tween.tween_property(self, "modulate", Color(0,0,0,0), 0.5)
	oscillate_tween.finished.connect(_OnDeath)

func _OnDeath() -> void:
	spawnOrbs.emit(value-1, getPosition())
	call_deferred("queue_free")
