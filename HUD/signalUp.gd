extends Node2D

signal crumpled(offset, texture) 

func _crumpledCatch(offset, texture) -> void:
	crumpled.emit(offset, texture)
