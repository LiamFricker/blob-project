extends "res://Blob/base_collectable.gd"

var parentRef : Node2D

func _OnDeath() -> void:
	if parentRef:
		parentRef.removeChild(self)
	super()

func addPosition(addpos : Vector2) -> void:#, dims : Vector2) -> void:
	position += addpos  

func reset() -> void: 
	$Lifetime.start()
	toggleHurtbox(true)
	visible = true
	set_process(true)

func disable() -> void:
	$Lifetime.stop()
	if oscillate_tween:	
		oscillate_tween.kill()
	toggleHurtbox(false)
	visible = false
	set_process(false)

func orphan(pos = Vector2.ZERO) -> void:
	_on_lifetime_timeout()
