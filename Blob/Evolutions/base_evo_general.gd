extends Node2D

@export var parentRef : Node2D

signal damagedEnemy(amt : float)

func _damagedEnemy(amt : float) -> void:
	damagedEnemy.emit(amt)

func getID() -> int:
	return parentRef.getID()
	
#These variables all go into the Area2D collision. 
func getParent() -> Node2D:
	return parentRef

func getPosition() -> Vector2:
	return position + parentRef.getPosition()
