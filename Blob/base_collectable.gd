extends Node2D

@onready var Inner : Node2D = $Inner

var oscillate_tween
@export var value = 0.0
@export var currency_type : int = 0

signal spawnOrbs(amt : int, pos : Vector2)

#func _enableHurtbox() -> void:
#	$Inner/Hurtbox.set_deferred("monitoring", true)

func getPosition() -> Vector2:
	return position + Inner.position
	#return Vector2.ZERO

func _on_lifetime_timeout() -> void:
	if currency_type == 0:
		spawnOrbs.emit(ceil(value*0.5), getPosition())
	if oscillate_tween:
		oscillate_tween.kill()
	oscillate_tween = create_tween()
	oscillate_tween.tween_property(self, "modulate", Color(0,0,0,0), 0.5)
	oscillate_tween.finished.connect(_OnDeath)
	

func _OnDeath() -> void:
	call_deferred("queue_free")

func toggleHurtbox(toggle : bool) -> void:
	$Inner/Hurtbox.set_deferred("monitoring", toggle)

func _on_hurtbox_area_entered(area: Area2D) -> void:
	area.getParent().collect(value, getPosition(), false) 
	_deathAnim()

func _on_hurtbox_body_entered(body: Node2D) -> void:
	body.collect(value, getPosition(), false)# w/e
	_deathAnim()

func _deathAnim() -> void:
	$Lifetime.stop()
	toggleHurtbox(false)
	if oscillate_tween:
		oscillate_tween.kill()
	oscillate_tween = create_tween()
	oscillate_tween.tween_property($Inner/Sprite, "scale", Vector2(0,0), 0.4)
	oscillate_tween.parallel().tween_property(self, "modulate", Color(1.0,1.0,1.0,0.0), 0.4)
	oscillate_tween.finished.connect(_OnDeath)
