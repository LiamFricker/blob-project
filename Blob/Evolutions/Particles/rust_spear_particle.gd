extends "res://Blob/base_player_particle.gd"

func setParams(pos : Vector2, rot : float, size : float, kwargs : Array) -> void:
	super(pos, rot, size*2, [])
	match kwargs[0]:
		0:
			$Rust1.show()
		1:
			$Rust2.show()
		2:
			$Rust3.show()
		3:
			$Rust4.show()
		4:
			print("5 ain't supposed to spawn a rust particle. Also make sure the pos offsets are fine.")
	
