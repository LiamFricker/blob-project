extends Node2D

@export var parentRef : Node2D
@export var size : float = 1.0

signal damagedEnemy(amt : float)

func _damagedEnemy(amt : float) -> void:
	damagedEnemy.emit(amt)

func _ready() -> void:
	_setSize()

func _setSize() -> void:
	pass

func getID() -> int:
	return parentRef.getID()
	
#These variables all go into the Area2D collision. 
func getParent() -> Node2D:
	return parentRef

func getPosition() -> Vector2:
	return position + parentRef.getPosition()
