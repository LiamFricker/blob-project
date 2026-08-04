extends Area2D

@export var parentRef : Node2D

#These variables all go into the Area2D collision. 
func getParent() -> Node2D:
	return parentRef

func toggle(on = true) -> void:
	set_deferred("monitorable", on)
