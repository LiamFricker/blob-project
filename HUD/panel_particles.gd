extends Sprite2D

#var startVelocity : Vector2 = Vector2(0,-1)
var currVelocity : Vector2 = Vector2(0,0)
var secondVelocity : Vector2 = Vector2(0,-1)

const gravity = 1500
const velocityMult = 250

func initialize(pos : Vector2, sV : Vector2, _secV: Vector2, text : Texture, off : Vector2) -> void:
	position = pos
	currVelocity = sV * Vector2(velocityMult, 2 * velocityMult)
	#secondVelocity = secV * Vector2(velocityMult, 2 * velocityMult)
	texture = text
	offset = off
	
func _process(delta: float) -> void:
	position += currVelocity * delta
	currVelocity.y += gravity * delta
	rotation += 0.15 * currVelocity.x * delta
	modulate.a -= delta


func _on_timer_timeout() -> void:
	currVelocity = secondVelocity


func _on_life_time_timeout() -> void:
	call_deferred("queue_free")
