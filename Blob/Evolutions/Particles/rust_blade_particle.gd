extends "res://Blob/base_player_particle.gd"

func setParams(pos : Vector2, rot : float, size : float, kwargs : Array) -> void:
	super(pos, rot, size, [])
	match kwargs[1]:
		0:
			if kwargs[0]:
				$RustedL1.show()
			else:
				$RustedR1.show()
		1:
			if kwargs[0]:
				$RustedL2.show()
			else:
				$RustedR2.show()
		2:
			if kwargs[0]:
				$RustedL3.show()
			else:
				$RustedR3.show()
	
