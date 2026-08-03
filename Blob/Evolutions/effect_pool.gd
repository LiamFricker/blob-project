extends Sprite2D

#Replace this with a shader eventuallys

var tween
var poolType : int = 0
var size : float = 1.0
var playerRef : Node2D

func setParams(type : int, sz : float, pR : Node2D) -> void:
	poolType = type
	size = sz * 1.25
	playerRef = pR

func _ready() -> void:
	match poolType:
		0:
			modulate = Color("d9ff0083")
		2:
			modulate = Color("37ff0063")
			
	tween = create_tween()
	tween.tween_property(self, "scale", size*Vector2(1.5,1.5), 0.25).from(Vector2.ZERO)
	tween.tween_property(self, "scale", size*Vector2(1,1), 0.1)

func disable() -> void:
	playerRef.removeChild(self)
	tween = create_tween()
	tween.tween_property(self, "scale", Vector2(0,0), 0.25)
	#tween.tween_property(self, "scale", size*Vector2(0.5,0.5), 0.1)
	#tween.tween_property(self, "scale", Vector2(0,0), 0.1)
	tween.finished.connect(call_deferred.bind("queue_free"))

func addPosition(newpos) -> void:
	position += newpos
