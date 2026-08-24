extends Control#TextureRect

#Just make this a shader i cba it looks not that good.

@export var orb_type : int = 0

const interval_time = 1.5
const duration_time = 0.1

var modulate_tween

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_handleOrbGradient()

func _handleOrbGradient() -> void:
	if modulate_tween:
		modulate_tween.kill()
	modulate_tween = create_tween().set_loops()
	match orb_type:
		0:
			redTween()
			greenTween()
			blueTween()
		1:
			greenTween()
			blueTween()
			redTween()
		2:
			blueTween()
			redTween()
			greenTween()
	
func redTween() -> void:
	modulate_tween.tween_property(self, "modulate", Color(1.0, 0.2, 0.0), interval_time)
	modulate_tween.tween_property(self, "modulate", Color(0.5, 0.0, 1.0), interval_time).set_delay(duration_time)
	modulate_tween.tween_property(self, "modulate", Color(1.0, 0.6, 0.0), interval_time).set_delay(duration_time)
	modulate_tween.tween_interval(duration_time)
	
func greenTween() -> void:
	modulate_tween.tween_property(self, "modulate", Color(0.0, 1.0, 0.0), interval_time)
	modulate_tween.tween_property(self, "modulate", Color(1.0, 0.2, 1.0), interval_time).set_delay(duration_time)
	modulate_tween.tween_property(self, "modulate", Color(0.4, 0.0, 1.0), interval_time).set_delay(duration_time)
	
	modulate_tween.tween_interval(duration_time)
	
func blueTween() -> void:
	modulate_tween.tween_property(self, "modulate", Color(0.0, 1.0, 1.0), interval_time)
	modulate_tween.tween_property(self, "modulate", Color(0.52, 0.6, 0.0), interval_time).set_delay(duration_time)
	modulate_tween.tween_property(self, "modulate", Color(1.0, 1.0, 0.0), interval_time).set_delay(duration_time)
	
	modulate_tween.tween_interval(duration_time)
