extends Node2D

#DELETE THIS IF UNECESSARY

signal crumpled(offset : Vector2, col : Color) 

func _crumpledCatch(off : Vector2, color : Color) -> void:
	crumpled.emit(off, color)
