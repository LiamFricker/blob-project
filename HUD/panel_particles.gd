extends Sprite2D

var startVelocity : Vector2 = Vector2(0,-1)
var currVelocity : Vector2 = Vector2(0,0)
var secondVelocity : Vector2 = Vector2(0,-1)

const gravity = 9.8

func initialize(pos : Vector2, sV : Vector2, secV: Vector2, text : Texture) -> void:
	position = pos
	startVelocity = sV
	secondVelocity = secV
	texture = text

func _process(delta: float) -> void:
	currVelocity.y -= gravity * delta
	position += currVelocity * delta
	modulate.a -= delta


func _on_timer_timeout() -> void:
	currVelocity = secondVelocity


func _on_life_time_timeout() -> void:
	call_deferred("queue_free")
