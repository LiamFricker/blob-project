extends base_creature

var target_reference
var target_found = false

#Change these later to @export var based on difficulty.
const detection_range = 100
const base_speed = 10.0
const base_patience = 4.0
const base_wait = 2.0

@export var strength: float = 1.0 
const duration: float = 2.0 

var oldSpeed = 0

@export var virus_decay : PackedScene

#func _process(_delta):
#	print(virus_decay)

func _getDirection() -> Vector2:
	return (target_reference.getPosition() - getPosition()).normalized()  

func _knockbackEnd() -> void:
	_retrackTarget()
	super()

func _retrackTarget() -> void:
	if target_found:
		if (target_reference.getPosition()).distance_to(getPosition()) > size * detection_range * 1.25:
			print("TOO FAR")
			state = IDLE
			target_found = false
		else:
			print("UN FAR")
			state = FIGHT
			oldSpeed = 0
			if oscillate_tween:
				oscillate_tween.kill()
			oscillate_tween = create_tween()
			var startRot = Sprite.rotation
			oscillate_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			oscillate_tween.tween_property(Sprite, "position", Vector2(0,-10*size), base_patience/10)#.set_delay(1.0)
			oscillate_tween.parallel().tween_property(Sprite, "rotation", startRot + 0.55, base_patience/10)#.set_delay(1.0)
			oscillate_tween.set_ease(Tween.EASE_OUT)
			oscillate_tween.tween_property(Sprite, "position", Vector2.ZERO, base_patience/10)
			oscillate_tween.parallel().tween_property(Sprite, "rotation", startRot + 1.1, base_patience/10) 
			if movement_tween:
				movement_tween.kill()
			movement_tween = create_tween()
			movement_tween.tween_method(_follow, 0.0, 2.5*base_patience, base_patience).set_delay(base_patience/5) 
			movement_tween.tween_callback(_retrackTarget).set_delay(base_wait) 

func explode(esize : float, angle : float, pos : Vector2) -> void:
	print("explode start")
	superArmor = true
	position  = pos
	$InnerNode/Detection.monitoring = false
	$InnerNode/Hitbox.monitoring = false
	state = FEAST
	movement_tween = create_tween()
	movement_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	movement_tween.tween_property(Inner, "position", 20 * esize * Vector2(cos(angle), sin(angle)), esize * 0.5)
	movement_tween.parallel().tween_property(Sprite, "rotation", esize * 0.5, esize * 0.5)
	movement_tween.tween_callback(explodeEnd)
	
func explodeEnd() -> void:
	print("explode end")
	superArmor = false
	state = IDLE
	$InnerNode/Detection.monitoring = true
	$InnerNode/Hitbox.monitoring = true
			
func _follow(speed : float) -> void:
	position += _getDirection() * (speed - oldSpeed) * base_speed
	var tempRot = floor(15 * (_getDirection().angle() - rotation))
	Sprite.rotation += sign(tempRot) * (speed - oldSpeed)
	oldSpeed = speed

func _on_detection_area_entered(area: Area2D) -> void:
	if state != FIGHT:
		var tempTarget = area.getParent()
		#print("TARGET: ", tempTarget)
		#print("SELF: ", self)
		if tempTarget.spawnerID == spawnerID:
			print("SELFFFFFFF")
			return
		if tempTarget.size < size * 4 and not tempTarget.isHazard:
			state = FIGHT
			target_reference = tempTarget
			target_found = true
			if not kb_moving:
				if movement_tween:
					movement_tween.kill()
				movement_tween = create_tween()
				movement_tween.tween_method(_follow, 0.0, 2.5 * base_patience, base_patience) 
				movement_tween.tween_callback(_retrackTarget).set_delay(base_wait)

func _on_detection_body_entered(body: Node2D) -> void:
	if state != FIGHT:
		var tempTarget = body
		print("TARGET: ", tempTarget, " ", tempTarget.size, " ", size * 4)
		print("SELF: ", self)
		if tempTarget.spawnerID == spawnerID:
			print("How?")
			return
		if tempTarget.size < size * 4 and not tempTarget.isHazard:
			state = FIGHT
			target_reference = tempTarget
			target_found = true
			if not kb_moving:
				oldSpeed = 0
				if movement_tween:
					movement_tween.kill()
				movement_tween = create_tween()
				if oscillate_tween:
					oscillate_tween.kill()
				oscillate_tween = create_tween()
				oscillate_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
				var startRot = Sprite.rotation
				oscillate_tween.tween_property(Sprite, "position", Vector2(0,-10*size), base_patience/10)#.set_delay(1.0)
				oscillate_tween.parallel().tween_property(Sprite, "rotation", startRot + 0.55, base_patience/10)#.set_delay(1.0)
				oscillate_tween.set_ease(Tween.EASE_OUT)
				oscillate_tween.tween_property(Sprite, "position", Vector2.ZERO, base_patience/10)
				oscillate_tween.parallel().tween_property(Sprite, "rotation", startRot + 1.1, base_patience/10)
				movement_tween.tween_method(_follow, 0.0, 2.5*base_patience, base_patience).set_delay(base_patience/5) 
				 
				movement_tween.tween_callback(_retrackTarget).set_delay(base_wait)


func _on_hitbox_area_entered(area: Area2D) -> void:
	if state == FIGHT:
		var tempTarget = area.getParent()
		if tempTarget.spawnerID != spawnerID and tempTarget.size < size * 4 and not tempTarget.isHazard:
			var tempDecay = virus_decay.instantiate()
			tempDecay.construct($InnerNode/Sprite/Sprite2D.texture, duration, Vector2(0.75,0.75) * size, getPosition() - tempTarget.getPosition())
			tempTarget.attach.add_child(tempDecay)
			tempTarget.increaseVirusLevel(spawnerID, strength, duration) #ID
			_OnDeath()


func _on_hitbox_body_entered(body: Node2D) -> void:
	if state == FIGHT:
		var tempTarget = body
		if tempTarget.spawnerID != spawnerID and tempTarget.size < size * 4 and not tempTarget.isHazard:
			var tempDecay = virus_decay.instantiate()
			tempDecay.construct($InnerNode/Sprite/Sprite2D.texture, duration, Vector2(0.75,0.75) * size, getPosition() - tempTarget.getPosition())
			tempTarget.attach.add_child(tempDecay)
			tempTarget.increaseVirusLevel(spawnerID, strength, duration)
			_OnDeath()
