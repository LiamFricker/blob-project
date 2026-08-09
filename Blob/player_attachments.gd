extends Node2D

var id_dict : Dictionary = {}

func attachSelf(newAttach : Node2D, ID : int) -> void:
	id_dict[ID] += 1
	add_child(newAttach)

func attachDeath(ID : int) -> void:
	if id_dict[ID]:
		id_dict[ID] -= 1

func idCount(ID : int) -> int:
	return id_dict[ID]
