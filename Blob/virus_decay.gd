extends Sprite2D

var decay_tween
@export var duration : float = 2.0

func _ready():
	decay_tween = create_tween()
	var tempCol = modulate
	tempCol.a = 0.0
	decay_tween.tween_property(self, "modulate", tempCol, duration)
	decay_tween.tween_callback(_death)

func construct(tex : Texture, dur : float, scl : Vector2, pos : Vector2) -> void:
	self.texture = tex
	duration = dur
	scale = scl
	position = pos
	

func _death():
	call_deferred("queue_free")
