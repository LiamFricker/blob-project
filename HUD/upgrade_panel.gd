extends AnimatedSprite2D

#The animation is played then a signal is emitted to upgrade on completion
#On completion, the panel is moved to the back and upgrade spawns a crumpled particle based on the color, position of the panel, and the animation played
# Animation played = ending offset + ending sprite 

signal crumpled(offset, texture) 

var texture :int = 1

# Needs to load the current animated sprites frames used for this panel
#Have rng be in upgrade and pass it down here.
func _reset(type : int) -> void:
	match type:
		1:
			pass
		2:
			pass
		3:
			pass

func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_animation_finished() -> void:
	crumpled.emit(global_position, texture)
