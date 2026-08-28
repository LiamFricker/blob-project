extends "res://Blob/base_player_attack.gd"

@export var hitbox_type : int = 0

func getPosition() -> Vector2: 
	return parentRef.getFocusedPosition(hitbox_type) + position
