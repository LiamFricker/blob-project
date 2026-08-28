extends Node2D

@export var lifetime = 3.0

var fade_tween

func _ready() -> void:
	$Lifetime.start(lifetime)

func setParams(pos : Vector2, rot : float, size : float, _kwargs : Array) -> void:
	position = pos
	rotation = rot
	scale = Vector2(1,1) * size


func _on_lifetime_timeout() -> void:
	fade_tween = create_tween()
	fade_tween.tween_property(self, "modulate:a", 0.0, 1.0)
	fade_tween.finished.connect(_delete)

func _delete() -> void:
	#call_deferred("queue_free")
	queue_free()
